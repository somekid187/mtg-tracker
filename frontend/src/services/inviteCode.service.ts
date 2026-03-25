import axios from 'axios'
import api from './http.service'

const apiURL = process.env.BACKEND_URL || 'http://localhost:3000'

export const inviteCodeService = {
  createInviteCode(data: { code: string; expiresAt: string; fk_match_connects: number }) {
    return api.post('/invite-code', data).then((r: any) => r.data)
  },

  getInviteCodeById(id: number) {
    return api.get(`/invite-code/${id}`).then((r: any) => r.data)
  },

  getInviteCodesByMatch(matchId: number) {
    return api.get(`/invite-code/match/${matchId}`).then((r: any) => r.data)
  },

  // Public — no auth required
  getInviteCodeByCode(code: string) {
    return axios
      .get(`${apiURL}/invite-code/code/${code}`)
      .then((r: any) => r.data)
  },

  expireInviteCode(id: number) {
    return api.put(`/invite-code/${id}/expire`).then((r: any) => r.data)
  },

  deleteInviteCode(id: number) {
    return api.delete(`/invite-code/${id}`).then((r: any) => r.data)
  },
}
