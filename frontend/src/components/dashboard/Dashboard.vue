<template>
  <div class="page-layout">
    <Sidebar />
    <div class="dashboard-content">
      <div class="dashboard-row">
        <div class="box stat-box">
          <img src="/assets/crown.svg" class="stat-icon" alt="Wins" />
          <span class="stat-label">Wins</span>
          <span class="stat-value good">{{ stats ? stats.wins : '—' }}</span>
        </div>
        <div class="box stat-box">
          <img src="/assets/games.png" class="stat-icon" alt="Games Played" />
          <span class="stat-label">Games Played</span>
          <span class="stat-value">{{ stats ? stats.totalGames : '—' }}</span>
        </div>
        <div class="box stat-box">
          <img src="/assets/friends.png" class="stat-icon" alt="Friends" />
          <span class="stat-label">Friends</span>
          <span class="stat-value">{{ friendCount !== null ? friendCount : '—' }}</span>
        </div>
      </div>
      <div class="dashboard-row">
        <div class="create-match box">
          <h2>Create Match</h2>
          <p>Start a new match and track your stats in real-time.</p>
          <button class="btn-primary" @click="router.push('/match')">Create Match</button>
        </div>
        <div class="create-event box">
          <h2>Create Event</h2>
          <p>Organize your tournaments and events with ease.</p>
          <button class="btn-primary" @click="router.push('/event')">Create Event</button>
        </div>
      </div>
      <div class="dashboard-row">
        <div class="box recent-matches-box">
          <h2 class="recent-title">Ongoing Matches</h2>
          <p v-if="!stats" class="recent-empty">Loading…</p>
          <p v-else-if="inProgressMatches.length === 0" class="recent-empty">
            No ongoing matches.
          </p>
          <div v-else class="recent-list">
            <div
              v-for="match in inProgressMatches"
              :key="match.matchId"
              class="recent-row clickable"
              @click="router.push('/match/' + match.matchId)"
            >
              <div class="recent-info">
                <span class="recent-name">{{ match.matchName }}</span>
                <span class="recent-meta">{{ match.format }} &middot; {{ formatDate(match.startTime) }}</span>
              </div>
              <div class="recent-right">
                <span class="recent-badge in-progress">In Progress</span>
                <button class="btn-delete-match" @click.stop="deleteMatch(match)" title="Delete match">✕</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { useRouter } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'
import { userService } from '../../services/user.service'
import { matchService } from '../../services/match.service'

export default {
  components: { Sidebar },
  data() {
    return {
      stats: null,
      friendCount: null,
    }
  },
  computed: {
    inProgressMatches() {
      return this.stats?.recentMatches?.filter(m => !m.endTime) ?? []
    },
  },
  async mounted() {
    try {
      const [statsRes, friendsRes] = await Promise.all([
        userService.getStats(),
        userService.getFriends(),
      ])
      this.stats = statsRes.data
      this.friendCount = Array.isArray(friendsRes.data) ? friendsRes.data.length : 0
    } catch {
      // silently fail — counters stay as '—'
    }
  },
  methods: {
    async deleteMatch(match) {
      try {
        await matchService.deleteMatch(match.matchId)
        localStorage.removeItem(`match_${match.matchId}`)
        this.stats.recentMatches = this.stats.recentMatches.filter(m => m.matchId !== match.matchId)
      } catch {
        // silently fail
      }
    },
  },
  setup() {
    const router = useRouter()
    function formatDate(dateStr) {
      if (!dateStr) return '—'
      // MySQL returns 'YYYY-MM-DD HH:MM:SS' — replace space with T for valid ISO parsing
      const iso = String(dateStr).replace(' ', 'T')
      const d = new Date(iso)
      if (isNaN(d.getTime())) return '—'
      return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
    }
    return { router, formatDate }
  },
}


</script>

<style scoped src="./dashboard.css"></style>
