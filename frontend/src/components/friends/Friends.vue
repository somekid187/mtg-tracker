<template>
  <div class="page-layout">
    <Sidebar />

    <div class="friends-content">
      <h1 class="page-title">Friends</h1>

      <!-- Join Match Bar -->
      <div class="join-match-bar">
        <div class="join-match-info">
          <span class="join-match-title">Got an invite code?</span>
          <span class="join-match-sub">Enter it to join a friend's match in progress.</span>
        </div>
        <button class="btn-join-match" @click="goToJoin">Join Match</button>
      </div>

      <!-- Tabs -->
      <div class="tab-bar">
        <button :class="['tab-btn', { active: activeTab === 'friends' }]" @click="activeTab = 'friends'">
          Friend Requests
          <span v-if="requests.length" class="tab-badge">{{ requests.length }}</span>
        </button>
        <button :class="['tab-btn', { active: activeTab === 'invites' }]" @click="activeTab = 'invites'">
          Game Invites
          <span v-if="gameInvites.length" class="tab-badge">{{ gameInvites.length }}</span>
        </button>
      </div>

      <!-- ── Friend Requests Tab ── -->
      <template v-if="activeTab === 'friends'">

        <!-- Add friend -->
        <div class="add-friend-bar">
          <input
            class="friend-input"
            type="text"
            v-model="searchUsername"
            placeholder="Enter username…"
            @keyup.enter="sendRequest"
          />
          <button class="btn-add" @click="sendRequest" :disabled="sending || !searchUsername.trim()">
            {{ sending ? 'Sending…' : 'Add Friend' }}
          </button>
        </div>
        <p v-if="addFeedback" class="feedback" :class="addFeedback.type">{{ addFeedback.msg }}</p>

        <!-- Incoming requests -->
        <div class="section-card">
          <h2 class="section-header">
            Pending Requests
            <span v-if="requests.length" class="badge">{{ requests.length }}</span>
          </h2>
          <p v-if="loading" class="loading">Loading…</p>
          <p v-else-if="!requests.length" class="empty-state">No pending requests.</p>
          <div v-else class="friend-list">
            <div v-for="req in requests" :key="req.pk_friendship" class="friend-row">
              <div class="avatar">
                <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20">
                  <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/>
                </svg>
              </div>
              <div class="friend-info">
                <span class="friend-name">{{ req.requesterUsername }}</span>
                <span class="friend-meta">Sent you a friend request</span>
              </div>
              <div class="row-actions">
                <button class="btn-icon accept" @click="accept(req.pk_friendship)">Accept</button>
                <button class="btn-icon reject" @click="reject(req.pk_friendship)">Decline</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Friends list -->
        <div class="section-card">
          <h2 class="section-header">Your Friends</h2>
          <p v-if="loading" class="loading">Loading…</p>
          <p v-else-if="!friends.length" class="empty-state">You have no friends yet. Add some!</p>
          <div v-else class="friend-list">
            <div v-for="f in friends" :key="f.pk_friendship" class="friend-row">
              <div class="avatar">
                <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20">
                  <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/>
                </svg>
              </div>
              <div class="friend-info">
                <span class="friend-name">{{ f.friendUsername }}</span>
                <span class="friend-meta">ID: {{ f.friendId }}</span>
              </div>
              <div class="row-actions">
                <button class="btn-icon remove" @click="remove(f.pk_friendship)">Remove</button>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- ── Game Invites Tab ── -->
      <template v-else>
        <div class="section-card">
          <h2 class="section-header">
            Pending Game Invites
            <span v-if="gameInvites.length" class="badge">{{ gameInvites.length }}</span>
          </h2>
          <p v-if="loadingInvites" class="loading">Loading…</p>
          <p v-else-if="!gameInvites.length" class="empty-state">No pending game invites.</p>
          <div v-else class="friend-list">
            <div v-for="inv in gameInvites" :key="inv.pk_invite" class="friend-row invite-row">
              <div class="avatar invite-avatar">🎮</div>
              <div class="friend-info">
                <span class="friend-name">{{ inv.matchName || 'Unnamed Match' }}</span>
                <div class="invite-chips">
                  <span class="invite-chip">{{ inv.matchFormat }}</span>
                  <span class="invite-chip">♥ {{ inv.startingLife }}</span>
                  <span class="invite-chip">from {{ inv.inviterUsername }}</span>
                </div>
              </div>
              <div class="row-actions">
                <button class="btn-icon accept" @click="acceptInvite(inv.pk_invite, inv.matchId)">Accept</button>
                <button class="btn-icon reject" @click="declineInvite(inv.pk_invite)">Decline</button>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'
