<script setup lang="ts">
import Header from './Header.vue'
</script>

<template>
  <div class="page-layout">
    <Header />
    <div class="not-found">
      <h1>404</h1>
      <p>The page you're looking for doesn't exist.</p>
      <RouterLink to="/">Go home</RouterLink>
    </div>
  </div>
</template>

<style scoped src="./shared.css"></style>
