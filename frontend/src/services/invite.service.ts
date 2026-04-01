import api from './http.service'

export const inviteService = {
  getPendingInvites() {
    return api.get('/invites/pending').then((r: any) => r.data)
  },

  acceptInvite(id: number) {
    return api.put(`/invites/${id}/accept`).then((r: any) => r.data)
  },

  declineInvite(id: number) {
    return api.put(`/invites/${id}/decline`).then((r: any) => r.data)
  },

  sendInvite(data: { fk_player_isInvited: number; fk_match_hosts: number }) {
    return api.post('/invites', data).then((r: any) => r.data)
  },

  getInvitesByMatch(matchId: number) {
    return api.get(`/invites/match/${matchId}`).then((r: any) => r.data)
  },

  cancelInvite(id: number) {
    return api.delete(`/invites/${id}`).then((r: any) => r.data)
  },
}
