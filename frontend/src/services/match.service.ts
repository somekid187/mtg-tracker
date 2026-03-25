import api from './http.service'

export const matchService = {
  createMatch(data: {
    name?: string
    description?: string
    format: string
    startingLife: number
    startTime: string
    isTeamMatch: boolean
    commanderThreshold?: number
    counterThreshold?: number
  }) {
    return api.post('/match', data).then((r: any) => r.data)
  },

  joinMatch(data: { inviteCode: string }) {
    return api.post('/match/join', data).then((r: any) => r.data)
  },

  leaveMatch(data: { matchId: number }) {
    return api.post('/match/leave', data).then((r: any) => r.data)
  },

  getMatchById(matchId: number) {
    return api.get(`/match/${matchId}`).then((r: any) => r.data)
  },

  updateMatch(
    matchId: number,
    data: {
      name?: string
      description?: string
      format?: string
      startingLife?: number
      startTime?: string
      isTeamMatch?: boolean
      commanderThreshold?: number
      counterThreshold?: number
    }
  ) {
    return api.put(`/match/${matchId}`, data).then((r: any) => r.data)
  },

  deleteMatch(matchId: number) {
    return api.delete(`/match/${matchId}`).then((r: any) => r.data)
  },

  sendInviteEmail(data: { email: string; matchId: number; inviteCode: string }) {
    return api.post('/match/invite-email', data).then((r: any) => r.data)
  },

  getPlayersByMatch(matchId: number) {
    return api.get(`/player/match/${matchId}`).then((r: any) => r.data)
  },
}
