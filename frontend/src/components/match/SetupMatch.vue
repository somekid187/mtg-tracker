<template>
    <div class="page-layout">
        <Sidebar />
        <div class="setup-content">
            <template v-if="config">
                <!-- Header -->
                <div class="setup-header">
                    <div>
                        <h1 class="page-title">{{ config.matchName || 'Player Setup' }}</h1>
                        <p class="page-sub">Assign players to each slot, then start the match.</p>
                    </div>
                    <div class="header-chips">
                        <span class="chip">{{ config.format }}</span>
                        <span class="chip">♥ {{ config.startingLife }}</span>
                        <span class="chip">{{ config.playerCount }} Players</span>
                    </div>
                </div>

                <!-- Invite code banner -->
                <div class="invite-banner" v-if="config.inviteCode">
                    <div class="invite-inner">
                        <div>
                            <span class="invite-label">Invite Code</span>
                            <p class="invite-hint">Share this code with players so they can join via "Join Match"</p>
                        </div>
                        <div class="invite-code-row">
                            <span class="invite-code">{{ config.inviteCode }}</span>
                            <button class="btn-copy" @click="copyCode">{{ copied ? '✓ Copied' : 'Copy' }}</button>
                        </div>
                    </div>
                </div>

                <!-- Player slots -->
                <div class="slots-grid">
                    <div
                        v-for="(slot, i) in slots"
                        :key="i"
                        class="slot-card"
                        :class="{ 'is-joined': slot.joinedUsername, 'is-you': i === 0 }"
                    >
                        <!-- Slot header row -->
                        <div class="slot-head">
                            <span class="slot-num">Player {{ i + 1 }}</span>
                            <span v-if="i === 0" class="badge badge-you">You</span>
                            <span v-else-if="slot.joinedUsername" class="badge badge-joined">✓ Joined</span>
                            <span v-else-if="slot.isPending" class="badge badge-pending">⏳ Waiting</span>
                            <span v-else class="badge badge-open">Open</span>
                        </div>

                        <!-- You (slot 0) -->
                        <div v-if="i === 0" class="slot-you-info">
                            <div class="avatar">👤</div>
                            <span class="slot-name-txt">{{ slot.name }}</span>
                        </div>

                        <!-- Already joined via invite -->
                        <div v-else-if="slot.joinedUsername" class="slot-you-info">
                            <div class="avatar joined-avatar">✅</div>
                            <span class="slot-name-txt joined-txt">{{ slot.joinedUsername }}</span>
                        </div>

                        <!-- Configurable -->
                        <div v-else class="slot-configure">
                            <!-- Type tabs -->
                            <div class="type-tabs">
                                <button :class="['ttab', { active: slot.type === 'guest' }]" @click="slot.type = 'guest'">Guest</button>
                                <button :class="['ttab', { active: slot.type === 'friend' }]" @click="slot.type = 'friend'">Friend</button>
                                <button :class="['ttab', { active: slot.type === 'email' }]" @click="slot.type = 'email'">Email Invite</button>
                            </div>

                            <!-- Guest name input -->
                            <div v-if="slot.type === 'guest'" class="slot-form">
                                <input class="s-input" type="text" v-model="slot.guestName" placeholder="Guest name…" />
                            </div>

                            <!-- Friend picker -->
                            <div v-else-if="slot.type === 'friend'" class="slot-form">
                                <select class="s-input" v-model="slot.selectedFriendId">
                                    <option value="">Select a friend…</option>
                                    <option v-for="f in availableFriends(i)" :key="f.friendId" :value="f.friendId">
                                        {{ f.friendUsername }}
                                    </option>
                                </select>
                                <p v-if="!friends.length" class="no-friends-note">No friends added yet. Use Email invite instead.</p>
                                <div v-if="slot.selectedFriendId" class="code-share-box">
                                    <span class="code-share-label">Share this invite code with {{ friends.find(f => f.friendId == slot.selectedFriendId)?.friendUsername }}:</span>
                                    <div class="code-share-row">
                                        <code class="code-val">{{ config.inviteCode }}</code>
                                        <button class="btn-copy-sm" @click="copyCode">Copy</button>
                                    </div>
                                </div>
                            </div>

                            <!-- Email invite -->
                            <div v-else-if="slot.type === 'email'" class="slot-form">
                                <template v-if="!slot.inviteSent">
                                    <input class="s-input" type="email" v-model="slot.email" placeholder="player@email.com" />
                                    <button class="btn-send" @click="sendEmailInvite(i)" :disabled="slot.sending || !slot.email">
                                        {{ slot.sending ? 'Sending…' : 'Send Invite' }}
                                    </button>
                                </template>
                                <div v-else class="sent-row">
                                    <span class="sent-text">✉ Invite sent to {{ slot.email }}</span>
                                    <span class="sent-hint">Waiting for them to join…</span>
                                </div>
                            </div>

                            <p v-if="slot.error" class="slot-error">{{ slot.error }}</p>
                        </div>
                    </div>
                </div>

                <!-- Start button -->
                <div class="start-row">
                    <button class="btn-start" @click="startMatch" :disabled="loading">
                        {{ loading ? 'Starting…' : '▶ Start Match' }}
                    </button>
                    <p v-if="startError" class="start-error">{{ startError }}</p>
                </div>
            </template>

            <p v-else class="loading-txt">Loading match setup…</p>
        </div>
    </div>