import { userService } from '../../services/user.service'
import { inviteService } from '../../services/invite.service'
import { refreshNotifications } from '../../utils/notifications'

export default defineComponent({
  name: 'Friends',
  components: { Sidebar },
  setup() {
    const router = useRouter()

    const activeTab = ref<'friends' | 'invites'>('friends')

    const friends = ref<any[]>([])
    const requests = ref<any[]>([])
    const loading = ref(true)
    const searchUsername = ref('')
    const sending = ref(false)
    const addFeedback = ref<{ msg: string; type: 'success' | 'error' } | null>(null)

    const gameInvites = ref<any[]>([])
    const loadingInvites = ref(true)

    function goToJoin() {
      router.push('/match/join')
    }

    async function loadFriends() {
      loading.value = true
      try {
        const [f, r] = await Promise.all([
          userService.getFriends(),
          userService.getFriendRequests(),
        ])
        friends.value = f?.data ?? []
        requests.value = r?.data ?? []
      } catch { /* noop */ } finally {
        loading.value = false
      }
    }

    async function loadGameInvites() {
      loadingInvites.value = true
      try {
        const res = await inviteService.getPendingInvites()
        gameInvites.value = res?.data ?? []
      } catch { /* noop */ } finally {
        loadingInvites.value = false
      }
    }

    async function loadAll() {
      await Promise.all([loadFriends(), loadGameInvites()])
      await refreshNotifications()
    }

    async function sendRequest() {
      if (!searchUsername.value.trim()) return
      sending.value = true
      addFeedback.value = null
      try {
        const found = await userService.searchUser(searchUsername.value.trim())
        await userService.sendFriendRequest(found.data.userId)
        addFeedback.value = { msg: `Friend request sent to ${found.data.username}!`, type: 'success' }
        searchUsername.value = ''
      } catch (err: any) {
        addFeedback.value = {
          msg: err?.response?.data?.message || 'Failed to send request.',
          type: 'error',
        }
      } finally {
        sending.value = false
      }
    }

    async function accept(friendshipId: number) {
      try {
        await userService.acceptFriendRequest(friendshipId)
        await loadAll()
      } catch { /* noop */ }
    }

    async function reject(friendshipId: number) {
      try {
        await userService.rejectFriendRequest(friendshipId)
        await loadAll()
      } catch { /* noop */ }
    }

    async function remove(friendshipId: number) {
      try {
        await userService.removeFriend(friendshipId)
        await loadAll()
      } catch { /* noop */ }
    }

    async function acceptInvite(inviteId: number, matchId: number) {
      try {
        await inviteService.acceptInvite(inviteId)
        // Navigate to join the match via invite code flow
        router.push(`/match/join?matchId=${matchId}`)
        await loadAll()
      } catch { /* noop */ }
    }

    async function declineInvite(inviteId: number) {
      try {
        await inviteService.declineInvite(inviteId)
        await loadAll()
      } catch { /* noop */ }
    }

    onMounted(loadAll)

    return {
      activeTab,
      friends, requests, loading,
      searchUsername, sending, addFeedback,
      gameInvites, loadingInvites,
      goToJoin, sendRequest, accept, reject, remove,
      acceptInvite, declineInvite,
    }
  },
})
</script>

<style scoped src="./friends.css"></style>
