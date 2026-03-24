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

            <div v-if="match.format == 'Custom'" class="custom-toggles">
                <label><input type="checkbox" v-model="customOptions.hasPoison" /> Poison Counters</label>
                <label><input type="checkbox" v-model="customOptions.hasTax" /> Commander Tax</label>
                <label><input type="checkbox" v-model="customOptions.hasCommanderDamage" /> Commander Damage</label>
            </div>
            
            <label>Number of Players:</label>
            <select v-model="match.playerCount" name="playerCount">
                <option value="">Select Player Count</option>
                <option v-for="count in [2, 3, 4, 5, 6]" :key="count" :value="count">
                    {{ count }} Players
                </option>
            </select>
            
            <button type="submit">Create Match</button>
            <p v-if="createError" class="error">{{ createError }}</p>
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
                playerCount: ''
            },
            playerNames: [],
            formatOptions: formats.formats,
            matchCreated: false,
            createError: '',
            customOptions: {
                hasPoison: false,
                hasTax: false,
                hasCommanderDamage: false
            }
        };
    },
    methods: {
        createMatch() {
            if (!this.match.format) {
                this.createError = 'Please select a format.';
                return;
            }
            if (!this.match.playerCount) {
                this.createError = 'Please select the number of players.';
                return;
            }
            this.createError = '';
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
            const isCustom = this.match.format === 'Custom';
            const hasPoison = isCustom ? this.customOptions.hasPoison : (selectedFormat?.has_poison ?? false);
            const hasTax = isCustom ? this.customOptions.hasTax : (selectedFormat?.has_tax ?? false);
            const hasCommanderDamage = isCustom ? this.customOptions.hasCommanderDamage : (selectedFormat?.has_commander_damage ?? false);
            const count = parseInt(this.match.playerCount);

            const players = this.playerNames
                .map((name, index) => ({
                    id: index + 1,
                    name: name.trim() || `Player ${index + 1}`,
                    startingLife: this.match.startingLife,
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
                        : null
                }));

            const matchData = {
                ...this.match,
                hasCommanderDamage,
                hasPoison,
                hasTax,
                players
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
            const count = parseInt(newCount);
            if (count) {
                this.playerNames = Array(count).fill('');
            } else {
                this.playerNames = [];
            }
        }
    }
};
</script>

<style scoped>
.error {
    color: red;
    margin-top: 8px;
}
</style>