import api from './http.service'

export const guestService = {
  createGuest(data: { guestName: string }) {
    return api.post('/guest', data).then((r: any) => r.data)
  },

  getGuestById(guestId: number) {
    return api.get(`/guest/${guestId}`).then((r: any) => r.data)
  },

  updateGuest(guestId: number, data: { guestName: string }) {
    return api.put(`/guest/${guestId}`, data).then((r: any) => r.data)
  },

  deleteGuest(guestId: number) {
    return api.delete(`/guest/${guestId}`).then((r: any) => r.data)
  },
}
