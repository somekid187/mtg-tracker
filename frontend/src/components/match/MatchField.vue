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
            :class="{ flipped: row.flipped, eliminated: player.currentLife <= 0 }"
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
                  <svg viewBox="0 0 24 24" fill="currentColor" width="32" height="32">
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
                  @click="adjustCommanderDamage(player, dealerId, 1)"
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
        <button v-if="!matchEnded" class="btn-end" @click="endMatch" :disabled="ending">
          {{ ending ? 'Saving...' : 'End Match' }}
        </button>
        <button class="btn-back" @click="goBack">Back</button>
      </div>

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
    }
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
    adjust(player, field, delta) {
      player[field] = Math.max(0, player[field] + delta)
    },
    adjustPoison(player, delta) {
      const prev = player.poisonCounter
      player.poisonCounter = Math.max(0, prev + delta)
      const applied = player.poisonCounter - prev
      player.currentLife = Math.max(0, player.currentLife - applied)
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
        // Sort by currentLife descending; ties broken by original position
        const sorted = [...this.matchData.players].sort((a, b) => b.currentLife - a.currentLife)

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
    goBack() {
      localStorage.removeItem(`match_${this.$route.params.id}`)
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
  padding: 0.5em;
  gap: 0.5em;
  overflow: hidden;
}

.players-row {
  flex: 1;
  display: flex;
  gap: 0.5em;
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
  padding: 0.6em 0.75em;
  gap: 0.5em;
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
  font-size: 1.1rem;
  font-weight: 700;
  line-height: 1.1;
}

.counter-val.lethal {
  color: #ff6b6b;
}

.counter-ctrl {
  display: flex;
  align-items: center;
  gap: 0.3em;
}

.counter-name {
  font-size: 0.7rem;
  color: #bbb;
  min-width: 2.5em;
  text-align: center;
}

.btn-counter {
  background: #414247;
  border: none;
  color: #fefefe;
  border-radius: 4px;
  width: 20px;
  height: 20px;
  font-size: 0.85rem;
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
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: #414247;
  border: 2px solid #595d63;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #bbb;
}

.player-name {
  font-size: 1rem;
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
  padding: 0.4em;
  border-top: 1px solid #414247;
  border-bottom: 1px solid #414247;
  gap: 0.2em;
}

.life-label {
  font-size: 0.8rem;
  color: #bbb;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.life-controls {
  display: flex;
  align-items: center;
  gap: 0.6em;
}

.btn-life {
  background: #414247;
  border: none;
  color: #fefefe;
  border-radius: 8px;
  width: 36px;
  height: 36px;
  font-size: 1.3rem;
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
  font-size: 2.5rem;
  font-weight: 800;
  min-width: 3rem;
  text-align: center;
  line-height: 1;
}

.life-value.low-life {
  color: #ff6b6b;
}

.cdmg-summary {
  font-size: 0.72rem;
  color: #bbb;
}

/* Commander Damage section */
.card-cdmg {
  padding: 0.4em 0.75em;
  display: flex;
  flex-direction: column;
  gap: 0.3em;
}

.cdmg-label {
  font-size: 0.68rem;
  color: #bbb;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.cdmg-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.3em;
}

.cdmg-badge {
  background: #414247;
  border: 1px solid #595d63;
  color: #fefefe;
  border-radius: 6px;
  padding: 0.2em 0.5em;
  font-size: 0.7rem;
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
  justify-content: center;
  gap: 1em;
  padding: 0.5em 1em;
  background: #212121;
}

.btn-end {
  background: #c0392b;
  color: white;
  border: none;
  padding: 0.5em 1.5em;
  cursor: pointer;
  border-radius: 8px;
  font-weight: 600;
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
  padding: 0.5em 1.5em;
  cursor: pointer;
  border-radius: 8px;
  font-weight: 600;
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
</style>
