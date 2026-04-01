import { ref } from 'vue'
import { userService } from '../services/user.service'
import { inviteService } from '../services/invite.service'

// Shared reactive notification counts — imported by Sidebar and Friends.
export const pendingFriendRequests = ref(0)
export const pendingGameInvites = ref(0)

export async function refreshNotifications() {
  try {
    const [fr, gi] = await Promise.all([
      userService.getFriendRequests(),
      inviteService.getPendingInvites(),
    ])
    pendingFriendRequests.value = (fr?.data ?? []).length
    pendingGameInvites.value = (gi?.data ?? []).length
  } catch {
    // reset to 0 on error (e.g. session expired) so badge doesn't stay stale
    pendingFriendRequests.value = 0
    pendingGameInvites.value = 0
  }
}
