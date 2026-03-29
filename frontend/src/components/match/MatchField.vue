<template>
  <div class="page-layout">
    <Sidebar v-if="sidebarOpen" />
    <div class="match-field">
      <button class="sidebar-toggle" @click="sidebarOpen = !sidebarOpen">
        {{ sidebarOpen ? '◀' : '▶' }}
      </button>

      <div v-if="matchData?.players" class="players-grid">
        <div v-for="(row, rowIdx) in playerRows" :key="rowIdx" class="players-row">
          <div
            v-for="player in row.players"
            :key="player.id"
            class="player-card"
            :class="{ flipped: row.flipped, eliminated: isEliminated(player) }"
          >
            <div class="card-info">
              <div class="card-counters">
                <div v-if="matchData.hasTax" class="counter-block">
                  <span class="counter-val">{{ player.tax }}</span>
                  <div class="counter-ctrl">
                    <button class="btn-counter" @click="adjust(player, 'tax', -1)" :disabled="matchEnded">-</button>
                    <span class="counter-name">Tax</span>
                    <button class="btn-counter" @click="adjust(player, 'tax', 1)" :disabled="matchEnded">+</button>
                  </div>
                </div>
                <div v-if="matchData.hasPoison" class="counter-block">
                  <span class="counter-val" :class="{ lethal: player.poisonCounter >= 10 }">{{ player.poisonCounter }}</span>
                  <div class="counter-ctrl">
                    <button class="btn-counter" @click="adjustPoison(player, -1)" :disabled="matchEnded">-</button>
                    <span class="counter-name">Poison</span>
                    <button class="btn-counter" @click="adjustPoison(player, 1)" :disabled="matchEnded">+</button>
                  </div>
                </div>
              </div>
              <div class="card-identity">
                <div class="avatar-circle">
                  <svg viewBox="0 0 24 24" fill="currentColor" width="44" height="44">
                    <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/>
                  </svg>
                </div>
                <span class="player-name">{{ player.name }}</span>
              </div>
            </div>

            <div class="life-section">
              <span class="life-label">Life</span>
              <div class="life-controls">
                <button class="btn-life" @click="adjust(player, 'currentLife', -1)" :disabled="matchEnded">−</button>
                <span class="life-value" :class="{ 'low-life': player.currentLife <= 5 }">{{ player.currentLife }}</span>
                <button class="btn-life" @click="adjust(player, 'currentLife', 1)" :disabled="matchEnded">+</button>
              </div>
              <span v-if="matchData.hasCommanderDamage" class="cdmg-summary">
                CDMG: {{ totalCommanderDamage(player) }} | CTR: {{ player.tax ?? 0 }}
              </span>
            </div>

            <div v-if="matchData.hasCommanderDamage && player.commanderDamage" class="card-cdmg">
              <span class="cdmg-label">Commander Damage</span>
              <div class="cdmg-badges">
                <button
                  v-for="(amount, dealerId) in player.commanderDamage"
                  :key="dealerId"
                  class="cdmg-badge"
                  @click="openCdmgModal(player, dealerId)"
                  :class="{ lethal: amount >= 21 }"
                  :disabled="matchEnded"
                >
                  {{ amount }} | {{ getPlayerName(dealerId) }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="match-footer">
        <div class="footer-tools">
          <button class="btn-tool" @click="openRandomModal('player')" title="Random Player">
            👤<span class="btn-tool-label">Player</span>
          </button>
          <button class="btn-tool" @click="openRandomModal('coin')" title="Coin Flip">
            🪙<span class="btn-tool-label">Coin</span>
          </button>
          <button class="btn-tool" @click="openRandomModal('dice')" title="Roll Dice">
            🎲<span class="btn-tool-label">Dice</span>
          </button>
        </div>
        <div class="footer-actions">
          <button v-if="!matchEnded" class="btn-end" @click="endMatch" :disabled="ending">
            {{ ending ? 'Saving...' : 'End Match' }}
          </button>
          <button class="btn-back" @click="goBack">Back</button>
        </div>
      </div>

      <!-- Commander Damage Modal -->
      <Teleport to="body">
        <div v-if="cdmgModal" class="cdmg-overlay" @click.self="closeCdmgModal">          <div class="cdmg-modal">
            <button class="cdmg-modal-close" @click="closeCdmgModal">✕</button>
            <span class="cdmg-modal-sub">Damage dealt by</span>
            <span class="cdmg-modal-dealer">{{ getPlayerName(cdmgModal.dealerId) }}</span>
            <span class="cdmg-modal-arrow">↓</span>
            <span class="cdmg-modal-receiver">{{ cdmgModal.receiver.name }}</span>
            <div class="cdmg-modal-controls">
              <button class="cdmg-modal-btn" @click="adjustCommanderDamage(cdmgModal.receiver, cdmgModal.dealerId, -1)">−</button>
              <span class="cdmg-modal-value" :class="{ 'cdmg-lethal': cdmgModal.receiver.commanderDamage[cdmgModal.dealerId] >= 21 }">
                {{ cdmgModal.receiver.commanderDamage[cdmgModal.dealerId] }}
              </span>
              <button class="cdmg-modal-btn" @click="adjustCommanderDamage(cdmgModal.receiver, cdmgModal.dealerId, 1)">+</button>
            </div>
            <span v-if="cdmgModal.receiver.commanderDamage[cdmgModal.dealerId] >= 21" class="cdmg-modal-lethal-warn">⚔ Lethal!</span>
          </div>
        </div>
      </Teleport>

      <!-- Random Tools Modal -->
      <Teleport to="body">
        <div v-if="randomModal" class="random-overlay" @click.self="closeRandomModal">
          <div class="random-modal">
            <button class="random-modal-close" @click="closeRandomModal">✕</button>

            <!-- Coin Flip -->
            <template v-if="randomModal.type === 'coin'">
              <span class="random-modal-title">🪙 Coin Flip</span>
              <div class="random-result">
                <span v-if="randomModal.result" class="random-value" :class="randomModal.result.toLowerCase()">{{ randomModal.result }}</span>
                <span v-else class="random-placeholder">?</span>
              </div>
              <button class="btn-roll" @click="rollCoin">Flip!</button>
            </template>

            <!-- Dice Roll -->
            <template v-else-if="randomModal.type === 'dice'">
              <span class="random-modal-title">🎲 Roll Dice</span>
              <div class="dice-sides-picker">
                <button
                  v-for="s in [4, 6, 8, 10, 12, 20, 100]"
                  :key="s"
                  class="btn-sides"
                  :class="{ active: randomModal.diceSides === s }"
                  @click="randomModal.diceSides = s; randomModal.result = null"
                >d{{ s }}</button>
              </div>
              <div class="custom-sides">
                <label class="custom-sides-label">Custom</label>
                <input
                  class="custom-sides-input"
                  type="number"
                  min="2"
                  max="1000"
                  v-model.number="randomModal.diceSides"
                  @input="randomModal.result = null"
                />
              </div>
              <div class="random-result">
                <span v-if="randomModal.result" class="random-value">{{ randomModal.result }}</span>
                <span v-else class="random-placeholder">?</span>
              </div>
              <button class="btn-roll" @click="rollDice">Roll d{{ randomModal.diceSides }}!</button>
            </template>

            <!-- Random Player -->
            <template v-else-if="randomModal.type === 'player'">
              <span class="random-modal-title">👤 Random Player</span>
              <div class="random-result">
                <span v-if="randomModal.result" class="random-value random-player-name">{{ randomModal.result }}</span>
                <span v-else class="random-placeholder">?</span>
              </div>
              <button class="btn-roll" @click="pickRandomPlayer">Pick!</button>
              <span class="random-note">Picks from players still in the game</span>
            </template>
          </div>
        </div>
      </Teleport>

      <!-- Final Results Modal -->
      <Teleport to="body">
        <div v-if="matchEnded && results.length" class="results-overlay">
          <div class="results-modal">
            <h2 class="results-title">Match Over</h2>
            <ul class="results-list">
              <li
                v-for="p in results"
                :key="p.id"
                class="results-item"
                :class="{ winner: p.isWinner }"
              >
                <span class="result-placement">{{ p.placement }}</span>
                <span class="result-name">{{ p.name }}</span>
                <span class="result-life">{{ p.finalLife }} life</span>
                <span v-if="p.isWinner" class="result-trophy">🏆</span>
              </li>
            </ul>
            <p v-if="endError" class="error">{{ endError }}</p>
            <button class="btn-lobby" @click="goBack">Back to Lobby</button>
          </div>
        </div>
      </Teleport>
    </div>
  </div>
</template>

<script>
import { useRouter, useRoute } from 'vue-router'
import { playerService } from '../../services/player.service'
import { matchService } from '../../services/match.service'
import Sidebar from '../shared/Sidebar.vue'
import { commanderDamageService } from '../../services/commanderDamage.service'

export default {
  components: {
    Sidebar,
  },
  setup() {
    const router = useRouter()
    const route = useRoute()
    return { router, route }
  },
  data() {
    return {
      matchData: null,
      matchEnded: false,
      ending: false,
      endError: '',
      results: [],
      sidebarOpen: true,
      autoSaveTimer: null,
      cdmgRecordIds: {},
      cdmgModal: null,
      randomModal: null,
    }
  },
  mounted() {
    this.autoSaveTimer = setInterval(this.autoSave, 2000)
  },
  beforeUnmount() {
    if (this.autoSaveTimer) clearInterval(this.autoSaveTimer)
  },
  computed: {
    playerRows() {
      if (!this.matchData?.players) return []
      const n = this.matchData.players.length
      const split = Math.ceil(n / 2)
      return [
        { players: this.matchData.players.slice(split), flipped: true },
        { players: this.matchData.players.slice(0, split), flipped: false },
      ]
    },
  },
  async created() {
    const matchId = this.$route.params.id
    const stored = localStorage.getItem(`match_${matchId}`)
    if (stored) {
      const parsed = JSON.parse(stored)
      this.matchData = {
        ...parsed,
        players: parsed.players.map((p) => ({
          ...p,
          currentLife: p.currentLife ?? p.startingLife,
        })),
      }
      return
    }

    // No localStorage — fetch from API and reconstruct matchData
    try {
      const res = await matchService.getMatchById(Number(matchId))
      const match = res.data
      const apiPlayers = match.players ?? []

      const hasPoison = apiPlayers.some((p) => p.poisonCounter != null)
      const hasTax = apiPlayers.some((p) => p.tax != null)
      const hasCommanderDamage = match.commanderThreshold != null

      const playerCount = apiPlayers.length
      const players = apiPlayers.map((p, index) => ({
        id: index + 1,
        pk_player: p.pk_player,
        userId: p.fk_appUser_participates ?? null,
        guestId: p.fk_guest_enters ?? null,
        name: p.userName || p.guestName || `Player ${index + 1}`,
        startingLife: p.startingLife,
        currentLife: p.startingLife,
        finalLife: null,
        isWinner: false,
        placement: null,
        tax: hasTax ? (p.tax ?? 0) : null,
        poisonCounter: hasPoison ? (p.poisonCounter ?? 0) : null,
        commanderDamage: hasCommanderDamage
          ? Object.fromEntries(
              Array.from({ length: playerCount }, (_, j) => j + 1)
                .filter((id) => id !== index + 1)
                .map((id) => [id, 0])
            )
          : null,
      }))

      this.matchData = {
        pk_match: match.pk_match,
        name: match.name,
        format: match.format,
        startingLife: match.startingLife,
        isTeamMatch: match.isTeamMatch,
        commanderThreshold: match.commanderThreshold,
        counterThreshold: match.counterThreshold,
        hasCommanderDamage,
        hasPoison,
        hasTax,
        players,
      }
    } catch {
      // matchData stays null — template shows nothing
    }
  },
  methods: {
    openRandomModal(type) {
      this.randomModal = { type, result: null, diceSides: 20 }
    },
    closeRandomModal() {
      this.randomModal = null
    },
    rollCoin() {
      this.randomModal.result = Math.random() < 0.5 ? 'Heads' : 'Tails'
    },
    rollDice() {
      const sides = Math.max(2, parseInt(this.randomModal.diceSides) || 6)
      this.randomModal.result = Math.floor(Math.random() * sides) + 1
    },
    pickRandomPlayer() {
      const alive = this.matchData.players.filter((p) => !this.isEliminated(p))
      const pool = alive.length > 0 ? alive : this.matchData.players
      this.randomModal.result = pool[Math.floor(Math.random() * pool.length)].name
    },
    openCdmgModal(receiver, dealerId) {      if (this.matchEnded) return
      this.cdmgModal = { receiver, dealerId: String(dealerId) }
    },
    closeCdmgModal() {
      this.cdmgModal = null
    },
    isEliminated(player) {
      if (player.currentLife <= 0) return true
      if (player.poisonCounter != null && player.poisonCounter >= 10) return true
      if (player.commanderDamage && Object.values(player.commanderDamage).some((v) => v >= 21)) return true
      return false
    },
    adjust(player, field, delta) {
      player[field] = Math.max(0, player[field] + delta)
    },
    adjustPoison(player, delta) {
      const prev = player.poisonCounter
      player.poisonCounter = Math.max(0, player.poisonCounter + delta)
      const applied = player.poisonCounter - prev
    },
    adjustCommanderDamage(player, dealerId, delta) {
      const prev = player.commanderDamage[dealerId]
      const next = Math.max(0, prev + delta)
      const applied = next - prev
      player.commanderDamage = { ...player.commanderDamage, [dealerId]: next }
      player.currentLife = Math.max(0, player.currentLife - applied)
    },
    getPlayerName(id) {
      return this.matchData.players.find((p) => p.id === parseInt(id))?.name || `Player ${id}`
    },
    totalCommanderDamage(player) {
      if (!player.commanderDamage) return 0
      return Object.values(player.commanderDamage).reduce((sum, v) => sum + v, 0)
    },
    async endMatch() {
      this.ending = true
      this.endError = ''
      try {
        // Sort: alive players by currentLife desc, eliminated players last
        const sorted = [...this.matchData.players].sort((a, b) => {
          const aElim = this.isEliminated(a) ? 1 : 0
          const bElim = this.isEliminated(b) ? 1 : 0
          if (aElim !== bElim) return aElim - bElim
          return b.currentLife - a.currentLife
        })

        // Assign placements (1 = most life = winner, last = eliminated/least life)
        const withPlacements = sorted.map((p, i) => ({
          ...p,
          finalLife: p.currentLife,
          placement: i + 1,
          isWinner: i === 0,
        }))

        // Save each player to the DB
        const updates = withPlacements.map((p) => {
          if (!p.pk_player) return Promise.resolve()
          return playerService.updatePlayer(p.pk_player, {
            finalLife: p.finalLife,
            placement: p.placement,
            isWinner: p.isWinner,
            poisonCounter: p.poisonCounter ?? undefined,
            tax: p.tax ?? undefined,
          })
        })
        await Promise.all(updates)

        // Set endTime on the match
        const endTime = new Date().toTimeString().slice(0, 8)
        await matchService.updateMatch(this.matchData.pk_match, { endTime })

        this.results = withPlacements
        this.matchEnded = true
        localStorage.removeItem(`match_${this.$route.params.id}`)
      } catch (err) {
        this.endError =
          err?.response?.data?.message || err?.message || 'Failed to save match results.'
      } finally {
        this.ending = false
      }
    },
    async autoSave() {
      if (!this.matchData?.players || this.matchEnded) return
      try {
        const playerUpdates = this.matchData.players.map((p) => {
          if (!p.pk_player) return Promise.resolve()
          return playerService.updatePlayer(p.pk_player, {
            finalLife: p.currentLife,
            poisonCounter: p.poisonCounter ?? undefined,
            tax: p.tax ?? undefined,
          }).catch(() => {})
        })

        const cdmgUpdates = []
        if (this.matchData.hasCommanderDamage) {
          for (const receiver of this.matchData.players) {
            if (!receiver.commanderDamage || !receiver.pk_player) continue
            for (const [dealerId, amount] of Object.entries(receiver.commanderDamage)) {
              const dealer = this.matchData.players.find((p) => p.id === parseInt(dealerId))
              if (!dealer?.pk_player) continue
              const key = `${dealer.pk_player}_${receiver.pk_player}`
              const existingId = this.cdmgRecordIds[key]
              const isLethal = amount >= (this.matchData.commanderThreshold ?? 21)
              if (existingId) {
                cdmgUpdates.push(
                  commanderDamageService.updateCommanderDamage(existingId, { damageAmount: amount, isLethal }).catch(() => {})
                )
              } else if (amount > 0) {
                cdmgUpdates.push(
                  commanderDamageService.createCommanderDamage({
                    damageAmount: amount,
                    isLethal,
                    fk_player_deals: dealer.pk_player,
                    fk_player_receives: receiver.pk_player,
                    fk_match_refersTo: this.matchData.pk_match,
                  }).then((res) => {
                    const id = res?.data?.pk_commanderDamage
                    if (id) this.cdmgRecordIds[key] = id
                  }).catch(() => {})
                )
              }
            }
          }
        }

        await Promise.all([...playerUpdates, ...cdmgUpdates])
      } catch {}
    },
    goBack() {
      // Just navigate away — localStorage is preserved so the match can be resumed
      this.router.push('/match')
    },
  },
  watch: {
    matchData: {
      deep: true,
      handler(val) {
        if (this.matchEnded) return
        const matchId = this.$route.params.id
        localStorage.setItem(`match_${matchId}`, JSON.stringify(val))
      },
    },
  },
}
</script>

<style scoped>
.page-layout {
  display: flex;
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background-color: #292b2d;
}

.match-field {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
}

.sidebar-toggle {
  position: absolute;
  top: 0.6em;
  left: 0.6em;
  z-index: 10;
  background: #3d3d3d;
  border: 1px solid #ffd170;
  color: #ffd170;
  border-radius: 8px;
  padding: 0.3em 0.7em;
  cursor: pointer;
  font-size: 0.85rem;
  font-family: 'Poppins', sans-serif;
  transition: background 0.2s, color 0.2s;
}

.sidebar-toggle:hover {
  background: #ffd170;
  color: #292b2d;
}

.players-grid {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 0.75em;
  gap: 0.75em;
  overflow: hidden;
}

.players-row {
  flex: 1;
  display: flex;
  gap: 0.75em;
  overflow: hidden;
}

/* Player card */
.player-card {
  flex: 1;
  display: flex;
  flex-direction: column;
  border: 2px solid #ffd170;
  border-radius: 16px;
  background: #313338;
  color: #fefefe;
  font-family: 'Poppins', sans-serif;
  overflow: hidden;
  min-width: 0;
}

.player-card.flipped {
  transform: rotate(180deg);
}

.player-card.eliminated {
  border-color: #c0392b;
  opacity: 0.7;
}

/* Card top: counters + identity */
.card-info {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 0.9em 1em;
  gap: 0.75em;
}

.card-counters {
  display: flex;
  flex-direction: column;
  gap: 0.5em;
}

.counter-block {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.counter-val {
  font-size: 1.5rem;
  font-weight: 700;
  line-height: 1.1;
}

.counter-val.lethal {
  color: #ff6b6b;
}

.counter-ctrl {
  display: flex;
  align-items: center;
  gap: 0.4em;
}

.counter-name {
  font-size: 0.85rem;
  color: #bbb;
  min-width: 2.5em;
  text-align: center;
}

.btn-counter {
  background: #414247;
  border: none;
  color: #fefefe;
  border-radius: 6px;
  width: 36px;
  height: 36px;
  font-size: 1.1rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, color 0.2s;
  font-family: 'Poppins', sans-serif;
}

.btn-counter:hover {
  background: #ffd170;
  color: #292b2d;
}

.btn-counter:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.card-identity {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.4em;
}

.avatar-circle {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: #414247;
  border: 2px solid #595d63;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #bbb;
}

.player-name {
  font-size: 1.25rem;
  font-weight: 700;
  text-align: center;
  word-break: break-word;
}

/* Life section */
.life-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0.6em;
  border-top: 1px solid #414247;
  border-bottom: 1px solid #414247;
  gap: 0.4em;
}

.life-label {
  font-size: 1rem;
  color: #bbb;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.life-controls {
  display: flex;
  align-items: center;
  gap: 1em;
}

.btn-life {
  background: #414247;
  border: none;
  color: #fefefe;
  border-radius: 12px;
  width: 64px;
  height: 64px;
  font-size: 2rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, color 0.2s;
  font-family: 'Poppins', sans-serif;
}

.btn-life:hover {
  background: #ffd170;
  color: #292b2d;
}

.btn-life:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.life-value {
  font-size: 5rem;
  font-weight: 800;
  min-width: 3.5rem;
  text-align: center;
  line-height: 1;
}

.life-value.low-life {
  color: #ff6b6b;
}

.cdmg-summary {
  font-size: 0.9rem;
  color: #bbb;
}

/* Commander Damage section */
.card-cdmg {
  padding: 0.6em 1em;
  display: flex;
  flex-direction: column;
  gap: 0.4em;
}

.cdmg-label {
  font-size: 0.85rem;
  color: #bbb;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.cdmg-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5em;
}

.cdmg-badge {
  background: #414247;
  border: 1px solid #595d63;
  color: #fefefe;
  border-radius: 8px;
  padding: 0.4em 0.85em;
  font-size: 0.95rem;
  cursor: pointer;
  font-family: 'Poppins', sans-serif;
  transition: background 0.2s, color 0.2s;
}

.cdmg-badge:hover {
  background: #ffd170;
  color: #292b2d;
  border-color: #ffd170;
}

.cdmg-badge.lethal {
  border-color: #ff6b6b;
  color: #ff6b6b;
}

.cdmg-badge:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

/* Footer */
.match-footer {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1em;
  padding: 0.75em 1em;
  background: #212121;
}

.footer-tools {
  display: flex;
  align-items: center;
  gap: 0.5em;
}

.btn-tool {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.15em;
  background: #414247;
  border: 1px solid #595d63;
  color: #fefefe;
  border-radius: 10px;
  padding: 0.45em 0.85em;
  cursor: pointer;
  font-size: 1.3rem;
  font-family: 'Poppins', sans-serif;
  transition: background 0.2s, border-color 0.2s;
  line-height: 1;
}

.btn-tool:hover {
  background: #595d63;
  border-color: #ffd170;
}

.btn-tool-label {
  font-size: 0.6rem;
  color: #bbb;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  line-height: 1;
}

.footer-actions {
  display: flex;
  align-items: center;
  gap: 1em;
}

.btn-end {
  background: #c0392b;
  color: white;
  border: none;
  padding: 0.75em 2em;
  cursor: pointer;
  border-radius: 10px;
  font-weight: 600;
  font-size: 1.1rem;
  font-family: 'Poppins', sans-serif;
  transition: background 0.2s;
}

.btn-end:hover {
  background: #e74c3c;
}

.btn-end:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-back {
  background: #414247;
  color: #fefefe;
  border: none;
  padding: 0.75em 2em;
  cursor: pointer;
  border-radius: 10px;
  font-weight: 600;
  font-size: 1.1rem;
  font-family: 'Poppins', sans-serif;
  transition: background 0.2s;
}

.btn-back:hover {
  background: #595d63;
}

.results-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.75);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.results-modal {
  background: #313338;
  border-radius: 20px;
  padding: 2.5em 3em;
  width: 100%;
  max-width: 480px;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.5);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.25em;
  font-family: 'Poppins', sans-serif;
  color: #fefefe;
}

