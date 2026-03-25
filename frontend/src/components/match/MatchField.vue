<template>
    <div class="match-field">
        <h2>{{ matchData?.name || 'Match' }}</h2>

        <div v-if="matchData" class="match-info">
            <span><strong>Format:</strong> {{ matchData.format }}</span>
            <span><strong>Starting Life:</strong> {{ matchData.startingLife }}</span>
        </div>

        <div v-if="matchData?.players" class="players-list">
            <div v-for="player in matchData.players" :key="player.id" class="player-card">
                <h4>{{ player.name }}</h4>

                <div class="stat-row">
                    <span class="stat-label">Life</span>
                    <button class="btn-adjust" @click="adjust(player, 'currentLife', -1)" :disabled="matchEnded">−</button>
                    <span class="stat-value">{{ player.currentLife }}</span>
                    <button class="btn-adjust" @click="adjust(player, 'currentLife', 1)" :disabled="matchEnded">+</button>
                </div>

                <div v-if="matchData.hasTax" class="stat-row">
                    <span class="stat-label">Tax</span>
                    <button class="btn-adjust" @click="adjust(player, 'tax', -1)" :disabled="matchEnded">−</button>
                    <span class="stat-value">{{ player.tax }}</span>
                    <button class="btn-adjust" @click="adjust(player, 'tax', 1)" :disabled="matchEnded">+</button>
                </div>

                <div v-if="matchData.hasPoison" class="stat-row">
                    <span class="stat-label">Poison</span>
                    <button class="btn-adjust" @click="adjustPoison(player, -1)" :disabled="matchEnded">−</button>
                    <span class="stat-value" :class="{ lethal: player.poisonCounter >= 10 }">{{ player.poisonCounter }}</span>
                    <button class="btn-adjust" @click="adjustPoison(player, 1)" :disabled="matchEnded">+</button>
                </div>

                <div v-if="matchData.hasCommanderDamage && player.commanderDamage" class="commander-damage">
                    <p class="section-label">Commander Damage Received</p>
                    <div v-for="(amount, dealerId) in player.commanderDamage" :key="dealerId" class="stat-row">
                        <span class="stat-label">From {{ getPlayerName(dealerId) }}</span>
                        <button class="btn-adjust" @click="adjustCommanderDamage(player, dealerId, -1)" :disabled="matchEnded">−</button>
                        <span class="stat-value" :class="{ lethal: amount >= 21 }">{{ amount }}</span>
                        <button class="btn-adjust" @click="adjustCommanderDamage(player, dealerId, 1)" :disabled="matchEnded">+</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- End Match results -->
        <div v-if="matchEnded && results.length" class="results-panel">
            <h3>Final Results</h3>
            <ol>
                <li v-for="p in results" :key="p.id">
                    {{ p.placement }}. {{ p.name }} — {{ p.finalLife }} life
                    <span v-if="p.isWinner"> 🏆</span>
                </li>
            </ol>
            <p v-if="endError" class="error">{{ endError }}</p>
        </div>

        <div class="actions">
            <button v-if="!matchEnded" class="btn-end" @click="endMatch" :disabled="ending">
                {{ ending ? 'Saving...' : 'End Match' }}
            </button>
            <button class="btn-back" @click="goBack">Back to Match Setup</button>
        </div>
    </div>
</template>

<script>
import { useRouter, useRoute } from 'vue-router';
import { playerService } from '../../services/player.service';

export default {
    setup() {
        const router = useRouter();
        const route = useRoute();
        return { router, route };
    },
    data() {
        return {
            matchData: null,
            matchEnded: false,
            ending: false,
            endError: '',
            results: [],
        };
    },
    created() {
        const matchId = this.$route.params.id;
        const stored = localStorage.getItem(`match_${matchId}`);
        if (stored) {
            const parsed = JSON.parse(stored);
            this.matchData = {
                ...parsed,
                players: parsed.players.map(p => ({
                    ...p,
                    currentLife: p.currentLife ?? p.startingLife
                }))
            };
        }
    },
    methods: {
        adjust(player, field, delta) {
            player[field] = Math.max(0, player[field] + delta);
        },
        adjustPoison(player, delta) {
            const prev = player.poisonCounter;
            player.poisonCounter = Math.max(0, prev + delta);
            const applied = player.poisonCounter - prev;
            player.currentLife = Math.max(0, player.currentLife - applied);
        },
        adjustCommanderDamage(player, dealerId, delta) {
            const prev = player.commanderDamage[dealerId];
            const next = Math.max(0, prev + delta);
            const applied = next - prev;
            player.commanderDamage = { ...player.commanderDamage, [dealerId]: next };
            player.currentLife = Math.max(0, player.currentLife - applied);
        },
        getPlayerName(id) {
            return this.matchData.players.find(p => p.id === parseInt(id))?.name || `Player ${id}`;
        },
        async endMatch() {
            this.ending = true;
            this.endError = '';
            try {
                // Sort by currentLife descending; ties broken by original position
                const sorted = [...this.matchData.players]
                    .sort((a, b) => b.currentLife - a.currentLife);

                // Assign placements (1 = most life = winner, last = eliminated/least life)
                const withPlacements = sorted.map((p, i) => ({
                    ...p,
                    finalLife: p.currentLife,
                    placement: i + 1,
                    isWinner: i === 0,
                }));

                // Save each player to the DB
                const updates = withPlacements.map(p => {
                    if (!p.pk_player) return Promise.resolve();
                    return playerService.updatePlayer(p.pk_player, {
                        finalLife: p.finalLife,
                        placement: p.placement,
                        isWinner: p.isWinner,
                        poisonCounter: p.poisonCounter ?? undefined,
                        tax: p.tax ?? undefined,
                    });
                });
                await Promise.all(updates);

                this.results = withPlacements;
                this.matchEnded = true;
                localStorage.removeItem(`match_${this.$route.params.id}`);
            } catch (err) {
                this.endError = err?.response?.data?.message || err?.message || 'Failed to save match results.';
            } finally {
                this.ending = false;
            }
        },
        goBack() {
            localStorage.removeItem(`match_${this.$route.params.id}`);
            this.router.push('/match');
        }
    },
    watch: {
        matchData: {
            deep: true,
            handler(val) {
                if (this.matchEnded) return;
                const matchId = this.$route.params.id;
                localStorage.setItem(`match_${matchId}`, JSON.stringify(val));
            }
        }
    }
};
</script>

<style scoped>
.actions {
    display: flex;
    gap: 12px;
    margin-top: 24px;
}
.btn-end {
    background: #c0392b;
    color: white;
    border: none;
    padding: 10px 20px;
    cursor: pointer;
    border-radius: 4px;
    font-size: 1rem;
}
.btn-end:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}
.results-panel {
    margin-top: 20px;
    padding: 16px;
    background: #f9f9f9;
    border: 1px solid #ddd;
    border-radius: 6px;
}
.results-panel ol {
    padding-left: 20px;
}
.results-panel li {
    margin: 6px 0;
    font-size: 1rem;
}
.error {
    color: red;
    margin-top: 8px;
}
</style>
