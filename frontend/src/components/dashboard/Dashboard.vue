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
          <h2 class="recent-title">Recent Matches</h2>
          <p v-if="!stats" class="recent-empty">Loading…</p>
          <p v-else-if="!stats.recentMatches || stats.recentMatches.length === 0" class="recent-empty">
            No matches played yet.
          </p>
          <div v-else class="recent-list">
            <div
              v-for="match in stats.recentMatches"
              :key="match.matchId"
              class="recent-row"
              :class="{ clickable: match.finalLife == null }"
              @click="match.finalLife == null && router.push('/match/' + match.matchId)"
            >
              <div class="recent-info">
                <span class="recent-name">{{ match.matchName }}</span>
                <span class="recent-meta">{{ match.format }} &middot; {{ formatDate(match.endTime ?? match.startTime) }}</span>
              </div>
              <div class="recent-right">
                <span class="recent-placement" v-if="match.finalLife != null">#{{ match.placement ?? '—' }}</span>
                <span class="recent-badge" :class="match.finalLife != null ? (match.isWinner ? 'win' : 'loss') : 'in-progress'">
                  {{ match.finalLife != null ? (match.isWinner ? 'Win' : 'Loss') : 'In Progress' }}
                </span>
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

export default {
  components: { Sidebar },
  data() {
    return {
      stats: null,
      friendCount: null,
    }
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
