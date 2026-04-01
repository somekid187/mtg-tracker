import api from './http.service'

export const deckService = {
  createDeck(data: { name: string; commander?: string; description?: string }) {
    return api.post('/deck', data).then((r: any) => r.data)
  },

  getMyDecks() {
    return api.get('/deck').then((r: any) => r.data)
  },

  getDeckById(deckId: number) {
    return api.get(`/deck/${deckId}`).then((r: any) => r.data)
  },

  updateDeck(deckId: number, data: { name?: string; commander?: string; description?: string }) {
    return api.put(`/deck/${deckId}`, data).then((r: any) => r.data)
  },

  deleteDeck(deckId: number) {
    return api.delete(`/deck/${deckId}`).then((r: any) => r.data)
  },
}
