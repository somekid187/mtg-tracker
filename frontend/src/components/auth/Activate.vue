<template>
  <div>
    <h2>Activate Account</h2>

    <form v-if="!isActivated" @submit.prevent="onSubmit">
      <label>Activation Token:</label>
      <input type="text" v-model="token" required>

      <button type="submit" :disabled="isSubmitting">
        {{ isSubmitting ? 'Activating...' : 'Activate Account' }}
      </button>
    </form>

    <p v-if="message">{{ message }}</p>
    <p><router-link to="/login">Go to Login</router-link></p>
  </div>
</template>

<script>
import authService from '../../services/auth.service'

export default {
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
