<template>
  <div class="page-layout">
    <Sidebar />
    <div class="dashboard-content">
      <div class="dashboard-row">
        <div class="box"></div>
        <div class="box"></div>
        <div class="box"></div>
      </div>
      <div class="dashboard-row">
        <div class="create-match box">
          <h2>Create Match</h2>
          <p>Start a new match and track your stats in real-time.</p>
          <button class="btn-primary" @click="router.push('/match')">Create Match</button>
        </div>
        <div class="create-event box">
          <h2>Create Event</h2>
          <p>Organize your tournaments and events with ease.</p>
          <button class="btn-primary" @click="router.push('/event')">Create Event</button>
        </div>
      </div>
      <div class="dashboard-row">
        <div class="box"></div>
      </div>
    </div>
  </div>
</template>

<script>
import { useRouter } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'

export default {
  components: { Sidebar },
  setup() {
    const router = useRouter()
    return { router }
  },

}


</script>

<style scoped src="./dashboard.css"></style>
