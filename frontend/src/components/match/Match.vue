<template>
    <div>
        <h2>Create Match</h2>
        
        <!-- Initial Match Setup Form -->
        <form v-if="!matchCreated" @submit.prevent="createMatch">
            <input type="text" v-model="match.name" placeholder="Match Name (optional)" />
            <select name="format" id="" v-model="match.format">
                <option value="">Select Format</option>
                <option v-for="format in formatOptions" :key="format.name" :value="format.name">
                    {{ format.name }}
                </option>
            </select>
            <input v-if="match.format == 'Custom'" type="number" v-model.number="match.startingLife"
                placeholder="Starting Life Total" />
            
            <label>Number of Players:</label>
            <select v-model.number="match.playerCount" name="playerCount">
                <option value="">Select Player Count</option>
                <option v-for="count in [2, 3, 4, 5, 6]" :key="count" :value="count">
                    {{ count }} Players
                </option>
            </select>
            
            <button type="submit">Create Match</button>
        </form>
        
        <!-- Player Names Form -->
        <form v-if="matchCreated" @submit.prevent="startMatch">
            <h3>Enter Player Names</h3>
            <div v-for="(name, index) in playerNames" :key="index" class="player-input">
                <label>Player {{ index + 1 }}:</label>
                <input type="text" v-model="playerNames[index]" :placeholder="`Player ${index + 1} name`" />
            </div>
            
            <button type="submit">Start Match</button>
        </form>
    </div>
</template>

<script>
import { useRouter } from 'vue-router';
import formats from '../../utils/format.json';

export default {
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
                playerCount: null
            },
            playerNames: [],
            formatOptions: formats.formats,
            matchCreated: false
        };
    },
    methods: {
        createMatch() {
            this.matchCreated = true;
            console.log('Match details:', {
                name: this.match.name,
                format: this.match.format,
                startingLife: this.match.startingLife,
                playerCount: this.match.playerCount
            });
        },
        startMatch() {
            const selectedFormat = this.formatOptions.find(f => f.name === this.match.format);
            
            // Create player objects with all required properties
            const players = this.playerNames
                .map((name, index) => ({
                    id: index + 1,
                    name: name.trim() || `Player ${index + 1}`,
                    startingLife: this.match.startingLife,
                    finalLife: null,
                    isWinner: false,
                    tax: selectedFormat?.has_tax ? 0 : null,
                    placement: null,
                    poisonCounter: 0
                }));
            
            const matchData = {
                ...this.match,
                players: players
            };
            console.log('Match started:', matchData);
            
            // Generate a temporary match ID (in production, this would come from backend)
            const matchId = Date.now().toString();
            
            // Navigate to matchfield and pass match data
            this.router.push({
                path: `/match/${matchId}`,
                state: { matchData }
            });
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
            if (newCount) {
                this.playerNames = Array(newCount).fill('');
            } else {
                this.playerNames = [];
            }
        }
    }
};
</script>