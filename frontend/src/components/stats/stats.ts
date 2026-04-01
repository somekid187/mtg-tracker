import { defineComponent, ref, computed, onMounted } from 'vue'
import Sidebar from '../shared/Sidebar.vue'
import { userService } from '../../services/user.service'

export default defineComponent({
  name: 'Stats',
  components: { Sidebar },
  setup() {
    const stats = ref<any>(null)
    const loading = ref(true)
    const selectedMatch = ref<any>(null)
    const activeView = ref<'matches' | 'leaderboard'>('matches')
    const leaderboard = ref<any[]>([])
    const leaderboardLoading = ref(false)
    const leaderboardLoaded = ref(false)

    const winRateClass = computed(() => {
      if (!stats.value) return 'neutral'
      if (stats.value.winRate >= 50) return 'good'
      if (stats.value.winRate >= 25) return 'neutral'
      return 'bad'
    })

    function formatTime(t: string | null | undefined): string {
      if (!t) return '—'
      // MySQL DATETIME returns "YYYY-MM-DD HH:MM:SS"
      const iso = String(t).replace(' ', 'T')
      const d = new Date(iso)
      if (isNaN(d.getTime())) return '—'
      return d.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
    }

    function openMatch(m: any) {
      selectedMatch.value = m
    }

    async function loadLeaderboard() {
      if (leaderboardLoaded.value) return
      leaderboardLoading.value = true
      try {
        const res = await userService.getLeaderboard()
        leaderboard.value = Array.isArray(res.data) ? res.data : []
        leaderboardLoaded.value = true
      } catch {
        leaderboard.value = []
      } finally {
        leaderboardLoading.value = false
      }
    }

    function switchView(view: 'matches' | 'leaderboard') {
      activeView.value = view
      if (view === 'leaderboard') loadLeaderboard()
    }

    onMounted(async () => {
      try {
        const res = await userService.getStats()
        stats.value = res.data
      } catch {
        stats.value = null
      } finally {
        loading.value = false
      }
    })

    return { stats, loading, winRateClass, selectedMatch, openMatch, formatTime,
             activeView, leaderboard, leaderboardLoading, switchView }
  },
})