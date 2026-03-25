<template>
    <div class="page-layout">
        <Sidebar />
        <div class="match-content">
            <div class="match-container">
                <!-- Initial Match Setup Form -->
                <form v-if="!matchCreated" @submit.prevent="createMatch" class="box form-section">
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

                <!-- Player Names Form -->
                <form v-if="matchCreated" @submit.prevent="startMatch" class="box form-section">
                    <h2>Enter Player Names</h2>
                    <div class="players-list">
                        <div v-for="(name, index) in playerNames" :key="index" class="player-input">
                            <label>Player {{ index + 1 }}{{ index === 0 ? ' (You)' : '' }}:</label>
                            <div class="player-row">
                                <input
                                    type="text"
                                    v-model="playerNames[index]"
                                    :placeholder="index === 0 ? (playerNames[0] || 'You') : `Player ${index + 1} name`"
                                    :readonly="index === 0 || !!inviteSlots[index]?.joinedUsername"
                                    :class="{ 'input-joined': !!inviteSlots[index]?.joinedUsername }"
                                    class="form-input"
                                />
                                <template v-if="index > 0">
                                    <template v-if="inviteSlots[index]?.joinedUsername">
                                        <span class="badge-joined">✓ {{ inviteSlots[index].joinedUsername }}</span>
                                    </template>
                                    <template v-else-if="inviteSlots[index]?.sent">
                                        <span class="badge-sent">Invite sent</span>
                                    </template>
                                    <template v-else-if="inviteSlots[index]?.showForm">
                                        <input
                                            type="email"
                                            v-model="inviteSlots[index].email"
                                            placeholder="Email address"
                                            class="invite-email-input form-input"
                                        />
                                        <button type="button" class="btn-invite-send" @click="sendInvite(index)" :disabled="inviteSlots[index].sending">
                                            {{ inviteSlots[index].sending ? '...' : 'Send' }}
                                        </button>
                                        <button type="button" class="btn-invite-cancel" @click="inviteSlots[index].showForm = false">✕</button>
                                        <span v-if="inviteSlots[index].error" class="invite-error">{{ inviteSlots[index].error }}</span>
                                    </template>
                                    <template v-else>
                                        <button type="button" class="btn-invite" @click="inviteSlots[index].showForm = true">Invite</button>
                                    </template>
                                </template>
                            </div>
                        </div>
                    </div>

                    <button type="submit" class="btn-primary" :disabled="loading">{{ loading ? 'Starting...' : 'Start Match' }}</button>
                    <p v-if="startError" class="error">{{ startError }}</p>
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
import { playerService } from '../../services/player.service';
import { guestService } from '../../services/guest.service';
import authService from '../../services/auth.service';

