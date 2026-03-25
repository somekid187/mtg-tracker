import api from './http.service'

export const userService = {
  getFriends() {
    return api.get('/user/friends').then((r: any) => r.data)
  },

  getFriendRequests() {
    return api.get('/user/friends/requests').then((r: any) => r.data)
  },

  sendFriendRequest(receiverId: number) {
    return api.post('/user/friends/request', { receiverId }).then((r: any) => r.data)
  },

  acceptFriendRequest(friendshipId: number) {
    return api.post(`/user/friends/${friendshipId}/accept`).then((r: any) => r.data)
  },

  rejectFriendRequest(friendshipId: number) {
    return api.post(`/user/friends/${friendshipId}/reject`).then((r: any) => r.data)
  },

  removeFriend(friendshipId: number) {
    return api.delete(`/user/friends/${friendshipId}`).then((r: any) => r.data)
  },
}
