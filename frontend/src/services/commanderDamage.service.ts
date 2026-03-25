import api from './http.service'

export const commanderDamageService = {
  createCommanderDamage(data: {
    damageAmount: number
    isLethal?: boolean
    fk_player_deals?: number
    fk_player_receives?: number
    fk_match_refersTo: number
  }) {
    return api.post('/commander-damage', data).then((r: any) => r.data)
  },

  getCommanderDamageById(id: number) {
    return api.get(`/commander-damage/${id}`).then((r: any) => r.data)
  },

  getCommanderDamageByMatch(matchId: number) {
    return api.get(`/commander-damage/match/${matchId}`).then((r: any) => r.data)
  },

  updateCommanderDamage(
    id: number,
    data: {
      damageAmount?: number
      isLethal?: boolean
      fk_player_deals?: number
      fk_player_receives?: number
    }
  ) {
    return api.put(`/commander-damage/${id}`, data).then((r: any) => r.data)
  },

  deleteCommanderDamage(id: number) {
    return api.delete(`/commander-damage/${id}`).then((r: any) => r.data)
  },
}
