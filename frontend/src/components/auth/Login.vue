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
      </form>
      <p class="auth-footer">Don't have an account? <router-link to="/register">Register here</router-link>.</p>
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
      password: ''
    };
  },
  methods: {
    onSubmit() {
      authService.login({ email: this.email, password: this.password })
        .then(response => {
          console.log('Login successful', response);
          // Redirect to the desired page after login
          this.$router.push('/dashboard');
        })
        .catch(error => {
          console.error('Login failed', error);
        });
    }
  }
};
</script>

<style scoped src="./auth.css"></style>