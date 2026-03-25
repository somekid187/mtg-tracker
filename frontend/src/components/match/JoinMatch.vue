<template>
    <div>
        <h2>Join Match</h2>

        <form @submit.prevent="joinMatch">
            <label>Invite Code</label>
            <input
                type="text"
                v-model="inviteCode"
                placeholder="Enter invite code (e.g. A1B2C3D4)"
                :disabled="loading"
                maxlength="8"
            />

            <button type="submit" :disabled="loading || !inviteCode.trim()">
                {{ loading ? 'Joining...' : 'Join Match' }}
            </button>
            <p v-if="error" class="error">{{ error }}</p>
        </form>
    </div>
</template>

<script>
import { useRouter, useRoute } from 'vue-router';
import { matchService } from '../../services/match.service';
import formats from '../../utils/format.json';

export default {
    setup() {
        const router = useRouter();
        const route = useRoute();
        return { router, route };
    },
    data() {
        return {
            inviteCode: '',
            loading: false,
            error: '',
        };
    },
    created() {
        // Pre-fill from email link: /match/join?code=XXXXXXXX
        const code = this.$route.query.code;
        if (code) this.inviteCode = String(code).toUpperCase();
    },
    methods: {
        async joinMatch() {
            this.loading = true;
            this.error = '';

            try {
                // Join the match via invite code — backend creates the Player record
                const res = await matchService.joinMatch({ inviteCode: this.inviteCode.trim().toUpperCase() });
                const matchId = res?.data?.pk_match;
                if (!matchId) throw new Error('Invalid response from server');

                // Fetch full match details to build localStorage entry
                const matchRes = await matchService.getMatchById(matchId);
                const matchInfo = matchRes?.data ?? matchRes;

                const formatOptions = formats.formats;
                const selectedFormat = formatOptions.find(f => f.name === matchInfo.format);
                const hasPoison = selectedFormat?.has_poison ?? false;
                const hasTax = selectedFormat?.has_tax ?? false;
                const hasCommanderDamage = selectedFormat?.has_commander_damage ?? false;

                const players = (matchInfo.players ?? []).map((p, index) => ({
                    id: index + 1,
                    name: p.username ?? p.guestName ?? `Player ${index + 1}`,
                    startingLife: matchInfo.startingLife,
                    currentLife: matchInfo.startingLife,
                    finalLife: null,
                    isWinner: false,
                    tax: hasTax ? 0 : null,
                    placement: null,
                    poisonCounter: hasPoison ? 0 : null,
                    commanderDamage: hasCommanderDamage
                        ? Object.fromEntries(
                            (matchInfo.players ?? [])
                                .map((_, j) => j + 1)
                                .filter(id => id !== index + 1)
                                .map(id => [id, 0])
                        )
                        : null,
                }));

                const matchData = {
                    pk_match: matchId,
                    name: matchInfo.name,
                    format: matchInfo.format,
                    startingLife: matchInfo.startingLife,
                    playerCount: players.length,
                    hasCommanderDamage,
                    hasPoison,
                    hasTax,
                    players,
                };

                localStorage.setItem(`match_${matchId}`, JSON.stringify(matchData));
                this.router.push({ path: `/match/${matchId}` });
            } catch (err) {
                this.error = err?.response?.data?.message || err?.message || 'Failed to join match.';
            } finally {
                this.loading = false;
            }
        },
    },
};
</script>

<style scoped>
.error {
    color: red;
    margin-top: 8px;
}
</style>
