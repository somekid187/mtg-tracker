import { defineComponent, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'
import { userService } from '../../services/user.service'
import authService from '../../services/auth.service'

export default defineComponent({
  name: 'Settings',
  components: { Sidebar },
  setup() {
    const router = useRouter()

    const username = ref('')
    const email = ref('')
    const loading = ref(true)
    const loadError = ref<string | null>(null)

    const saving = ref(false)
    const profileFeedback = ref<{ msg: string; type: 'success' | 'error' } | null>(null)

    const sendingReset = ref(false)
    const passwordFeedback = ref<{ msg: string; type: 'success' | 'error' } | null>(null)

    const showDeleteModal = ref(false)
    const deleting = ref(false)
    const deleteFeedback = ref<string | null>(null)

    async function loadProfile() {
      loading.value = true
      loadError.value = null
      try {
        const res = await userService.getProfile()
        username.value = res.data.username ?? ''
        email.value = res.data.email ?? ''
      } catch (err: any) {
        loadError.value = err?.response?.data?.message || 'Failed to load profile.'
      } finally {
        loading.value = false
      }
    }

    async function saveProfile() {
      saving.value = true
      profileFeedback.value = null
      try {
        await userService.updateProfile({ username: username.value })
        profileFeedback.value = { msg: 'Profile updated successfully!', type: 'success' }
      } catch (err: any) {
        profileFeedback.value = {
          msg: err?.response?.data?.message || 'Failed to update profile.',
          type: 'error',
        }
      } finally {
        saving.value = false
      }
    }

    async function sendPasswordReset() {
      sendingReset.value = true
      passwordFeedback.value = null
      try {
        await userService.requestPasswordReset(email.value)
        passwordFeedback.value = { msg: 'Password reset email sent!', type: 'success' }
      } catch (err: any) {
        passwordFeedback.value = {
          msg: err?.response?.data?.message || 'Failed to send reset email.',
          type: 'error',
        }
      } finally {
        sendingReset.value = false
      }
    }

    async function deleteAccount() {
      deleting.value = true
      deleteFeedback.value = null
      try {
        await userService.deleteAccount()
        await authService.logout()
        router.push('/')
      } catch (err: any) {
        deleteFeedback.value = err?.response?.data?.message || 'Failed to delete account.'
        deleting.value = false
      }
    }

    onMounted(loadProfile)

    return {
      username,
      email,
      loading,
      loadError,
      saving,
      profileFeedback,
      sendingReset,
      passwordFeedback,
      showDeleteModal,
      deleting,
      deleteFeedback,
      saveProfile,
      sendPasswordReset,
      deleteAccount,
    }
  },
})