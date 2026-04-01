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

        <!-- Recent matches / Leaderboard -->
        <div class="section-card">
          <div class="section-header-row">
            <h2 class="section-title">{{ activeView === 'matches' ? 'Recent Matches' : 'Leaderboard' }}</h2>
            <div class="view-toggle">
              <button :class="['toggle-btn', { active: activeView === 'matches' }]" @click="switchView('matches')">Recent Matches</button>
              <button :class="['toggle-btn', { active: activeView === 'leaderboard' }]" @click="switchView('leaderboard')">Leaderboard</button>
            </div>
          </div>

          <!-- Recent Matches table -->
          <template v-if="activeView === 'matches'">
            <p v-if="!stats.recentMatches?.length" class="empty-state">No matches played yet.</p>
            <div v-else class="match-table-scroll">
              <table class="match-table">
                <thead>
                  <tr>
                    <th>Match</th>
                    <th>Format</th>
                    <th>Start</th>
                    <th>End</th>
                    <th>Placement</th>
                    <th>Final Life</th>
                    <th>Result</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="m in stats.recentMatches.filter((m: any) => m.endTime != null)"
                    :key="m.matchId"
                    class="match-row"
                    @click="openMatch(m)"
                  >
                    <td>{{ m.matchName }}</td>
                    <td>{{ m.format }}</td>
                    <td>{{ formatTime(m.startTime) }}</td>
                    <td>{{ formatTime(m.endTime) }}</td>
                    <td><span class="placement-badge">#{{ m.placement }}</span></td>
                    <td>{{ m.finalLife ?? '—' }}</td>
                    <td>
                      <span class="pill" :class="m.isWinner ? 'win' : 'loss'">
                        {{ m.isWinner ? 'Win' : 'Loss' }}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>

          <!-- Leaderboard table -->
          <template v-else>
            <p v-if="leaderboardLoading" class="empty-state">Loading leaderboard…</p>
            <p v-else-if="!leaderboard.length" class="empty-state">No data yet. Play some matches!</p>
            <div v-else class="match-table-scroll">
              <table class="match-table">
                <thead>
                  <tr>
                    <th>Rank</th>
                    <th>Player</th>
                    <th>Games</th>
                    <th>Wins</th>
                    <th>Losses</th>
                    <th>Win %</th>
                    <th>Avg Place</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(row, i) in leaderboard" :key="row.userId" class="match-row">
                    <td>
                      <span v-if="i === 0" class="rank-crown">👑</span>
                      <span v-else class="placement-badge">#{{ i + 1 }}</span>
                    </td>
                    <td class="lb-username">{{ row.username }}</td>
                    <td>{{ row.totalGames }}</td>
                    <td><span class="pill win">{{ row.wins }}</span></td>
                    <td><span class="pill loss">{{ row.losses }}</span></td>
                    <td>
                      <span :class="['winpct', row.winRate >= 50 ? 'good' : row.winRate >= 25 ? 'neutral' : 'bad']">
                        {{ row.winRate }}%
                      </span>
                    </td>
                    <td>{{ row.avgPlacement }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>
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
          <span class="meta-chip">▶ {{ formatTime(selectedMatch.startTime) }}</span>
          <span class="meta-chip">⏹ {{ formatTime(selectedMatch.endTime) }}</span>
        </div>
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
      </div>
    </div>
  </Teleport>
</template>

<script lang="ts" src="./stats"></script>

<style scoped src="./stats.css"></style>
