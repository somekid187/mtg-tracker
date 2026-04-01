<template>
  <div class="page-layout">
    <Sidebar />
    <div class="events-content">

      <!-- Loading / not found -->
      <div v-if="loading" class="events-empty">Loading…</div>
      <template v-else-if="event">

        <!-- Event header -->
        <div class="event-detail-header">
          <button class="btn-back" @click="router.push('/event')">← Events</button>
          <div class="event-detail-title-row">
            <h1 class="events-title">{{ event.name }}</h1>
            <span class="event-organizer">by {{ event.organizerUsername }}</span>
          </div>
          <p v-if="event.description" class="event-detail-desc">{{ event.description }}</p>
        </div>

        <!-- Tabs -->
        <div class="tab-bar">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            class="tab-btn"
            :class="{ active: activeTab === tab.id }"
            @click="activeTab = tab.id"
          >{{ tab.label }}</button>
        </div>

        <!-- ── TAB: Ongoing Matches ── -->
        <div v-if="activeTab === 'ongoing'" class="tab-content">
          <div class="tab-section-header">
            <span class="section-label">Ongoing Matches</span>
            <button class="btn-primary-inline" @click="showCreateMatch = true">+ Create Match</button>
          </div>
          <p v-if="ongoingMatches.length === 0" class="events-empty">No ongoing matches.</p>
          <div v-else class="match-list">
            <div
              v-for="m in ongoingMatches"
              :key="m.matchId"
              class="match-row clickable"
              @click="router.push('/match/' + m.matchId)"
            >
              <div class="match-info">
                <span class="match-name">{{ m.matchName || 'Untitled Match' }}</span>
                <span class="match-meta">{{ m.format }} · {{ formatDate(m.startTime) }}</span>
              </div>
              <div class="match-right">
                <span class="recent-badge in-progress">In Progress</span>
                <button class="btn-delete-match" @click.stop="removeMatch(m)" title="Remove from event">✕</button>
              </div>
            </div>
          </div>
        </div>

        <!-- ── TAB: Finished Matches ── -->
        <div v-if="activeTab === 'finished'" class="tab-content">
          <div class="tab-section-header">
            <span class="section-label">Finished Matches</span>
          </div>
          <p v-if="finishedMatches.length === 0" class="events-empty">No finished matches yet.</p>
          <div v-else class="match-list">
            <div
              v-for="m in finishedMatches"
              :key="m.matchId"
              class="match-row clickable"
              @click="router.push('/match/' + m.matchId)"
            >
              <div class="match-info">
                <span class="match-name">{{ m.matchName || 'Untitled Match' }}</span>
                <span class="match-meta">{{ m.format }} · {{ formatDate(m.startTime) }} → {{ formatDate(m.endTime) }}</span>
              </div>
              <div class="match-right">
                <span class="recent-badge finished">Finished</span>
                <button class="btn-delete-match" @click.stop="removeMatch(m)" title="Remove from event">✕</button>
              </div>
            </div>
          </div>
        </div>

        <!-- ── TAB: Stats ── -->
        <div v-if="activeTab === 'stats'" class="tab-content">
          <div class="tab-section-header">
            <span class="section-label">Event Stats</span>
          </div>
          <div v-if="statsLoading" class="events-empty">Loading stats…</div>
          <div v-else-if="stats.length === 0" class="events-empty">No stats yet. Finish some matches first!</div>
          <div v-else class="stats-grid">
            <div class="stat-card box" v-for="s in stats" :key="s.userId">
              <span class="stat-card-name">{{ s.username }}</span>
              <div class="stat-card-row"><span class="stat-lbl">Games</span><span class="stat-val">{{ s.gamesPlayed }}</span></div>
              <div class="stat-card-row"><span class="stat-lbl">Wins</span><span class="stat-val good">{{ s.wins }}</span></div>
              <div class="stat-card-row"><span class="stat-lbl">Losses</span><span class="stat-val">{{ s.losses }}</span></div>
              <div class="stat-card-row"><span class="stat-lbl">Avg Placement</span><span class="stat-val">{{ s.avgPlacement }}</span></div>
              <div class="stat-card-row"><span class="stat-lbl">Avg Final Life</span><span class="stat-val">{{ s.avgFinalLife }}</span></div>
            </div>
          </div>
        </div>

        <!-- ── TAB: Leaderboard ── -->
        <div v-if="activeTab === 'leaderboard'" class="tab-content">
          <div class="tab-section-header">
            <span class="section-label">Leaderboard</span>
          </div>
          <div v-if="statsLoading" class="events-empty">Loading…</div>
          <div v-else-if="stats.length === 0" class="events-empty">No data yet.</div>
          <div v-else class="leaderboard-table-wrap">
            <table class="leaderboard-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Player</th>
                  <th>Games</th>
                  <th>Wins</th>
                  <th>Losses</th>
                  <th>Avg Placement</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(s, i) in stats" :key="s.userId" :class="{ 'rank-top': i === 0 }">
                  <td class="rank-cell">
                    <span v-if="i === 0" class="rank-crown">👑</span>
                    <span v-else>{{ i + 1 }}</span>
                  </td>
                  <td>{{ s.username }}</td>
                  <td>{{ s.gamesPlayed }}</td>
                  <td class="wins-cell">{{ s.wins }}</td>
                  <td>{{ s.losses }}</td>
                  <td>{{ s.avgPlacement }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </template>
      <div v-else class="events-empty">Event not found.</div>

      <!-- Create Match inside event modal -->
      <div v-if="showCreateMatch" class="modal-overlay" @click.self="showCreateMatch = false">
        <div class="modal-box">
          <h2>Create Match</h2>
          <form @submit.prevent="createMatchInEvent">
            <div class="form-group">
              <input type="text" v-model="newMatch.name" class="form-input" placeholder="Match Name (optional)" />
              <select v-model="newMatch.format" class="form-input" required>
                <option value="">Select Format</option>
                <option v-for="f in formatOptions" :key="f.name" :value="f.name">{{ f.name }}</option>
              </select>
              <select v-model="newMatch.playerCount" class="form-input" required>
                <option value="">Select Player Count</option>
                <option v-for="n in [2,3,4,5,6]" :key="n" :value="n">{{ n }} Players</option>
              </select>
            </div>
            <p v-if="createMatchError" class="error-msg">{{ createMatchError }}</p>
            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showCreateMatch = false">Cancel</button>
              <button type="submit" class="btn-primary-inline" :disabled="creatingMatch">
                {{ creatingMatch ? 'Creating…' : 'Create & Join' }}
              </button>
            </div>
          </form>
        </div>
      </div>

    </div>
  </div>
</template>

<script>
import { useRouter, useRoute } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'
import { eventService } from '../../services/event.service'
import { matchService } from '../../services/match.service'
import formats from '../../utils/format.json'

export default {
  components: { Sidebar },
  setup() {
    const router = useRouter()
    const route = useRoute()
    function formatDate(dateStr) {
      if (!dateStr) return '—'
      const iso = String(dateStr).replace(' ', 'T')
      const d = new Date(iso)
      if (isNaN(d.getTime())) return '—'
      return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
    }
    return { router, route, formatDate }
  },
  data() {
    return {
      event: null,
      loading: true,
      activeTab: 'ongoing',
      tabs: [
        { id: 'ongoing', label: 'Ongoing' },
        { id: 'finished', label: 'Finished' },
        { id: 'stats', label: 'Stats' },
        { id: 'leaderboard', label: 'Leaderboard' },
      ],
      stats: [],
      statsLoading: false,
      statsLoaded: false,
      showCreateMatch: false,
      creatingMatch: false,
      createMatchError: '',
      newMatch: { name: '', format: '', playerCount: '' },
      formatOptions: formats.formats,
    }
  },
  computed: {
    ongoingMatches() {
      return (this.event?.matches ?? []).filter(m => !m.endTime)
    },
    finishedMatches() {
      return (this.event?.matches ?? []).filter(m => m.endTime)
    },
  },
  watch: {
    activeTab(tab) {
      if ((tab === 'stats' || tab === 'leaderboard') && !this.statsLoaded) {
        this.loadStats()
      }
    },
  },
  async mounted() {
    await this.loadEvent()
  },
  methods: {
    async loadEvent() {
      this.loading = true
      try {
        const res = await eventService.getEventById(Number(this.route.params.id))
        this.event = res.data
      } catch {
        this.event = null
      } finally {
        this.loading = false
      }
    },
    async loadStats() {
      this.statsLoading = true
      try {
        const res = await eventService.getEventStats(Number(this.route.params.id))
        this.stats = Array.isArray(res.data) ? res.data : []
        this.statsLoaded = true
      } catch {
        this.stats = []
      } finally {
        this.statsLoading = false
      }
    },
    async removeMatch(match) {
      try {
        await eventService.removeMatchFromEvent(this.event.pk_event, match.matchId)
        this.event.matches = this.event.matches.filter(m => m.matchId !== match.matchId)
        this.event.matchCount = (this.event.matchCount ?? 1) - 1
        // Reset stats so they reload
        this.statsLoaded = false
        this.stats = []
      } catch {
        // silently fail
      }
    },
    async createMatchInEvent() {
      if (!this.newMatch.format) { this.createMatchError = 'Please select a format.'; return }
      if (!this.newMatch.playerCount) { this.createMatchError = 'Please select player count.'; return }
      this.createMatchError = ''
      this.creatingMatch = true
      try {
        const selectedFormat = this.formatOptions.find(f => f.name === this.newMatch.format)
        const matchRes = await matchService.createMatch({
          name: this.newMatch.name || undefined,
          format: this.newMatch.format,
          startingLife: selectedFormat?.starting_life ?? 20,
          startTime: new Date().toISOString().slice(0, 19).replace('T', ' '),
          isTeamMatch: false,
        })
        const matchId = matchRes?.data?.matchId
        if (!matchId) throw new Error('Failed to create match')

        // Link match to this event
        await eventService.addMatchToEvent(this.event.pk_event, matchId)

        // Store local match data and redirect to setup
        localStorage.setItem(`match_pending_${matchId}`, JSON.stringify({
          matchId,
          matchName: this.newMatch.name || '',
          format: this.newMatch.format,
          startingLife: selectedFormat?.starting_life ?? 20,
          playerCount: this.newMatch.playerCount,
          inviteCode: matchRes?.data?.inviteCode ?? null,
          hasPoison: selectedFormat?.has_poison ?? false,
          hasTax: selectedFormat?.has_tax ?? false,
          hasCommanderDamage: selectedFormat?.has_commander_damage ?? false,
          eventId: this.event.pk_event,
        }))

        this.showCreateMatch = false
        this.router.push(`/match/setup/${matchId}`)
      } catch (err) {
        this.createMatchError = err?.response?.data?.message || err?.message || 'Failed to create match.'
      } finally {
        this.creatingMatch = false
      }
    },
  },
}
</script>

<style scoped src="./event.css"></style>
