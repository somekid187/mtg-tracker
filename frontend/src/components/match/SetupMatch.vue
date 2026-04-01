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

                <!-- Seating layout -->
                <div class="seating-panel">
                    <div class="seating-panel-head">
                        <p class="seating-label">Seating Arrangement — drag seats to rearrange</p>
                        <div class="layout-toggle">
                            <button :class="['ltab', { active: layoutMode === 'linear' }]" @click="layoutMode = 'linear'" title="Linear layout">
                                <span class="ltab-icon">&#9135;&#9135;</span>
                            </button>
                            <button :class="['ltab', { active: layoutMode === 'rect' }]" @click="layoutMode = 'rect'" title="Rectangular layout">
                                <span class="ltab-icon">&#9645;</span>
                            </button>
                        </div>
                    </div>

                    <!-- Linear layout -->
                    <div v-if="layoutMode === 'linear'" class="seating-table">
                        <div v-for="(row, rowIdx) in slotRows" :key="rowIdx" class="seating-row">
                            <div
                                v-for="{ slot, index } in row.seats"
                                :key="index"
                                class="seat"
                                :class="{
                                    'seat-you': slot.type === 'you',
                                    'seat-joined': slot.joinedUsername,
                                    'seat-dragging': draggingFrom === index,
                                    'seat-dragover': dragoverIndex === index && draggingFrom !== index,
                                }"
                                draggable="true"
                                @dragstart="startDrag(index)"
                                @dragover.prevent="onDragOver(index)"
                                @drop.prevent="onDrop(index)"
                                @dragend="onDragEnd"
                            >
                                <span class="seat-num">Seat {{ index + 1 }}</span>
                                <span class="seat-name">{{ getSlotDisplayName(slot) }}</span>
                            </div>
                        </div>
                        <div class="table-divider"><span>TABLE</span></div>
                    </div>

                    <!-- Rectangular layout -->
                    <div v-else class="rect-table-wrap">
                        <div class="rect-table">
                            <!-- Top edge -->
                            <div class="rect-edge rect-top">
                                <div
                                    v-for="{ slot, index, rotation } in rectLayout.top"
                                    :key="index"
                                    class="seat"
                                    :class="{
                                        'seat-you': slot.type === 'you',
                                        'seat-joined': slot.joinedUsername,
                                        'seat-dragging': draggingFrom === index,
                                        'seat-dragover': dragoverIndex === index && draggingFrom !== index,
                                    }"
                                    :style="{ transform: `rotate(${rotation}deg)` }"
                                    draggable="true"
                                    @dragstart="startDrag(index)"
                                    @dragover.prevent="onDragOver(index)"
                                    @drop.prevent="onDrop(index)"
                                    @dragend="onDragEnd"
                                >
                                    <span class="seat-num">{{ index + 1 }}</span>
                                    <span class="seat-name">{{ getSlotDisplayName(slot) }}</span>
                                </div>
                            </div>

                            <!-- Middle row: left + table surface + right -->
                            <div class="rect-middle">
                                <div class="rect-edge rect-left">
                                    <div
                                        v-for="{ slot, index, rotation } in rectLayout.left"
                                        :key="index"
                                        class="seat"
                                        :class="{
                                            'seat-you': slot.type === 'you',
                                            'seat-joined': slot.joinedUsername,
                                            'seat-dragging': draggingFrom === index,
                                            'seat-dragover': dragoverIndex === index && draggingFrom !== index,
                                        }"
                                        :style="{ transform: `rotate(${rotation}deg)` }"
                                        draggable="true"
                                        @dragstart="startDrag(index)"
                                        @dragover.prevent="onDragOver(index)"
                                        @drop.prevent="onDrop(index)"
                                        @dragend="onDragEnd"
                                    >
                                        <span class="seat-num">{{ index + 1 }}</span>
                                        <span class="seat-name">{{ getSlotDisplayName(slot) }}</span>
                                    </div>
                                </div>

                                <div class="rect-surface"><span>TABLE</span></div>

                                <div class="rect-edge rect-right">
                                    <div
                                        v-for="{ slot, index, rotation } in rectLayout.right"
                                        :key="index"
                                        class="seat"
                                        :class="{
                                            'seat-you': slot.type === 'you',
                                            'seat-joined': slot.joinedUsername,
                                            'seat-dragging': draggingFrom === index,
                                            'seat-dragover': dragoverIndex === index && draggingFrom !== index,
                                        }"
                                        :style="{ transform: `rotate(${rotation}deg)` }"
                                        draggable="true"
                                        @dragstart="startDrag(index)"
                                        @dragover.prevent="onDragOver(index)"
                                        @drop.prevent="onDrop(index)"
                                        @dragend="onDragEnd"
                                    >
                                        <span class="seat-num">{{ index + 1 }}</span>
                                        <span class="seat-name">{{ getSlotDisplayName(slot) }}</span>
                                    </div>
                                </div>
                            </div>

                            <!-- Bottom edge -->
                            <div class="rect-edge rect-bottom">
                                <div
                                    v-for="{ slot, index, rotation } in rectLayout.bottom"
                                    :key="index"
                                    class="seat"
                                    :class="{
                                        'seat-you': slot.type === 'you',
                                        'seat-joined': slot.joinedUsername,
                                        'seat-dragging': draggingFrom === index,
                                        'seat-dragover': dragoverIndex === index && draggingFrom !== index,
                                    }"
                                    :style="{ transform: `rotate(${rotation}deg)` }"
                                    draggable="true"
                                    @dragstart="startDrag(index)"
                                    @dragover.prevent="onDragOver(index)"
                                    @drop.prevent="onDrop(index)"
                                    @dragend="onDragEnd"
                                >
                                    <span class="seat-num">{{ index + 1 }}</span>
                                    <span class="seat-name">{{ getSlotDisplayName(slot) }}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Player slots -->
                <div class="slots-grid">
                    <div
                        v-for="(slot, i) in slots"
                        :key="i"
                        class="slot-card"
                        :class="{ 'is-joined': slot.joinedUsername, 'is-you': slot.type === 'you' }"
                    >
                        <!-- Slot header row -->
                        <div class="slot-head">
                            <span class="slot-num">Player {{ i + 1 }}</span>
                            <span v-if="slot.type === 'you'" class="badge badge-you">You</span>
                            <span v-else-if="slot.joinedUsername" class="badge badge-joined">✓ Joined</span>
                            <span v-else-if="slot.inviteStatus === 'accepted'" class="badge badge-joined">✓ Accepted</span>
                            <span v-else-if="slot.inviteStatus === 'pending'" class="badge badge-pending">⏳ Pending</span>
                            <span v-else-if="slot.isPending" class="badge badge-pending">⏳ Waiting</span>
                            <span v-else class="badge badge-open">Open</span>
                        </div>

                        <!-- You -->
                        <div v-if="slot.type === 'you'" class="slot-you-info">
                            <div class="avatar">👤</div>
                            <span class="slot-name-txt">{{ slot.name }}</span>
                            <select v-model="slot.deckId" class="s-input deck-select">
                                <option :value="null">No deck</option>
                                <option v-for="d in decks" :key="d.pk_deck" :value="d.pk_deck">{{ d.name }}</option>
                            </select>
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
                                <select class="s-input" v-model="slot.selectedFriendId" :disabled="slot.inviteStatus !== 'none'">
                                    <option value="">Select a friend…</option>
                                    <option v-for="f in availableFriends(i)" :key="f.friendId" :value="f.friendId">
                                        {{ f.friendUsername }}
                                    </option>
                                </select>
                                <p v-if="!friends.length" class="no-friends-note">No friends added yet. Use Email invite instead.</p>
                                <template v-if="slot.selectedFriendId">
                                    <div v-if="slot.inviteStatus === 'none'" class="invite-action-row">
                                        <button class="btn-send" @click="sendFriendInvite(i)" :disabled="slot.sendingInvite">
                                            {{ slot.sendingInvite ? 'Sending…' : '✉ Send Invite' }}
                                        </button>
                                    </div>
                                    <div v-else-if="slot.inviteStatus === 'pending'" class="sent-row">
                                        <span class="sent-text">⏳ Invite sent — waiting for response…</span>
                                    </div>
                                    <div v-else-if="slot.inviteStatus === 'accepted'" class="sent-row">
                                        <span class="sent-text accepted-text">✅ Invite accepted — ready!</span>
                                    </div>
                                </template>
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
                    <button class="btn-start" @click="startMatch" :disabled="loading || !canStart">
                        {{ loading ? 'Starting…' : '▶ Start Match' }}
                    </button>
                    <p v-if="startError" class="start-error">{{ startError }}</p>
                    <p v-if="!canStart && !loading" class="start-hint">All friend invites must be accepted before starting.</p>
                </div>
            </template>

            <p v-else class="loading-txt">Loading match setup…</p>
        </div>
    </div>
