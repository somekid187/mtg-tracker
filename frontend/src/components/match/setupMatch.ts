import { defineComponent, ref, computed, onBeforeUnmount } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'
import { matchService } from '../../services/match.service'
import { playerService } from '../../services/player.service'
import { guestService } from '../../services/guest.service'
import { userService } from '../../services/user.service'
import { inviteService } from '../../services/invite.service'
import authService from '../../services/auth.service'
import { deckService } from '../../services/deck.service'

export default defineComponent({
  name: 'SetupMatch',
  components: { Sidebar },
  setup() {
    const router = useRouter()
    const route = useRoute()

    const config = ref<any>(null)
    const slots = ref<any[]>([])
    const friends = ref<any[]>([])
    const decks = ref<any[]>([])
    const loading = ref(false)
    const startError = ref('')
    const copied = ref(false)
    const pollTimer = ref<ReturnType<typeof setInterval> | null>(null)
    const draggingFrom = ref<number | null>(null)
    const dragoverIndex = ref<number | null>(null)
    const layoutMode = ref<'linear' | 'rect'>('linear')

    const slotRows = computed(() => {
      const n = slots.value.length
      const split = Math.ceil(n / 2)
      return [
        { seats: slots.value.slice(split).map((slot, j) => ({ slot, index: split + j })) },
        { seats: slots.value.slice(0, split).map((slot, j) => ({ slot, index: j })) },
      ]
    })

    // Distributes seats around four edges of a rectangle for the rect layout.
    // Returns { top, right, bottom, left } each containing { slot, index, rotation }.
    const rectLayout = computed(() => {
      const n = slots.value.length
      const indexed = slots.value.map((slot, index) => ({ slot, index }))

      // Edge capacities: bottom gets seat 0 (you), distribute rest around the table.
      // Arrangement order: bottom → right → top → left (clockwise from host).
      const total = n
      // Divide seats across edges, ensuring bottom has at least 1
      const base         = Math.floor(total / 4)
      const rem          = total % 4
      const bottomCount  = base + (rem >= 1 ? 1 : 0)
      const topCount     = base + (rem >= 2 ? 1 : 0)
      const rightCount   = base + (rem >= 3 ? 1 : 0)
      const leftCount    = base

      let i = 0
      const bottom = indexed.slice(i, i + bottomCount).map(s => ({ ...s, rotation: 0 }));   i += bottomCount
      const top    = indexed.slice(i, i + topCount   ).map(s => ({ ...s, rotation: 180 })); i += topCount
      const right  = indexed.slice(i, i + rightCount ).map(s => ({ ...s, rotation: -90 })); i += rightCount
      const left   = indexed.slice(i, i + leftCount  ).map(s => ({ ...s, rotation: 90 }))

      return { top, right, bottom, left }
    })

    // Returns the display name for a slot based on its type and current state.
    function getSlotDisplayName(slot: any): string {
      if (slot.type === 'you') return slot.name
      if (slot.joinedUsername) return slot.joinedUsername
      if (slot.type === 'guest' && slot.guestName?.trim()) return slot.guestName.trim()
      if (slot.type === 'friend' && slot.selectedFriendId) {
        return friends.value.find(f => f.friendId == slot.selectedFriendId)?.friendUsername || 'Friend'
      }
      if (slot.type === 'email' && slot.email) return slot.email.split('@')[0]
      return 'Empty'
    }

    // Records the index of the slot being dragged when a drag operation begins.
    function startDrag(index: number) {
      draggingFrom.value = index
    }

    // Tracks which slot index the dragged item is currently hovering over.
    function onDragOver(index: number) {
      dragoverIndex.value = index
    }

    // Swaps the dragged slot with the target slot when dropped.
    function onDrop(index: number) {
      if (draggingFrom.value === null || draggingFrom.value === index) {
        draggingFrom.value = null
        dragoverIndex.value = null
        return
      }
      const updated = [...slots.value]
      const temp = updated[draggingFrom.value]
      updated[draggingFrom.value] = updated[index]
      updated[index] = temp
      slots.value = updated
      draggingFrom.value = null
      dragoverIndex.value = null
    }

    // Clears drag state when a drag operation ends without a valid drop.
    function onDragEnd() {
      draggingFrom.value = null
      dragoverIndex.value = null
    }

    // Returns the list of friends not already assigned to another slot.
    function availableFriends(slotIndex: number) {
      const taken = slots.value
        .filter((s, i) => i !== slotIndex && s.selectedFriendId)
        .map(s => String(s.selectedFriendId))
      return friends.value.filter(f => !taken.includes(String(f.friendId)))
    }

    // Copies the match invite code to the clipboard and briefly shows a confirmation.
    async function copyCode() {
      try {
        await navigator.clipboard.writeText(config.value.inviteCode)
        copied.value = true
        setTimeout(() => { copied.value = false }, 2000)
      } catch {}
    }

    // Sends a site invite to the selected friend for this slot and marks it as pending.
    async function sendFriendInvite(i: number) {
      const slot = slots.value[i]
      if (!slot.selectedFriendId || !config.value?.matchId) return
      slot.sendingInvite = true
      slot.error = ''
      try {
        const res = await inviteService.sendInvite({
          fk_player_isInvited: Number(slot.selectedFriendId),
          fk_match_hosts: config.value.matchId,
        })
        slot.inviteId = res?.data?.pk_invite ?? null
        slot.inviteStatus = 'pending'
        slot.isPending = true
      } catch (err: any) {
        slot.error = err?.response?.data?.message || 'Failed to send invite.'
      } finally {
        slot.sendingInvite = false
      }
    }

    // Sends an email invite for the given slot index and marks it as pending.
    async function sendEmailInvite(i: number) {
      const slot = slots.value[i]
      if (!slot.email?.trim()) return
      slot.sending = true
      slot.error = ''
      try {
        await matchService.sendInviteEmail({
          email: slot.email.trim(),
          matchId: config.value.matchId,
          inviteCode: config.value.inviteCode,
        })
        slot.inviteSent = true
        slot.isPending = true
      } catch (err: any) {
        slot.error = err?.response?.data?.message || err?.message || 'Failed to send invite.'
      } finally {
        slot.sending = false
      }
    }

    // Starts a 5-second interval that checks for joined players and accepted friend invites.
    function startPolling() {
      if (!config.value?.matchId) return
      pollTimer.value = setInterval(async () => {
        // Poll joined players (email / invite-code flow)
        try {
          const res = await matchService.getPlayersByMatch(config.value.matchId)
          const players: any[] = res?.data ?? []
          players.forEach(p => {
            if (!p.userName) return
            const alreadyTracked = slots.value.some(s => s.joinedUsername === p.userName)
            if (alreadyTracked) return

            let idx = slots.value.findIndex(
              s => s.type !== 'you' && !s.joinedUsername && s.type === 'friend' &&
              friends.value.find(f => f.friendId == s.selectedFriendId)?.friendUsername === p.userName
            )
            if (idx === -1) {
              idx = slots.value.findIndex(s => s.isPending && !s.joinedUsername)
            }
            if (idx > -1) {
              slots.value[idx].joinedUsername = p.userName
              slots.value[idx].joinedPkPlayer = p.pk_player
            }
          })
        } catch {}

        // Poll invite acceptance for friend slots
        try {
          const invRes = await inviteService.getInvitesByMatch(config.value.matchId)
          const invites: any[] = invRes?.data ?? []
          slots.value.forEach(slot => {
            if (slot.type !== 'friend' || !slot.inviteId) return
            const inv = invites.find((inv: any) => inv.pk_invite === slot.inviteId)
            if (inv?.status === 'accepted') slot.inviteStatus = 'accepted'
          })
        } catch {}
      }, 5000)
    }

    // Clears the polling interval and resets the timer reference.
    function stopPolling() {
      if (pollTimer.value) {
        clearInterval(pollTimer.value)
        pollTimer.value = null
      }
    }

    // True when every friend slot with an assigned friend has had their invite accepted.
    const canStart = computed(() =>
      slots.value.every(s =>
        s.type !== 'friend' || !s.selectedFriendId || s.inviteStatus === 'accepted'
      )
    )

    // Creates all players (user, joined, or guest), saves match data to localStorage, and navigates to the active match.
    async function startMatch() {
      const { matchId, startingLife, playerCount, hasPoison, hasTax, hasCommanderDamage } = config.value
      const count = parseInt(playerCount)
      loading.value = true
      startError.value = ''

      try {
        const userId = authService.getUserId()
        const players: any[] = []

        for (let i = 0; i < count; i++) {
          const slot = slots.value[i]
          const cdInit = hasCommanderDamage
            ? Object.fromEntries(
                Array.from({ length: count }, (_, j) => j + 1)
                  .filter(id => id !== i + 1)
                  .map(id => [id, 0])
              )
            : null

          if (slot.type === 'you') {
            const r = await playerService.createPlayer({
              startingLife, placement: i + 1, minPlayers: count, maxPlayers: count,
              fk_appUser_participates: userId ?? undefined,
              fk_match_isPlayedIn: matchId,
              fk_deck_uses: slot.deckId || undefined,
            })
            players.push({
              id: i + 1, pk_player: r?.data?.pk_player ?? null,
              userId, guestId: null, name: slot.name,
              startingLife, currentLife: startingLife, finalLife: null, isWinner: false,
              tax: hasTax ? 0 : null, placement: null,
              poisonCounter: hasPoison ? 0 : null, commanderDamage: cdInit,
            })
          } else if (slot.joinedPkPlayer) {
            players.push({
              id: i + 1, pk_player: slot.joinedPkPlayer,
              userId: null, guestId: null, name: slot.joinedUsername,
              startingLife, currentLife: startingLife, finalLife: null, isWinner: false,
              tax: hasTax ? 0 : null, placement: null,
              poisonCounter: hasPoison ? 0 : null, commanderDamage: cdInit,
            })
          } else if (slot.type === 'friend' && slot.inviteStatus === 'accepted') {
            const friendName = friends.value.find(f => f.friendId == slot.selectedFriendId)?.friendUsername || `Player ${i + 1}`
            const r = await playerService.createPlayer({
              startingLife, placement: i + 1, minPlayers: count, maxPlayers: count,
              fk_appUser_participates: Number(slot.selectedFriendId),
              fk_match_isPlayedIn: matchId,
            })
            players.push({
              id: i + 1, pk_player: r?.data?.pk_player ?? null,
              userId: Number(slot.selectedFriendId), guestId: null, name: friendName,
              startingLife, currentLife: startingLife, finalLife: null, isWinner: false,
              tax: hasTax ? 0 : null, placement: null,
              poisonCounter: hasPoison ? 0 : null, commanderDamage: cdInit,
            })
          } else {
            const name =
              slot.type === 'guest'  ? (slot.guestName?.trim() || `Player ${i + 1}`) :
              slot.type === 'friend' ? (friends.value.find(f => f.friendId == slot.selectedFriendId)?.friendUsername || `Player ${i + 1}`) :
              slot.type === 'email'  ? (slot.email?.split('@')[0] || `Player ${i + 1}`) :
              `Player ${i + 1}`

            const gr = await guestService.createGuest({ guestName: name })
            const guestId = gr?.data?.pk_guest
            if (!guestId) throw new Error(`Failed to create guest for player ${i + 1}`)

            const pr = await playerService.createPlayer({
              startingLife, placement: i + 1, minPlayers: count, maxPlayers: count,
              fk_guest_enters: guestId,
              fk_match_isPlayedIn: matchId,
            })
            players.push({
              id: i + 1, pk_player: pr?.data?.pk_player ?? null,
              userId: null, guestId, name,
              startingLife, currentLife: startingLife, finalLife: null, isWinner: false,
              tax: hasTax ? 0 : null, placement: null,
              poisonCounter: hasPoison ? 0 : null, commanderDamage: cdInit,
            })
          }
        }

        const matchData = {
          pk_match: matchId,
          name: config.value.matchName,
          format: config.value.format,
          startingLife,
          playerCount: count,
          hasPoison, hasTax, hasCommanderDamage,
          layoutMode: layoutMode.value,
          players,
        }
        localStorage.setItem(`match_${matchId}`, JSON.stringify(matchData))
        localStorage.removeItem(`match_pending_${matchId}`)
        stopPolling()
        router.push(`/match/${matchId}`)
      } catch (err: any) {
        startError.value = err?.response?.data?.message || err?.message || 'Failed to start match.'
      } finally {
        loading.value = false
      }
    }

    // Initialization (replaces Options API `created`)
    const matchId = route.params.id as string
    const raw = localStorage.getItem(`match_pending_${matchId}`)
    if (!raw) {
      router.push('/match')
    } else {
      config.value = JSON.parse(raw)
      const count = parseInt(config.value.playerCount)
      const username = authService.getUsername()

      slots.value = Array.from({ length: count }, (_, i) => {
        if (i === 0) return { type: 'you', name: username || 'You', joinedUsername: null, deckId: null as number | null }
        return {
          type: 'guest',
          guestName: '',
          selectedFriendId: '',
          email: '',
          inviteSent: false,
          joinedUsername: null,
          joinedPkPlayer: null,
          isPending: false,
          error: '',
          sending: false,
          inviteId: null as number | null,
          inviteStatus: 'none' as 'none' | 'pending' | 'accepted',
          sendingInvite: false,
        }
      })

      userService.getFriends().then(res => {
        friends.value = res.data ?? []
      }).catch(() => {})

      deckService.getMyDecks().then(res => {
        decks.value = Array.isArray(res.data) ? res.data : []
      }).catch(() => {})

      startPolling()
    }

    onBeforeUnmount(() => {
      stopPolling()
    })

    return {
      config, slots, friends, decks, loading, startError, copied,
      draggingFrom, dragoverIndex, slotRows, rectLayout, layoutMode, canStart,
      getSlotDisplayName, startDrag, onDragOver, onDrop, onDragEnd,
      availableFriends, copyCode, sendFriendInvite, sendEmailInvite, startMatch,
    }
  },
})