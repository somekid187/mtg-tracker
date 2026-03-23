<template>
    <div class="match-field">
        <h2>{{ matchData?.name || 'Match Field' }}</h2>
        
        <div v-if="matchData" class="match-info">
            <p><strong>Format:</strong> {{ matchData.format }}</p>
            <p><strong>Starting Life:</strong> {{ matchData.startingLife }}</p>
            <p><strong>Players:</strong> {{ matchData.playerCount }}</p>
        </div>
        
        <div v-if="matchData?.players" class="players-list">
            <h3>Players</h3>
            <div v-for="player in matchData.players" :key="player.id" class="player-card">
                <h4>{{ player.name }}</h4>
                <div class="player-stats">
                    <p><strong>Starting Life:</strong> {{ player.startingLife }}</p>
                    <p><strong>Final Life:</strong> {{ player.finalLife !== null ? player.finalLife : 'TBD' }}</p>
                    <p><strong>Winner:</strong> {{ player.isWinner ? 'Yes' : 'No' }}</p>
                    <p v-if="player.tax !== null"><strong>Tax:</strong> {{ player.tax }}</p>
                    <p><strong>Placement:</strong> {{ player.placement !== null ? player.placement : 'TBD' }}</p>
                    <p><strong>Poison Counter:</strong> {{ player.poisonCounter }}</p>
                </div>
            </div>
        </div>
        
        <button @click="goBack">Back to Match Setup</button>
    </div>
</template>

<script>
import { useRouter, useRoute } from 'vue-router';

export default {
    setup() {
        const router = useRouter();
        const route = useRoute();
        return { router, route };
    },
    data() {
        return {
            matchData: null
        };
    },
    created() {
        // Retrieve match data from router state
        if (this.router.options.history.state?.matchData) {
            this.matchData = this.router.options.history.state.matchData;
        } else if (window.history.state?.matchData) {
            this.matchData = window.history.state.matchData;
        }
        
        console.log('Match Field loaded with data:', this.matchData);
    },
    methods: {
        goBack() {
            this.router.push('/match');
        }
    }
};
</script>

<style scoped>
.match-field {
    padding: 20px;
    border: 1px solid #ccc;
    border-radius: 5px;
}

.match-info {
    background-color: #f5f5f5;
    padding: 10px;
    margin: 10px 0;
    border-radius: 3px;
}

.players-list {
    margin: 20px 0;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 15px;
}

.player-card {
    background-color: #e8f4f8;
    border: 1px solid #b3d9e6;
    padding: 15px;
    border-radius: 5px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.player-card h4 {
    margin-top: 0;
    color: #333;
}

.player-stats {
    font-size: 14px;
}

.player-stats p {
    margin: 8px 0;
}

button {
    padding: 8px 15px;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 3px;
    cursor: pointer;
    margin-top: 20px;
}

button:hover {
    background-color: #0056b3;
}
</style>