</template>

<script>
import { useRouter, useRoute } from 'vue-router';
import Sidebar from '../shared/Sidebar.vue';
import { matchService } from '../../services/match.service';
import { playerService } from '../../services/player.service';
import { guestService } from '../../services/guest.service';
import { userService } from '../../services/user.service';
import authService from '../../services/auth.service';

export default {
    components: { Sidebar },
    setup() {
        const router = useRouter();
        const route = useRoute();
        return { router, route };
    },
    data() {
        return {
            config: null,
            slots: [],
            friends: [],
            loading: false,
            startError: '',
            copied: false,
            pollTimer: null,
        };
    },
    async created() {
        const matchId = this.$route.params.id;
        const raw = localStorage.getItem(`match_pending_${matchId}`);
        if (!raw) {
            this.router.push('/match');
            return;
        }
        this.config = JSON.parse(raw);
        const count = parseInt(this.config.playerCount);
        const username = authService.getUsername();

        this.slots = Array.from({ length: count }, (_, i) => {
            if (i === 0) return { type: 'you', name: username || 'You', joinedUsername: null };
            return {
                type: 'guest',
                guestName: '',
                selectedFriendId: '',
                email: '',
                inviteSent: false,
                joinedUsername: null,
                joinedPkPlayer: null,
                isPending: false,
                error: '',
                sending: false,
            };
        });

        userService.getFriends().then(res => {
            this.friends = res.data ?? [];
        }).catch(() => {});

        this.startPolling();
    },
    beforeUnmount() {
        this.stopPolling();
    },
    methods: {
        availableFriends(slotIndex) {
            const taken = this.slots
                .filter((s, i) => i !== slotIndex && s.selectedFriendId)
                .map(s => String(s.selectedFriendId));
            return this.friends.filter(f => !taken.includes(String(f.friendId)));
        },
        async copyCode() {
            try {
                await navigator.clipboard.writeText(this.config.inviteCode);
                this.copied = true;
                setTimeout(() => { this.copied = false; }, 2000);
            } catch {}
        },
        async sendEmailInvite(i) {
            const slot = this.slots[i];
            if (!slot.email?.trim()) return;
            slot.sending = true;
            slot.error = '';
            try {
                await matchService.sendInviteEmail({
                    email: slot.email.trim(),
                    matchId: this.config.matchId,
                    inviteCode: this.config.inviteCode,
                });
                slot.inviteSent = true;
                slot.isPending = true;
            } catch (err) {
                slot.error = err?.response?.data?.message || err?.message || 'Failed to send invite.';
            } finally {
                slot.sending = false;
            }
        },
        startPolling() {
            if (!this.config?.matchId) return;
            this.pollTimer = setInterval(async () => {
                try {
                    const res = await matchService.getPlayersByMatch(this.config.matchId);
                    const players = res?.data ?? [];
                    players.forEach(p => {
                        if (!p.userName) return;
                        const alreadyTracked = this.slots.some(s => s.joinedUsername === p.userName);
                        if (alreadyTracked) return;

                        // Try to match to a friend slot first
                        let idx = this.slots.findIndex(
                            (s, i) => i > 0 && !s.joinedUsername && s.type === 'friend' &&
                            this.friends.find(f => f.friendId == s.selectedFriendId)?.friendUsername === p.userName
                        );
                        // Fallback: first pending slot
                        if (idx === -1) {
                            idx = this.slots.findIndex((s, i) => i > 0 && s.isPending && !s.joinedUsername);
                        }
                        if (idx > -1) {
                            this.slots[idx].joinedUsername = p.userName;
                            this.slots[idx].joinedPkPlayer = p.pk_player;
                        }
                    });
                } catch {}
            }, 5000);
        },
        stopPolling() {
            if (this.pollTimer) {
                clearInterval(this.pollTimer);
                this.pollTimer = null;
            }
        },
        async startMatch() {
            const { matchId, startingLife, playerCount, hasPoison, hasTax, hasCommanderDamage } = this.config;
            const count = parseInt(playerCount);
            this.loading = true;
            this.startError = '';

            try {
                const userId = authService.getUserId();
                const players = [];

                for (let i = 0; i < count; i++) {
                    const slot = this.slots[i];
                    const cdInit = hasCommanderDamage
                        ? Object.fromEntries(
                            Array.from({ length: count }, (_, j) => j + 1)
                                .filter(id => id !== i + 1)
                                .map(id => [id, 0])
                        )
                        : null;

                    if (i === 0) {
                        const r = await playerService.createPlayer({
                            startingLife, placement: i + 1, minPlayers: count, maxPlayers: count,
                            fk_appUser_participates: userId,
                            fk_match_isPlayedIn: matchId,
                        });
                        players.push({
                            id: i + 1, pk_player: r?.data?.pk_player ?? null,
                            userId, guestId: null, name: slot.name,
                            startingLife, currentLife: startingLife, finalLife: null, isWinner: false,
                            tax: hasTax ? 0 : null, placement: null,
                            poisonCounter: hasPoison ? 0 : null, commanderDamage: cdInit,
                        });
                    } else if (slot.joinedPkPlayer) {
                        // Already joined via invite — reuse their player record
                        players.push({
                            id: i + 1, pk_player: slot.joinedPkPlayer,
                            userId: null, guestId: null, name: slot.joinedUsername,
                            startingLife, currentLife: startingLife, finalLife: null, isWinner: false,
                            tax: hasTax ? 0 : null, placement: null,
                            poisonCounter: hasPoison ? 0 : null, commanderDamage: cdInit,
                        });
                    } else {
                        const name =
                            slot.type === 'guest'  ? (slot.guestName?.trim() || `Player ${i + 1}`) :
                            slot.type === 'friend' ? (this.friends.find(f => f.friendId == slot.selectedFriendId)?.friendUsername || `Player ${i + 1}`) :
                            slot.type === 'email'  ? (slot.email?.split('@')[0] || `Player ${i + 1}`) :
                            `Player ${i + 1}`;

                        const gr = await guestService.createGuest({ guestName: name });
                        const guestId = gr?.data?.pk_guest;
                        if (!guestId) throw new Error(`Failed to create guest for player ${i + 1}`);

                        const pr = await playerService.createPlayer({
                            startingLife, placement: i + 1, minPlayers: count, maxPlayers: count,
                            fk_guest_enters: guestId,
                            fk_match_isPlayedIn: matchId,
                        });
                        players.push({
                            id: i + 1, pk_player: pr?.data?.pk_player ?? null,
                            userId: null, guestId, name,
                            startingLife, currentLife: startingLife, finalLife: null, isWinner: false,
                            tax: hasTax ? 0 : null, placement: null,
                            poisonCounter: hasPoison ? 0 : null, commanderDamage: cdInit,
                        });
                    }
                }

                const matchData = {
                    pk_match: matchId,
                    name: this.config.matchName,
                    format: this.config.format,
                    startingLife,
                    playerCount: count,
                    hasPoison, hasTax, hasCommanderDamage,
                    players,
                };
                localStorage.setItem(`match_${matchId}`, JSON.stringify(matchData));
                localStorage.removeItem(`match_pending_${matchId}`);
                this.stopPolling();
                this.router.push(`/match/${matchId}`);
            } catch (err) {
                this.startError = err?.response?.data?.message || err?.message || 'Failed to start match.';
            } finally {
                this.loading = false;
            }
        },
    },
};
</script>

