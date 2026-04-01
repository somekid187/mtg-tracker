<template>
  <div class="auth-page">
    <Header />
    <div class="auth-body">
      <div class="auth-card">

        <!-- Step 1: Request reset email -->
        <template v-if="step === 'request'">
          <h2 class="auth-title">Reset Password</h2>
          <form class="auth-form" @submit.prevent="onRequestReset">
            <div class="form-group">
              <label class="form-label">Email</label>
              <input class="form-input" type="email" v-model="email" placeholder="your@email.com" required />
            </div>
            <button class="btn-primary" type="submit" :disabled="submitting">
              {{ submitting ? 'Sending…' : 'Send Reset Email' }}
            </button>
            <p v-if="message" class="auth-message" :class="{ success: success }">{{ message }}</p>
          </form>
          <p class="auth-footer"><router-link to="/login">Back to Login</router-link></p>
        </template>

        <!-- Step 2: Set new password (token from URL query) -->
        <template v-else-if="step === 'reset'">
          <h2 class="auth-title">New Password</h2>
          <form class="auth-form" @submit.prevent="onChangePassword">
            <div class="form-group password-group">
              <label class="form-label">New Password</label>
              <input
                class="form-input" type="password" v-model="password"
                placeholder="••••••••" required
                @focus="passwordFocused = true" @blur="passwordFocused = false"
              />
              <ul v-if="password.length > 0 && passwordFocused" class="password-requirements">
                <li :class="hasMinLength ? 'requirement met' : 'requirement unmet'">At least 8 characters</li>
                <li :class="hasUppercase ? 'requirement met' : 'requirement unmet'">One uppercase letter</li>
                <li :class="hasLowercase ? 'requirement met' : 'requirement unmet'">One lowercase letter</li>
                <li :class="hasDigit ? 'requirement met' : 'requirement unmet'">One digit</li>
                <li :class="hasSpecialChar ? 'requirement met' : 'requirement unmet'">One special character</li>
              </ul>
            </div>
            <div class="form-group">
              <label class="form-label">Confirm Password</label>
              <input class="form-input" type="password" v-model="confirmPassword" placeholder="••••••••" required />
              <p v-if="confirmPassword.length > 0 && !passwordsMatch" class="password-mismatch">Passwords do not match</p>
            </div>
            <button class="btn-primary" type="submit" :disabled="submitting || !passwordValid">
              {{ submitting ? 'Saving…' : 'Set New Password' }}
            </button>
            <p v-if="message" class="auth-message" :class="{ success: success }">{{ message }}</p>
          </form>
          <p class="auth-footer"><router-link to="/login">Back to Login</router-link></p>
        </template>

      </div>
    </div>
  </div>
</template>

<script>
import Header from '../shared/Header.vue'
import { userService } from '../../services/user.service'

export default {
  components: { Header },
  data() {
    return {
      step: 'request',
      email: '',
      password: '',
      confirmPassword: '',
      passwordFocused: false,
      submitting: false,
      success: false,
      message: '',
      token: '',
    }
  },
  computed: {
    hasMinLength()  { return this.password.length >= 8 },
    hasUppercase()  { return /[A-Z]/.test(this.password) },
    hasLowercase()  { return /[a-z]/.test(this.password) },
    hasDigit()      { return /\d/.test(this.password) },
    hasSpecialChar(){ return /[!@#$%^&*(),.?":{}|<>]/.test(this.password) },
    passwordsMatch(){ return this.password === this.confirmPassword && this.confirmPassword.length > 0 },
    passwordValid() {
      return this.hasMinLength && this.hasUppercase && this.hasLowercase
          && this.hasDigit && this.hasSpecialChar && this.passwordsMatch
    },
  },
  created() {
    const tokenFromQuery = this.$route.query.token
    if (typeof tokenFromQuery === 'string' && tokenFromQuery.trim() !== '') {
      this.token = tokenFromQuery.trim()
      this.step = 'reset'
    }
  },
  methods: {
    async onRequestReset() {
      this.message = ''
      this.success = false
      this.submitting = true
      try {
        await userService.requestPasswordReset(this.email.trim())
        this.success = true
        this.message = 'If an account with that email exists, a reset link has been sent.'
      } catch (err) {
        this.message = err?.response?.data?.message || err?.message || 'Failed to send reset email.'
      } finally {
        this.submitting = false
      }
    },
    async onChangePassword() {
      if (!this.passwordValid) return
      this.message = ''
      this.success = false
      this.submitting = true
      try {
        await userService.changePassword(this.token, this.password)
        this.success = true
        this.message = 'Password changed successfully! Redirecting to login…'
        setTimeout(() => this.$router.push('/login'), 2000)
      } catch (err) {
        this.message = err?.response?.data?.message || err?.message || 'Failed to reset password. The link may have expired.'
      } finally {
        this.submitting = false
      }
    },
  },
}
</script>

<style scoped src="./auth.css"></style>