export default {
    components: { Sidebar },
    setup() {
        const router = useRouter();
        return { router };
    },
    beforeUnmount() {
        this.stopPolling();
    },
    data() {
        return {
            match: {
                name: '',
                format: '',
                startingLife: 20,
                playerCount: ''
            },
            playerNames: [],
            formatOptions: formats.formats,
            matchCreated: false,
            createError: '',
            startError: '',
            loading: false,
            customOptions: {
                hasPoison: false,
                hasTax: false,
                hasCommanderDamage: false
            },
            // Per-slot invite state (index 0 unused — that's the host)
            inviteSlots: [],
            // Stored after match+players are created, used for polling
            createdMatchId: null,
            createdInviteCode: null,
            pollTimer: null,
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
                const startTime = new Date().toTimeString().slice(0, 8);
                const matchRes = await matchService.createMatch({
                    name: this.match.name || undefined,
                    format: this.match.format,
                    startingLife: this.match.startingLife,
                    startTime,
                    isTeamMatch: false,
                });
                const matchId = matchRes?.data?.matchId;
                if (!matchId) throw new Error('Failed to create match');
                this.createdMatchId = matchId;
                this.createdInviteCode = matchRes?.data?.inviteCode ?? null;
                // Pre-fill player 1 with the logged-in user's username
                const username = authService.getUsername();
                this.playerNames[0] = username || 'Player 1';
                this.matchCreated = true;
                this.startPolling();
            } catch (err) {
                this.createError = err?.response?.data?.message || err?.message || 'Failed to create match.';
            } finally {
                this.loading = false;
            }
        },
        async sendInvite(index) {
            const slot = this.inviteSlots[index];
            if (!slot || !slot.email?.trim()) return;
            slot.sending = true;
            slot.error = '';
            try {
                await matchService.sendInviteEmail({
                    email: slot.email.trim(),
                    matchId: this.createdMatchId,
                    inviteCode: this.createdInviteCode,
                });
                slot.sent = true;
                slot.showForm = false;
            } catch (err) {
                slot.error = err?.response?.data?.message || err?.message || 'Failed to send invite.';
            } finally {
                slot.sending = false;
            }
        },
        startPolling() {
            if (!this.createdMatchId) return;
            this.pollTimer = setInterval(async () => {
                try {
                    const res = await matchService.getPlayersByMatch(this.createdMatchId);
                    const players = res?.data ?? [];
                    players.forEach((p) => {
                        if (p.userName) {
                            // Find which invite slot this user filled
                            // Slots 1..n correspond to guests; match by fk_appUser_participates presence
                            const slotIdx = this.inviteSlots.findIndex(
                                (s, i) => i > 0 && s?.sent && !s?.joinedUsername
                            );
                            if (slotIdx > -1) {
                                this.inviteSlots[slotIdx].joinedUsername = p.userName;
                                this.playerNames[slotIdx] = p.userName;
                            }
                        }
                    });
                } catch {
                    // silently ignore poll errors
                }
            }, 5000);
        },
        stopPolling() {
            if (this.pollTimer) {
                clearInterval(this.pollTimer);
                this.pollTimer = null;
            }
        },
        async startMatch() {
            const selectedFormat = this.formatOptions.find(f => f.name === this.match.format);
            const isCustom = this.match.format === 'Custom';
            const hasPoison = isCustom ? this.customOptions.hasPoison : (selectedFormat?.has_poison ?? false);
            const hasTax = isCustom ? this.customOptions.hasTax : (selectedFormat?.has_tax ?? false);
            const hasCommanderDamage = isCustom ? this.customOptions.hasCommanderDamage : (selectedFormat?.has_commander_damage ?? false);
            const count = parseInt(this.match.playerCount);

            this.loading = true;
            this.startError = '';

            try {
                const matchId = this.createdMatchId;
                if (!matchId) throw new Error('Match has not been created yet');

                // Create player records — player 1 is the logged-in user, rest are guests
                const userId = authService.getUserId();
                const players = [];
                for (let index = 0; index < count; index++) {
                    const name = this.playerNames[index]?.trim() || `Player ${index + 1}`;

                    if (index === 0) {
                        // Creator: link to real user account
                        if (!userId) throw new Error('Could not determine logged-in user ID');
                        const playerRes = await playerService.createPlayer({
                            startingLife: this.match.startingLife,
                            placement: index + 1,
                            minPlayers: count,
                            maxPlayers: count,
                            fk_appUser_participates: userId,
                            fk_match_isPlayedIn: matchId,
                        });
                        players.push({
                            id: index + 1,
                            pk_player: playerRes?.data?.pk_player ?? null,
                            userId,
                            guestId: null,
                            name,
                            startingLife: this.match.startingLife,
                            currentLife: this.match.startingLife,
                            finalLife: null,
                            isWinner: false,
                            tax: hasTax ? 0 : null,
                            placement: null,
                            poisonCounter: hasPoison ? 0 : null,
                            commanderDamage: hasCommanderDamage
                                ? Object.fromEntries(
                                    Array.from({ length: count }, (_, j) => j + 1)
                                        .filter(id => id !== index + 1)
                                        .map(id => [id, 0])
                                )
                                : null,
                        });
                    } else {
                        // Other players: create as guests
                        const guestRes = await guestService.createGuest({ guestName: name });
                        const guestId = guestRes?.data?.pk_guest;
                        if (!guestId) throw new Error(`Failed to create guest for player ${index + 1}`);
                        const playerRes2 = await playerService.createPlayer({
                            startingLife: this.match.startingLife,
                            placement: index + 1,
                            minPlayers: count,
                            maxPlayers: count,
                            fk_guest_enters: guestId,
                            fk_match_isPlayedIn: matchId,
                        });
                        players.push({
                            id: index + 1,
                            pk_player: playerRes2?.data?.pk_player ?? null,
                            userId: null,
                            guestId,
                            name,
                            startingLife: this.match.startingLife,
                            currentLife: this.match.startingLife,
                            finalLife: null,
                            isWinner: false,
                            tax: hasTax ? 0 : null,
                            placement: null,
                            poisonCounter: hasPoison ? 0 : null,
                            commanderDamage: hasCommanderDamage
                                ? Object.fromEntries(
                                    Array.from({ length: count }, (_, j) => j + 1)
                                        .filter(id => id !== index + 1)
                                        .map(id => [id, 0])
                                )
                                : null,
                        });
                    }
                }

                // 3. Store in localStorage and navigate
                const matchData = {
                    ...this.match,
                    pk_match: matchId,
                    hasCommanderDamage,
                    hasPoison,
                    hasTax,
                    players,
                };
                localStorage.setItem(`match_${matchId}`, JSON.stringify(matchData));
                this.stopPolling();
                this.router.push({ path: `/match/${matchId}` });
            } catch (err) {
                this.startError = err?.response?.data?.message || err?.message || 'Failed to start match.';
            } finally {
                this.loading = false;
            }
        }
    },
    watch: {
        'match.format'(newFormat) {
            const selectedFormat = this.formatOptions.find(f => f.name === newFormat);
            if (selectedFormat && selectedFormat.starting_life !== null) {
                this.match.startingLife = selectedFormat.starting_life;
            }
        },
        'match.playerCount'(newCount) {
            const count = parseInt(newCount);
            if (count) {
                const username = authService.getUsername();
                this.playerNames = Array(count).fill('').map((_, i) =>
                    i === 0 ? (username || 'Player 1') : ''
                );
                // Reset invite slots
                this.inviteSlots = Array(count).fill(null).map((_, i) =>
                    i === 0 ? null : { showForm: false, email: '', sending: false, sent: false, error: '', joinedUsername: null }
                );
            } else {
                this.playerNames = [];
                this.inviteSlots = [];
            }
        }
    }
};
</script>

<style scoped src="./match.css"></style>