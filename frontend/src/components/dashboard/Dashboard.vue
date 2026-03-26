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
        <div class="box"></div>
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
    return { router }
  },
}


</script>

<style scoped src="./dashboard.css"></style>
