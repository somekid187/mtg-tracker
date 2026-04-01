import api from './http.service'

export const playerService = {
  createPlayer(data: {
    startingLife: number
    isWinner?: boolean
    tax?: number
    placement: number
    killCounter?: number
    poisonCounter?: number
    minPlayers: number
    maxPlayers: number
    fk_guest_enters?: number
    fk_appUser_participates?: number
    fk_team_isIncluded?: number
    fk_match_isPlayedIn: number
    fk_deck_uses?: number
  }) {
    return api.post('/player', data).then((r: any) => r.data)
  },

  getPlayerById(playerId: number) {
    return api.get(`/player/${playerId}`).then((r: any) => r.data)
  },

  getPlayersByMatch(matchId: number) {
    return api.get(`/player/match/${matchId}`).then((r: any) => r.data)
  },

  updatePlayer(
    playerId: number,
    data: {
      startingLife?: number
      finalLife?: number
      isWinner?: boolean
      tax?: number
      placement?: number
      killCounter?: number
      poisonCounter?: number
      fk_team_isIncluded?: number
    }
  ) {
    return api.put(`/player/${playerId}`, data).then((r: any) => r.data)
  },

  deletePlayer(playerId: number) {
    return api.delete(`/player/${playerId}`).then((r: any) => r.data)
  },
}
