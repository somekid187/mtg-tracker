// services/match.service.js
export const matchService = {
  createMatch(match: { name?: string; format: string; startingLife?: number }) {
    // Logic to create a match
    console.log('Match created:', match);
  },
  addPlayer(player: { name: string; life: number } ) {
    // Logic to add a player
    console.log('Player added:', player);
  },
  removePlayer(playerId: string) {
    // Logic to remove a player
    console.log('Player removed:', playerId);
  }
};