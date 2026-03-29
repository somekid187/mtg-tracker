<template>
    <div class="page-layout">
        <Sidebar />
        <div class="match-content">
            <div class="match-container">
                <form @submit.prevent="createMatch" class="box form-section">
                    <h2>Create Match</h2>
                    <div class="form-group">
                        <input type="text" v-model="match.name" placeholder="Match Name (optional)" class="form-input" />
                        <select name="format" v-model="match.format" class="form-input">
                            <option value="">Select Format</option>
                            <option v-for="format in formatOptions" :key="format.name" :value="format.name">
                                {{ format.name }}
                            </option>
                        </select>
                        <input v-if="match.format == 'Custom'" type="number" v-model.number="match.startingLife"
                            placeholder="Starting Life Total" class="form-input" />

                        <div v-if="match.format == 'Custom'" class="custom-toggles">
                            <label><input type="checkbox" v-model="customOptions.hasPoison" /> Poison Counters</label>
                            <label><input type="checkbox" v-model="customOptions.hasTax" /> Commander Tax</label>
                            <label><input type="checkbox" v-model="customOptions.hasCommanderDamage" /> Commander Damage</label>
                        </div>

                        <label class="form-label">Number of Players:</label>
                        <select v-model="match.playerCount" class="form-input">
                            <option value="">Select Player Count</option>
                            <option v-for="count in [2, 3, 4, 5, 6]" :key="count" :value="count">
                                {{ count }} Players
                            </option>
                        </select>
                    </div>

                    <button type="submit" class="btn-primary" :disabled="loading">{{ loading ? 'Creating...' : 'Create Match' }}</button>
                    <p v-if="createError" class="error">{{ createError }}</p>
                </form>
            </div>
        </div>
    </div>
</template>

<script>
import { useRouter } from 'vue-router';
import Sidebar from '../shared/Sidebar.vue';
import formats from '../../utils/format.json';
import { matchService } from '../../services/match.service';

export default {
    components: { Sidebar },
    setup() {
        const router = useRouter();
        return { router };
    },
    data() {
        return {
            match: {
                name: '',
                format: '',
                startingLife: 20,
                playerCount: ''
            },
            formatOptions: formats.formats,
            createError: '',
            loading: false,
            customOptions: {
                hasPoison: false,
                hasTax: false,
                hasCommanderDamage: false
            },
        };
    },
    methods: {
        async createMatch() {
            if (!this.match.format) {
                this.createError = 'Please select a format.';
                return;
            }
            if (!this.match.playerCount) {
                this.createError = 'Please select the number of players.';
                return;
            }
            this.createError = '';
            this.loading = true;
            try {
                const matchRes = await matchService.createMatch({
                    name: this.match.name || undefined,
                    format: this.match.format,
                    startingLife: this.match.startingLife,
                    startTime: new Date().toTimeString().slice(0, 8),
                    isTeamMatch: false,
                });
                const matchId = matchRes?.data?.matchId;
                if (!matchId) throw new Error('Failed to create match');

                const isCustom = this.match.format === 'Custom';
                const selectedFormat = this.formatOptions.find(f => f.name === this.match.format);
                const hasPoison = isCustom ? this.customOptions.hasPoison : (selectedFormat?.has_poison ?? false);
                const hasTax = isCustom ? this.customOptions.hasTax : (selectedFormat?.has_tax ?? false);
                const hasCommanderDamage = isCustom ? this.customOptions.hasCommanderDamage : (selectedFormat?.has_commander_damage ?? false);

                localStorage.setItem(`match_pending_${matchId}`, JSON.stringify({
                    matchId,
                    matchName: this.match.name || '',
                    format: this.match.format,
                    startingLife: this.match.startingLife,
                    playerCount: this.match.playerCount,
                    inviteCode: matchRes?.data?.inviteCode ?? null,
                    hasPoison,
                    hasTax,
                    hasCommanderDamage,
                }));

                this.router.push(`/match/setup/${matchId}`);
            } catch (err) {
                this.createError = err?.response?.data?.message || err?.message || 'Failed to create match.';
            } finally {
                this.loading = false;
            }
        },
    },
    watch: {
        'match.format'(newFormat) {
            const selectedFormat = this.formatOptions.find(f => f.name === newFormat);
            if (selectedFormat && selectedFormat.starting_life !== null) {
                this.match.startingLife = selectedFormat.starting_life;
            }
        },
    }
};
</script>

<style scoped src="./match.css"></style>