</template>

<script lang="ts" src="./setupMatch"></script>

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

/* Seating layout */
.seating-panel {
    background-color: #313338;
    border-radius: 16px;
    padding: 1.25em 1.75em;
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.seating-panel-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 1em;
}

.seating-label {
    margin: 0;
    font-size: 0.75rem;
    font-weight: 700;
    color: #888;
    text-transform: uppercase;
    letter-spacing: 0.06em;
}

/* Layout toggle buttons */
.layout-toggle {
    display: flex;
    gap: 2px;
    background: #252729;
    border-radius: 8px;
    padding: 3px;
}
.ltab {
    border: none;
    background: transparent;
    color: #888;
    padding: 0.3em 0.65em;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1rem;
    line-height: 1;
    transition: all 0.15s;
}
.ltab.active { background: #414247; color: #ffd170; }
.ltab-icon { pointer-events: none; }

.seating-table {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0;
}

.seating-row {
    display: flex;
    gap: 0.75em;
    justify-content: center;
    padding: 0.75em 0;
}

.table-divider {
    width: 100%;
    display: flex;
    align-items: center;
    gap: 1em;
    color: #444;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.12em;
}
.table-divider::before,
.table-divider::after {
    content: '';
    flex: 1;
    height: 1px;
    background: #3a3d42;
}

.seat {
    background: #252729;
    border: 2px solid #414247;
    border-radius: 12px;
    padding: 0.6em 1.25em;
    min-width: 110px;
    text-align: center;
    cursor: grab;
    user-select: none;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.2em;
    transition: border-color 0.15s, background 0.15s, opacity 0.15s, transform 0.1s;
}
.seat:active { cursor: grabbing; }
.seat-you { border-color: #ffd170; }
.seat-joined { border-color: #6bffb8; }
.seat-dragging { opacity: 0.4; transform: scale(0.95); }
.seat-dragover { border-color: #ffd170; background: #3a3520; }

.seat-num {
    font-size: 0.65rem;
    color: #555;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
}
.seat-name {
    font-size: 0.9rem;
    font-weight: 600;
    color: #fefefe;
}

/* ── Rectangular table layout ─────────────────────── */
.rect-table-wrap {
    display: flex;
    justify-content: center;
    padding: 0.5em 0;
}
.rect-table {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5em;
    width: 100%;
    max-width: 700px;
}
.rect-edge {
    display: flex;
    gap: 0.5em;
    justify-content: center;
    flex-wrap: wrap;
}
/* Left/right edges stack seats vertically and fill the middle row height */
.rect-left, .rect-right {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-self: stretch;
}
.rect-middle {
    display: flex;
    align-items: stretch;
    gap: 0.5em;
    width: 100%;
    justify-content: center;
}
.rect-surface {
    flex: 1;
    min-height: 80px;
    max-width: 320px;
    background: #252729;
    border: 2px solid #3a3d42;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #444;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.12em;
}

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

.slot-you-info { display: flex; align-items: center; gap: 0.75em; flex-wrap: wrap; }
.deck-select { flex: 1; min-width: 100px; max-width: 160px; font-size: 0.82rem; padding: 0.3rem 0.5rem; }
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

.invite-action-row { display: flex; }
.accepted-text { color: #6bffb8; }

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
.start-hint { color: #888; margin: 0; font-size: 0.82rem; font-style: italic; }
.loading-txt { color: #888; font-size: 1rem; }
</style>
