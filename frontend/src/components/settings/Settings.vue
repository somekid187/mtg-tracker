<template>
  <div class="page-layout">
    <Sidebar />

    <div class="settings-content">
      <h1 class="page-title">Settings</h1>

      <!-- Profile -->
      <div class="section-card">
        <h2 class="section-header">Profile</h2>
        <p v-if="loadError" class="feedback error">{{ loadError }}</p>

        <div v-else class="field-group">
          <div class="field-row">
            <label class="field-label">Username</label>
            <input
              class="settings-input"
              type="text"
              v-model="username"
              placeholder="Username"
              :disabled="saving || loading"
            />
          </div>

          <div class="field-row">
            <label class="field-label">Email</label>
            <input
              class="settings-input"
              type="email"
              :value="email"
              disabled
            />
          </div>

          <div class="field-actions">
            <p v-if="profileFeedback" class="feedback" :class="profileFeedback.type">
              {{ profileFeedback.msg }}
            </p>
            <button class="btn-save" @click="saveProfile" :disabled="saving || loading">
              {{ saving ? 'Saving…' : 'Save Changes' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Security -->
      <div class="section-card">
        <h2 class="section-header">Security</h2>
        <p class="section-desc">
          A password reset link will be sent to your registered email address.
        </p>
        <div class="section-action-row">
          <p v-if="passwordFeedback" class="feedback" :class="passwordFeedback.type">
            {{ passwordFeedback.msg }}
          </p>
          <button class="btn-save" @click="sendPasswordReset" :disabled="sendingReset || loading">
            {{ sendingReset ? 'Sending…' : 'Send Password Reset Email' }}
          </button>
        </div>
      </div>

      <!-- Danger Zone -->
      <div class="section-card danger-card">
        <h2 class="section-header danger">Danger Zone</h2>
        <p class="section-desc">
          Permanently delete your account and all associated data. This cannot be undone.
        </p>
        <div class="section-action-row">
          <button class="btn-danger" @click="showDeleteModal = true">Delete Account</button>
        </div>
      </div>
    </div>

    <!-- Delete Confirm Modal -->
    <div v-if="showDeleteModal" class="modal-backdrop" @click.self="showDeleteModal = false">
      <div class="modal">
        <h2>Delete Account</h2>
        <p>
          Are you sure you want to permanently delete your account? All your matches, stats, and
          friendships will be removed. This action cannot be undone.
        </p>
        <p v-if="deleteFeedback" class="feedback error">{{ deleteFeedback }}</p>
        <div class="modal-actions">
          <button class="btn-save" @click="showDeleteModal = false" :disabled="deleting">
            Cancel
          </button>
          <button class="btn-danger" @click="deleteAccount" :disabled="deleting">
            {{ deleting ? 'Deleting…' : 'Delete Account' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
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
        authService.logout()
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
</script>

<style scoped src="./settings.css"></style>