<style scoped>
.page-layout { width: 100%; height: 100%; display: flex; }

.setup-content {
    flex: 1;
    padding: 2em 3em;
    background-color: #292b2d;
    font-family: 'Poppins', sans-serif;
    color: #fefefe;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 1.5em;
}

.setup-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 1em;
}

.page-title { margin: 0; font-size: 2rem; font-weight: 700; }
.page-sub { margin: 0.25em 0 0; color: #a0a3a8; font-size: 0.9rem; }

.header-chips { display: flex; gap: 0.5em; flex-wrap: wrap; align-items: center; }
.chip {
    background-color: #414247;
    border-radius: 20px;
    padding: 0.3em 1em;
    font-size: 0.85rem;
    font-weight: 600;
}

/* Invite banner */
.invite-banner {
    background-color: #313338;
    border-radius: 16px;
    padding: 1.25em 1.75em;
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}
.invite-inner { display: flex; align-items: center; justify-content: space-between; gap: 1.5em; flex-wrap: wrap; }
.invite-label { font-size: 0.75rem; font-weight: 700; color: #888; text-transform: uppercase; letter-spacing: 0.06em; }
.invite-hint { margin: 0.2em 0 0; font-size: 0.8rem; color: #666; }
.invite-code-row { display: flex; align-items: center; gap: 0.75em; }
.invite-code { font-size: 1.8rem; font-weight: 800; letter-spacing: 0.18em; color: #ffd170; }
.btn-copy {
    background-color: #ffd170;
    color: #292b2d;
    border: none;
    border-radius: 8px;
    padding: 0.4em 1em;
    font-size: 0.85rem;
    font-weight: 700;
    cursor: pointer;
    transition: background-color 0.2s;
    white-space: nowrap;
}
.btn-copy:hover { background-color: #ffc107; }

/* Slots grid */
.slots-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1em;
}

.slot-card {
    background-color: #313338;
    border-radius: 16px;
    padding: 1.25em 1.5em;
    display: flex;
    flex-direction: column;
    gap: 0.9em;
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    border: 2px solid transparent;
    transition: border-color 0.2s;
}
.slot-card.is-joined { border-color: #6bffb8; }
.slot-card.is-you { border-color: #ffd170; }

.slot-head { display: flex; align-items: center; justify-content: space-between; }
.slot-num { font-size: 0.75rem; font-weight: 700; color: #888; text-transform: uppercase; letter-spacing: 0.06em; }

.badge {
    font-size: 0.72rem;
    font-weight: 700;
    padding: 0.2em 0.7em;
    border-radius: 20px;
}
.badge-you     { background: #3d3620; color: #ffd170; }
.badge-joined  { background: #1e3d2f; color: #6bffb8; }
.badge-pending { background: #3d3015; color: #ffc107; }
.badge-open    { background: #2a2d31; color: #888; }

.slot-you-info { display: flex; align-items: center; gap: 0.75em; }
.avatar { font-size: 1.5rem; }
.slot-name-txt { font-weight: 600; font-size: 1rem; }
.joined-txt { color: #6bffb8; }

/* Configure area */
.slot-configure { display: flex; flex-direction: column; gap: 0.7em; }
.type-tabs {
    display: flex;
    gap: 2px;
    background: #252729;
    border-radius: 8px;
    padding: 3px;
}
.ttab {
    flex: 1;
    border: none;
    background: transparent;
    color: #888;
    padding: 0.35em 0.5em;
    border-radius: 6px;
    font-size: 0.78rem;
    font-weight: 600;
    cursor: pointer;
    font-family: 'Poppins', sans-serif;
    transition: all 0.15s;
}
.ttab.active { background: #414247; color: #fefefe; }

.slot-form { display: flex; flex-direction: column; gap: 0.5em; }
.s-input {
    background-color: #252729;
    border: 1px solid #4a4a4a;
    border-radius: 8px;
    padding: 0.6em 0.875em;
    color: #fefefe;
    font-family: 'Poppins', sans-serif;
    font-size: 0.9rem;
    outline: none;
    width: 100%;
    box-sizing: border-box;
    transition: border-color 0.2s;
}
.s-input:focus { border-color: #ffd170; }

.code-share-box {
    background: #252729;
    border-radius: 8px;
    padding: 0.75em;
}
.code-share-label { font-size: 0.78rem; color: #888; display: block; margin-bottom: 0.4em; }
.code-share-row { display: flex; align-items: center; gap: 0.5em; }
.code-val { font-size: 1.1rem; font-weight: 800; letter-spacing: 0.12em; color: #ffd170; flex: 1; font-style: normal; }
.btn-copy-sm {
    background-color: #ffd170;
    color: #292b2d;
    border: none;
    border-radius: 6px;
    padding: 0.25em 0.75em;
    font-size: 0.75rem;
    font-weight: 700;
    cursor: pointer;
}

.no-friends-note { margin: 0; font-size: 0.8rem; color: #888; font-style: italic; }

.btn-send {
    background-color: #ffd170;
    color: #292b2d;
    border: none;
    border-radius: 8px;
    padding: 0.5em 1.25em;
    font-size: 0.85rem;
    font-weight: 700;
    font-family: 'Poppins', sans-serif;
    cursor: pointer;
    align-self: flex-start;
    transition: background-color 0.2s;
}
.btn-send:hover { background-color: #ffc107; }
.btn-send:disabled { background-color: #555; color: #888; cursor: not-allowed; }

.sent-row { display: flex; flex-direction: column; gap: 0.2em; }
.sent-text { color: #6bffb8; font-size: 0.85rem; font-weight: 600; }
.sent-hint { color: #888; font-size: 0.78rem; }

.slot-error { color: #ff6b6b; font-size: 0.8rem; margin: 0; }

/* Start row */
.start-row { display: flex; align-items: center; gap: 1em; flex-wrap: wrap; }
.btn-start {
    background-color: #ffd170;
    color: #292b2d;
    border: none;
    border-radius: 12px;
    padding: 0.875em 2.5em;
    font-size: 1.1em;
    font-weight: 700;
    font-family: 'Poppins', sans-serif;
    cursor: pointer;
    transition: background-color 0.2s;
}
.btn-start:hover { background-color: #ffc107; }
.btn-start:disabled { background-color: #555; color: #888; cursor: not-allowed; }
.start-error { color: #ff6b6b; margin: 0; font-size: 0.9rem; }
.loading-txt { color: #888; font-size: 1rem; }
</style>
