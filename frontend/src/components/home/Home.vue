<template>
  <div class="home-page">
    <Header />

    <!-- Hero -->
    <section class="hero">
      <p class="hero-eyebrow">Commander · EDH · Multiplayer</p>
      <h1 class="hero-title">Track Every Match,<br><span>Own Every Game.</span></h1>
      <p class="hero-subtitle">
        MTG Tracker is the ultimate life counter and match recorder for Magic: The Gathering Commander games. Free, fast, and built for your playgroup.
      </p>
      <div class="hero-actions">
        <RouterLink class="btn-primary" :to="isAuthenticated ? '/dashboard' : '/register'">Get Started</RouterLink>
        <RouterLink class="btn-secondary" :to="isAuthenticated ? '/dashboard' : '/login'">Sign In</RouterLink>
      </div>
    </section>

    <!-- Features -->
    <section class="features">
      <h2 class="section-title">Everything you need to <span>play better</span></h2>
      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">⚔️</div>
          <h3>Live Match Tracking</h3>
          <p>Track life totals, poison counters, commander damage, and the city's blessing all in one place.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">👥</div>
          <h3>Multiplayer Ready</h3>
          <p>Support for 2–6 players with a clean split-screen layout everyone at the table can see.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">📊</div>
          <h3>Match History</h3>
          <p>Every game is saved. Review past matches, final standings, and performance stats over time.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🔗</div>
          <h3>Invite Your Playgroup</h3>
          <p>Send invite codes to let friends join your matches, no account required for guests.</p>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="cta">
      <h2>Ready to start? <span>It's free.</span></h2>
      <p>Create an account in seconds and start tracking your next Commander game.</p>
      <RouterLink class="btn-primary" :to="isAuthenticated ? '/dashboard' : '/register'">Create Free Account</RouterLink>
    </section>

    <footer class="home-footer">
      © {{ new Date().getFullYear() }} MTG Tracker. Not affiliated with Wizards of the Coast.
    </footer>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import Header from '../shared/Header.vue';
import authService from '../../services/auth.service';

export default defineComponent({
  name: 'Home',
  components: {
    Header
  },
  setup() {
    const isAuthenticated = authService.isAuthenticated();
    return { isAuthenticated };
  }
});
</script>

<style scoped src="./home.css"></style>