.results-title {
  margin: 0;
  font-size: 2rem;
  font-weight: 700;
  color: #ffd170;
  text-align: center;
}

.results-list {
  list-style: none;
  margin: 0;
  padding: 0;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.6em;
}

.results-item {
  display: flex;
  align-items: center;
  gap: 0.75em;
  background: #292b2d;
  border-radius: 12px;
  padding: 0.75em 1em;
  border: 2px solid transparent;
  transition: border-color 0.2s;
}

.results-item.winner {
  border-color: #ffd170;
  background: #2e2c1e;
}

.result-placement {
  font-size: 1.25rem;
  font-weight: 800;
  color: #ffd170;
  min-width: 1.5em;
  text-align: center;
}

.result-name {
  flex: 1;
  font-size: 1rem;
  font-weight: 600;
}

.result-life {
  font-size: 0.9rem;
  color: #aaa;
}

.result-trophy {
  font-size: 1.3rem;
}

.btn-lobby {
  margin-top: 0.5em;
  padding: 0.65em 2em;
  background-color: #ffd170;
  border-radius: 12px;
  color: #292b2d;
  border: none;
  font-family: 'Poppins', sans-serif;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-lobby:hover {
  background-color: #ffc107;
}

.error {
  color: #ff6b6b;
}

/* Commander Damage Modal */
.cdmg-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.75);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 900;
  backdrop-filter: blur(4px);
}

