<template>
    <div class="page-layout">
        <Sidebar />
        <div class="join-content">
            <div class="join-card">
                <div class="join-icon">🎴</div>
                <h2 class="join-title">Join Match</h2>
                <p class="join-sub">Enter the invite code shared with you to join a match in progress.</p>

                <form @submit.prevent="joinMatch" class="join-form">
                    <div class="join-field">
                        <label class="join-label">Invite Code</label>
                        <input
                            class="join-input"
                            type="text"
                            v-model="inviteCode"
                            placeholder="A1B2C3D4"
                            :disabled="loading"
                            maxlength="8"
                            autocomplete="off"
                            spellcheck="false"
                        />
                    </div>

                    <button class="btn-join" type="submit" :disabled="loading || !inviteCode.trim()">
                        {{ loading ? 'Joining…' : 'Join Match' }}
                    </button>
                    <p v-if="error" class="join-error">{{ error }}</p>
                </form>
            </div>
        </div>
    </div>
</template>

<script>
import { useRouter, useRoute } from 'vue-router';
import Sidebar from '../shared/Sidebar.vue';
import { matchService } from '../../services/match.service';
import formats from '../../utils/format.json';

export default {
    components: { Sidebar },
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
        const code = this.$route.query.code;
        if (code) this.inviteCode = String(code).toUpperCase();
        // Auto-submit if code pre-filled from email link
        if (this.inviteCode) this.joinMatch();
    },
    methods: {
        async joinMatch() {
            this.loading = true;
            this.error = '';

            try {
                const res = await matchService.joinMatch({ inviteCode: this.inviteCode.trim().toUpperCase() });
                const matchId = res?.data?.matchId;
                if (!matchId) throw new Error('Invalid response from server');

                const matchRes = await matchService.getMatchById(matchId);
                const matchInfo = matchRes?.data ?? matchRes;

                const formatOptions = formats.formats;
                const selectedFormat = formatOptions.find(f => f.name === matchInfo.format);
                const hasPoison = selectedFormat?.has_poison ?? false;
                const hasTax = selectedFormat?.has_tax ?? false;
                const hasCommanderDamage = selectedFormat?.has_commander_damage ?? false;

                const players = (matchInfo.players ?? []).map((p, index) => ({
                    id: index + 1,
                    pk_player: p.pk_player ?? null,
                    userId: p.fk_appUser_participates ?? null,
                    guestId: p.fk_guest_enters ?? null,
                    name: p.userName ?? p.guestName ?? `Player ${index + 1}`,
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
.page-layout {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: row;
}

.join-content {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #292b2d;
    padding: 2em;
    font-family: 'Poppins', sans-serif;
}

.join-card {
    background-color: #313338;
    border-radius: 20px;
    padding: 2.5em 3em;
    width: 100%;
    max-width: 440px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
    display: flex;
    flex-direction: column;
    gap: 1em;
    align-items: center;
    text-align: center;
}

.join-icon {
    font-size: 2.5rem;
}

.join-title {
    margin: 0;
    font-size: 1.8rem;
    font-weight: 700;
    color: #ffd170;
}

.join-sub {
    margin: 0;
    color: #a0a3a8;
    font-size: 0.9rem;
    line-height: 1.5;
}

.join-form {
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 1em;
    margin-top: 0.5em;
}

.join-field {
    display: flex;
    flex-direction: column;
    gap: 0.4em;
    text-align: left;
}

.join-label {
    font-size: 0.85rem;
    font-weight: 600;
    color: #fefefe;
}

.join-input {
    background-color: #252729;
    border: 1px solid #4a4a4a;
    border-radius: 10px;
    padding: 0.75em 1em;
    color: #ffd170;
    font-family: 'Poppins', monospace;
    font-size: 1.4rem;
    font-weight: 800;
    letter-spacing: 0.2em;
    text-align: center;
    text-transform: uppercase;
    outline: none;
    transition: border-color 0.2s ease;
    width: 100%;
    box-sizing: border-box;
}

.join-input:focus {
    border-color: #ffd170;
}

.btn-join {
    background-color: #ffd170;
    border: none;
    border-radius: 12px;
    padding: 0.875em;
    color: #292b2d;
    font-family: 'Poppins', sans-serif;
    font-size: 1em;
    font-weight: 700;
    cursor: pointer;
    transition: background-color 0.2s ease;
    width: 100%;
}

.btn-join:hover {
    background-color: #ffc107;
}

.btn-join:disabled {
    background-color: #4a4a4a;
    color: #888;
    cursor: not-allowed;
}

.join-error {
    color: #ff6b6b;
    font-size: 0.875rem;
    margin: 0;
    text-align: center;
}
</style>
