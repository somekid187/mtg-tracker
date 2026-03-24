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
                    <button class="btn-adjust" @click="adjust(player, 'currentLife', -1)">−</button>
                    <span class="stat-value">{{ player.currentLife }}</span>
                    <button class="btn-adjust" @click="adjust(player, 'currentLife', 1)">+</button>
                </div>

                <div v-if="matchData.hasTax" class="stat-row">
                    <span class="stat-label">Tax</span>
                    <button class="btn-adjust" @click="adjust(player, 'tax', -1)">−</button>
                    <span class="stat-value">{{ player.tax }}</span>
                    <button class="btn-adjust" @click="adjust(player, 'tax', 1)">+</button>
                </div>

                <div v-if="matchData.hasPoison" class="stat-row">
                    <span class="stat-label">Poison</span>
                    <button class="btn-adjust" @click="adjustPoison(player, -1)">−</button>
                    <span class="stat-value" :class="{ lethal: player.poisonCounter >= 10 }">{{ player.poisonCounter
                        }}</span>
                    <button class="btn-adjust" @click="adjustPoison(player, 1)">+</button>
                </div>

                <div v-if="matchData.hasCommanderDamage && player.commanderDamage" class="commander-damage">
                    <p class="section-label">Commander Damage Received</p>
                    <div v-for="(amount, dealerId) in player.commanderDamage" :key="dealerId" class="stat-row">
                        <span class="stat-label">From {{ getPlayerName(dealerId) }}</span>
                        <button class="btn-adjust" @click="adjustCommanderDamage(player, dealerId, -1)">−</button>
                        <span class="stat-value" :class="{ lethal: amount >= 21 }">{{ amount }}</span>
                        <button class="btn-adjust" @click="adjustCommanderDamage(player, dealerId, 1)">+</button>
                    </div>
                </div>
            </div>
        </div>

        <button class="btn-back" @click="goBack">Back to Match Setup</button>
    </div>
</template>

<script>
import { useRouter } from 'vue-router';

export default {
    setup() {
        const router = useRouter();
        return { router };
    },
    data() {
        return {
            matchData: null
        };
    },
    created() {
        const state = window.history.state?.matchData;
        if (state) {
            const parsed = JSON.parse(JSON.stringify(state));
            this.matchData = {
                ...parsed,
                players: parsed.players.map(p => ({
                    ...p,
                    currentLife: p.startingLife
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
        goBack() {
            this.router.push('/match');
        }
    }
};
</script>

<style scoped>
</style>
