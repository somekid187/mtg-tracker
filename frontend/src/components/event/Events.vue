<template>
  <div class="page-layout">
    <Sidebar />
    <div class="events-content">
      <div class="events-header-row">
        <h1 class="events-title">Events</h1>
        <button class="btn-primary-inline" @click="showCreate = true">+ New Event</button>
      </div>

      <!-- Create Event Modal -->
      <div v-if="showCreate" class="modal-overlay" @click.self="showCreate = false">
        <div class="modal-box">
          <h2>Create Event</h2>
          <form @submit.prevent="createEvent">
            <div class="form-group">
              <input
                v-model="newEvent.name"
                type="text"
                class="form-input"
                placeholder="Event Name"
                maxlength="255"
                required
              />
              <textarea
                v-model="newEvent.description"
                class="form-input form-textarea"
                placeholder="Description (optional)"
                rows="3"
              />
            </div>
            <p v-if="createError" class="error-msg">{{ createError }}</p>
            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showCreate = false">Cancel</button>
              <button type="submit" class="btn-primary-inline" :disabled="creating">
                {{ creating ? 'Creating…' : 'Create' }}
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Events list -->
      <div v-if="loading" class="events-empty">Loading…</div>
      <div v-else-if="events.length === 0" class="events-empty">
        No events yet. Create your first event!
      </div>
      <div v-else class="events-grid">
        <div
          v-for="event in events"
          :key="event.pk_event"
          class="event-card box clickable"
          @click="router.push('/event/' + event.pk_event)"
        >
          <div class="event-card-header">
            <span class="event-card-name">{{ event.name }}</span>
            <button
              class="btn-delete-match"
              @click.stop="deleteEvent(event)"
              title="Delete event"
            >✕</button>
          </div>
          <p v-if="event.description" class="event-card-desc">{{ event.description }}</p>
          <div class="event-card-meta">
            <span>{{ event.matchCount }} match{{ event.matchCount !== 1 ? 'es' : '' }}</span>
            <span>Created {{ formatDate(event.createdAt) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { useRouter } from 'vue-router'
import Sidebar from '../shared/Sidebar.vue'
import { eventService } from '../../services/event.service'

export default {
  components: { Sidebar },
  setup() {
    const router = useRouter()
    function formatDate(dateStr) {
      if (!dateStr) return '—'
      const iso = String(dateStr).replace(' ', 'T')
      const d = new Date(iso)
      if (isNaN(d.getTime())) return '—'
      return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
    }
    return { router, formatDate }
  },
  data() {
    return {
      events: [],
      loading: true,
      showCreate: false,
      creating: false,
      createError: '',
      newEvent: { name: '', description: '' },
    }
  },
  async mounted() {
    await this.loadEvents()
  },
  methods: {
    async loadEvents() {
      this.loading = true
      try {
        const res = await eventService.getMyEvents()
        this.events = Array.isArray(res.data) ? res.data : []
      } catch {
        this.events = []
      } finally {
        this.loading = false
      }
    },
    async createEvent() {
      if (!this.newEvent.name.trim()) {
        this.createError = 'Event name is required.'
        return
      }
      this.createError = ''
      this.creating = true
      try {
        const res = await eventService.createEvent({
          name: this.newEvent.name.trim(),
          description: this.newEvent.description.trim() || undefined,
        })
        this.showCreate = false
        this.newEvent = { name: '', description: '' }
        this.router.push('/event/' + res.data.pk_event)
      } catch (err) {
        this.createError = err?.response?.data?.message || err?.message || 'Failed to create event.'
      } finally {
        this.creating = false
      }
    },
    async deleteEvent(event) {
      try {
        await eventService.deleteEvent(event.pk_event)
        this.events = this.events.filter(e => e.pk_event !== event.pk_event)
      } catch {
        // silently fail
      }
    },
  },
}
</script>

<style scoped src="./event.css"></style>
