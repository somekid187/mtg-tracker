<template>
    <div class="dashboard">
        <h1>MTG Tracker</h1>

        <div class="dashboard-actions">
            <div class="action-card" @click="router.push('/match')">
                <h2>New Match</h2>
                <p>Set up and start a new game</p>
            </div>
        </div>

        <div class="recent-matches">
            <h2>Recent Matches</h2>
            <p class="placeholder">No matches recorded yet.</p>
        </div>
    </div>
</template>

<script>
import { useRouter } from 'vue-router';

export default {
    setup() {
        const router = useRouter();
        return { router };
    }
};
</script>

<style scoped>
.dashboard {
    padding: 24px;
}

.dashboard-actions {
    display: flex;
    gap: 16px;
    margin: 24px 0;
}

.action-card {
    border: 1px solid #ccc;
    border-radius: 8px;
    padding: 24px 32px;
    cursor: pointer;
    transition: background-color 0.2s;
}

.action-card:hover {
    background-color: #f0f0f0;
}

.action-card h2 {
    margin: 0 0 8px;
}

.action-card p {
    margin: 0;
    color: #555;
}

.recent-matches {
    margin-top: 32px;
}

.placeholder {
    color: #888;
}
</style>