.cdmg-modal {
  background: #313338;
  border-radius: 20px;
  padding: 2em 2.5em;
  width: 100%;
  max-width: 320px;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.6);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5em;
  font-family: 'Poppins', sans-serif;
  color: #fefefe;
  position: relative;
}

.cdmg-modal-close {
  position: absolute;
  top: 0.75em;
  right: 0.9em;
  background: none;
  border: none;
  color: #888;
  font-size: 1.1rem;
  cursor: pointer;
  font-family: 'Poppins', sans-serif;
  line-height: 1;
  transition: color 0.2s;
}

.cdmg-modal-close:hover { color: #fefefe; }

.cdmg-modal-sub {
  font-size: 0.72rem;
  color: #888;
  text-transform: uppercase;
  letter-spacing: 0.07em;
  margin-top: 0.5em;
}

.cdmg-modal-dealer {
  font-size: 1.3rem;
  font-weight: 700;
  color: #ffd170;
}

.cdmg-modal-arrow {
  font-size: 1rem;
  color: #595d63;
}

.cdmg-modal-receiver {
  font-size: 1.1rem;
  font-weight: 600;
  color: #fefefe;
  margin-bottom: 0.5em;
}

.cdmg-modal-controls {
  display: flex;
  align-items: center;
  gap: 1.25em;
  margin-top: 0.5em;
}

.cdmg-modal-btn {
  background: #414247;
  border: none;
  color: #fefefe;
  border-radius: 12px;
  width: 52px;
  height: 52px;
  font-size: 1.8rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, color 0.2s;
  font-family: 'Poppins', sans-serif;
  line-height: 1;
}

.cdmg-modal-btn:hover {
  background: #ffd170;
  color: #292b2d;
}

.cdmg-modal-value {
  font-size: 3.5rem;
  font-weight: 800;
  min-width: 3rem;
  text-align: center;
  line-height: 1;
}

.cdmg-modal-value.cdmg-lethal {
  color: #ff6b6b;
}

.cdmg-modal-lethal-warn {
  font-size: 0.85rem;
  font-weight: 700;
  color: #ff6b6b;
  margin-top: 0.25em;
}

/* Random Tools Modal */
.random-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 950;
  backdrop-filter: blur(4px);
}

