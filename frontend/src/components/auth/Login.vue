<template>
  <div class="auth-page">
    <Header />
    <div class="auth-body">
      <div class="auth-card">
      <h2 class="auth-title">Login</h2>
      <form class="auth-form" @submit.prevent="onSubmit">
        <div class="form-group">
          <label class="form-label">Email</label>
          <input class="form-input" type="email" v-model="email" placeholder="your@email.com" required>
        </div>
        <div class="form-group">
          <label class="form-label">Password</label>
          <input class="form-input" type="password" v-model="password" placeholder="••••••••" required>
        </div>
        <button class="btn-primary" type="submit">Login</button>
        <p v-if="errorMessage" class="auth-message">{{ errorMessage }}</p>
        <p v-if="showRegisterSuccess" class="auth-message success">Registration successful. Check your email for verification.</p>
      </form>
      <p class="auth-footer">Don't have an account? <router-link to="/register">Register here</router-link>.</p>
      <p class="auth-footer"><router-link to="/reset-password">Forgot your password?</router-link></p>
      </div>
    </div>
  </div>
</template>

<script>
import authService from '../../services/auth.service';
import Header from '../shared/Header.vue';

export default {
  components: { Header },
  data() {
    return {
      email: '',
      password: '',
      errorMessage: '',
      showRegisterSuccess: false
    };
  },
  mounted() {
    if (this.$route.query.registeringSuccess) {
      this.showRegisterSuccess = true;
      setTimeout(() => {
        this.showRegisterSuccess = false;
      }, 5000);
    }
  },
  methods: {
    onSubmit() {
      this.errorMessage = '';
      authService.login({ email: this.email, password: this.password })
        .then(() => {
          const redirect = this.$route.query.redirect;
          this.$router.push(redirect ? String(redirect) : '/dashboard');
        })
        .catch(error => {
          console.error('Login failed', error);
          this.errorMessage = error?.response?.data?.message || error?.message || 'Login failed. Please check your email and password.';
        });
    }
  }
};
</script>

<style scoped src="./auth.css"></style>