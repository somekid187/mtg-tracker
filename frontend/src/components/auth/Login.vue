<template>
  <div>
    <h2>Login</h2>
    <form @submit.prevent="onSubmit">
      <label>Email:</label>
      <input type="email" v-model="email">

      <label>Password:</label>
      <input type="password" v-model="password">

      <button type="submit">Login</button>
    </form>
    <p>Don't have an account? <router-link to="/register">Register here</router-link>.</p>
  </div>
</template>

<script>
import authService from '../../services/auth.service';

export default {
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