.random-modal {
  background: #313338;
  border-radius: 20px;
  padding: 2em 2.5em;
  width: 100%;
  max-width: 360px;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.6);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1em;
  font-family: 'Poppins', sans-serif;
  color: #fefefe;
  position: relative;
}

.random-modal-close {
  position: absolute;
  top: 0.75em;
  right: 0.9em;
  background: none;
  border: none;
  color: #888;
  font-size: 1.1rem;
  cursor: pointer;
  font-family: 'Poppins', sans-serif;
  transition: color 0.2s;
}
.random-modal-close:hover { color: #fefefe; }

.random-modal-title {
  font-size: 1.4rem;
  font-weight: 700;
  color: #ffd170;
  margin-top: 0.25em;
}

.random-result {
  width: 140px;
  height: 140px;
  border-radius: 50%;
  background: #292b2d;
  border: 3px solid #595d63;
  display: flex;
  align-items: center;
  justify-content: center;
}

.random-placeholder {
  font-size: 3rem;
  opacity: 0.3;
}

.random-value {
  font-size: 3rem;
  font-weight: 800;
  text-align: center;
  line-height: 1.1;
}

.random-value.heads {
  color: #ffd170;
}

.random-value.tails {
  color: #a78bfa;
}

.random-player-name {
  font-size: 1.5rem;
  color: #ffd170;
  padding: 0 0.5em;
  word-break: break-word;
  text-align: center;
}

.dice-sides-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4em;
  justify-content: center;
}

