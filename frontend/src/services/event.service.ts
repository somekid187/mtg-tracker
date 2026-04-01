import api from './http.service'

export const eventService = {
  createEvent(data: { name: string; description?: string }) {
    return api.post('/event', data).then((r: any) => r.data)
  },

  getMyEvents() {
    return api.get('/event').then((r: any) => r.data)
  },

  getEventById(eventId: number) {
    return api.get(`/event/${eventId}`).then((r: any) => r.data)
  },

  updateEvent(eventId: number, data: { name?: string; description?: string }) {
    return api.put(`/event/${eventId}`, data).then((r: any) => r.data)
  },

  deleteEvent(eventId: number) {
    return api.delete(`/event/${eventId}`).then((r: any) => r.data)
  },

  addMatchToEvent(eventId: number, matchId: number) {
    return api.post(`/event/${eventId}/match`, { matchId }).then((r: any) => r.data)
  },

  removeMatchFromEvent(eventId: number, matchId: number) {
    return api.delete(`/event/${eventId}/match/${matchId}`).then((r: any) => r.data)
  },

  getEventStats(eventId: number) {
    return api.get(`/event/${eventId}/stats`).then((r: any) => r.data)
  },
}
