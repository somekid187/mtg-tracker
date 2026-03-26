<template>
  <div class="page-layout">
    <Sidebar />

    <div class="stats-content">
      <h1 class="page-title">Statistics</h1>

      <p v-if="loading" class="loading">Loading your stats…</p>

      <template v-else-if="stats">
        <!-- Summary cards -->
        <div class="stat-cards">
          <div class="stat-card">
            <span class="stat-label">Total Games</span>
            <span class="stat-value neutral">{{ stats.totalGames }}</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">Wins</span>
            <span class="stat-value good">{{ stats.wins }}</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">Losses</span>
            <span class="stat-value bad">{{ stats.losses }}</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">Win Rate</span>
            <span class="stat-value" :class="winRateClass">{{ stats.winRate }}%</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">Avg Placement</span>
            <span class="stat-value neutral">{{ stats.avgPlacement }}</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">Avg Final Life</span>
            <span class="stat-value neutral">{{ stats.avgFinalLife }}</span>
          </div>
        </div>

        <!-- Win rate bar -->
        <div class="section-card">
          <h2 class="section-title">Win Rate</h2>
          <div class="winrate-bar-wrap">
            <div class="winrate-bar-track">
              <div class="winrate-bar-fill" :style="{ width: stats.winRate + '%' }"></div>
            </div>
            <div class="winrate-labels">
              <span>{{ stats.wins }} W</span>
              <span>{{ stats.winRate }}%</span>
              <span>{{ stats.losses }} L</span>
            </div>
          </div>
        </div>

        <!-- Recent matches -->
        <div class="section-card">
          <h2 class="section-title">Recent Matches</h2>
          <p v-if="!stats.recentMatches?.length" class="empty-state">No matches played yet.</p>
          <div v-else class="match-table-scroll">
            <table class="match-table">
              <thead>
                <tr>
                  <th>Match</th>
                  <th>Format</th>
                  <th>Placement</th>
                  <th>Final Life</th>
                  <th>Result</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="m in stats.recentMatches"
                  :key="m.matchId"
                  class="match-row"
                  @click="openMatch(m)"
                >
                  <td>{{ m.matchName }}</td>
                  <td>{{ m.format }}</td>
                  <td>
                    <span v-if="m.finalLife != null" class="placement-badge">#{{ m.placement }}</span>
                    <span v-else class="pill in-progress">In Progress</span>
                  </td>
                  <td>{{ m.finalLife ?? '—' }}</td>
                  <td>
                    <span v-if="m.finalLife != null" class="pill" :class="m.isWinner ? 'win' : 'loss'">
                      {{ m.isWinner ? 'Win' : 'Loss' }}
                    </span>
                    <span v-else class="pill in-progress">—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </template>

      <p v-else class="empty-state">Could not load stats. Play some matches first!</p>
    </div>
  </div>

  <!-- Match modal -->
  <Teleport to="body">
    <div v-if="selectedMatch" class="modal-overlay" @click.self="selectedMatch = null">
      <div class="modal-card">
        <h2 class="modal-title">{{ selectedMatch.matchName }}</h2>
        <div class="modal-meta">
          <span class="meta-chip">{{ selectedMatch.format }}</span>
        </div>

        <template v-if="selectedMatch.finalLife != null">
          <!-- Finished match details -->
          <div class="modal-result">
            <div class="result-row">
              <span class="result-label">Result</span>
              <span class="pill" :class="selectedMatch.isWinner ? 'win' : 'loss'">
                {{ selectedMatch.isWinner ? 'Win 🏆' : 'Loss' }}
              </span>
            </div>
            <div class="result-row">
              <span class="result-label">Placement</span>
              <span class="placement-badge">#{{ selectedMatch.placement }}</span>
            </div>
            <div class="result-row">
              <span class="result-label">Final Life</span>
              <span>{{ selectedMatch.finalLife }}</span>
            </div>
            <div class="result-row">
              <span class="result-label">Starting Life</span>
              <span>{{ selectedMatch.startingLife }}</span>
            </div>
          </div>
          <button class="btn-close" @click="selectedMatch = null">Close</button>
        </template>

        <template v-else>
          <!-- Unfinished match -->
          <p class="modal-body">This match is still in progress. You can resume where you left off.</p>
          <div class="modal-actions">
            <button class="btn-resume" @click="resumeMatch(selectedMatch.matchId)">▶ Resume Match</button>
            <button class="btn-close" @click="selectedMatch = null">Cancel</button>
          </div>
        </template>
      </div>
    </div>
  </Teleport>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'
import { userService } from '../../services/user.service'

export default defineComponent({
  name: 'Stats',
  components: { Sidebar },
  setup() {
    const router = useRouter()
    const stats = ref<any>(null)
    const loading = ref(true)
    const selectedMatch = ref<any>(null)

    const winRateClass = computed(() => {
      if (!stats.value) return 'neutral'
      if (stats.value.winRate >= 50) return 'good'
      if (stats.value.winRate >= 25) return 'neutral'
      return 'bad'
    })

    function openMatch(m: any) {
      selectedMatch.value = m
    }

    function resumeMatch(matchId: number) {
      selectedMatch.value = null
      router.push(`/match/${matchId}`)
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

    return { stats, loading, winRateClass, selectedMatch, openMatch, resumeMatch }
  },
})
</script>

<style scoped src="./stats.css"></style>