.btn-sides {
  background: #414247;
  border: 2px solid transparent;
  color: #fefefe;
  border-radius: 8px;
  padding: 0.3em 0.65em;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  font-family: 'Poppins', sans-serif;
  transition: background 0.2s, border-color 0.2s;
}

.btn-sides:hover {
  background: #595d63;
}

.btn-sides.active {
  border-color: #ffd170;
  color: #ffd170;
  background: #2e2c1e;
}

.custom-sides {
  display: flex;
  align-items: center;
  gap: 0.5em;
}

.custom-sides-label {
  font-size: 0.85rem;
  color: #bbb;
}

.custom-sides-input {
  width: 70px;
  background: #292b2d;
  border: 1px solid #595d63;
  color: #fefefe;
  border-radius: 8px;
  padding: 0.3em 0.5em;
  font-size: 1rem;
  font-family: 'Poppins', sans-serif;
  text-align: center;
}

.custom-sides-input:focus {
  outline: none;
  border-color: #ffd170;
}

.btn-roll {
  background: #ffd170;
  color: #292b2d;
  border: none;
  padding: 0.65em 2em;
  cursor: pointer;
  border-radius: 12px;
  font-weight: 700;
  font-size: 1.05rem;
  font-family: 'Poppins', sans-serif;
  transition: background 0.2s;
}

.btn-roll:hover {
  background: #ffc107;
}

.random-note {
  font-size: 0.75rem;
  color: #888;
  text-align: center;
}
</style>
