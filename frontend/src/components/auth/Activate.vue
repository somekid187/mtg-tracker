<template>
  <div class="auth-page">
    <Header />
    <div class="auth-body">
      <div class="auth-card">
      <h2 class="auth-title">Activate Account</h2>
      <form v-if="!isActivated" class="auth-form" @submit.prevent="onSubmit">
        <div class="form-group">
          <label class="form-label">Activation Token</label>
          <input class="form-input" type="text" v-model="token" placeholder="Paste your token here" required>
        </div>
        <button class="btn-primary" type="submit" :disabled="isSubmitting">
          {{ isSubmitting ? 'Activating...' : 'Activate Account' }}
        </button>
      </form>
      <p v-if="message" class="auth-message" :class="{ success: isActivated }">{{ message }}</p>
      <p class="auth-footer"><router-link to="/login">Go to Login</router-link></p>
      </div>
    </div>
  </div>
</template>

<script>
import authService from '../../services/auth.service'
import Header from '../shared/Header.vue'

export default {
  components: { Header },
  data() {
    return {
      token: '',
      isSubmitting: false,
      isActivated: false,
      message: ''
    }
  },
  created() {
    const tokenFromQuery = this.$route.query.token
    if (typeof tokenFromQuery === 'string' && tokenFromQuery.trim() !== '') {
      this.token = tokenFromQuery
      this.onSubmit()
    }
  },
  methods: {
    onSubmit() {
      if (!this.token.trim()) {
        this.message = 'Activation token is required.'
        return
      }

      this.isSubmitting = true
      this.message = ''

      authService.activateAccount(this.token.trim())
        .then(() => {
          this.isActivated = true
          this.message = 'Account activated successfully. You can now log in.'
        })
        .catch(() => {
          this.message = 'Activation failed. The token may be invalid or expired.'
        })
        .finally(() => {
          this.isSubmitting = false
        })
    }
  }
}
</script>

<style scoped src="./auth.css"></style>
