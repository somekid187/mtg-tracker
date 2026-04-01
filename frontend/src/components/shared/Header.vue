<style scoped src="./shared.css"></style>
<template>
  <nav class="header">
    <a class="logo-container" href="/">
        <img src="/assets/mtglogo.png" alt="MTG Tracker Logo" class="logo" />
      <h1 class="app-name">MTG Tracker</h1>
    </a>
    <div class="nav-links">
      <RouterLink to="/login" v-if="!isAuthenticated">Login</RouterLink>
      <RouterLink to="/register" v-if="!isAuthenticated">Register</RouterLink>
      <RouterLink to="/dashboard" v-if="isAuthenticated">Dashboard</RouterLink>
      <button @click="handleLogout" v-if="isAuthenticated">Logout</button>
    </div>
  </nav>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import { useRouter } from 'vue-router'
import authService from '../../services/auth.service'

export default defineComponent({
  name: 'Header',
  setup() {
    const router = useRouter()
    const isAuthenticated = authService.isAuthenticated()

    async function handleLogout() {
      await authService.logout()
      router.push('/')
    }

    return { isAuthenticated, handleLogout }
  },
})
</script>
