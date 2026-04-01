<template>
  <div class="page-layout">
    <Sidebar />
    <div class="decks-content">
      <div class="decks-header-row">
        <h1 class="decks-title">Decks</h1>
        <button class="btn-primary-inline" @click="openCreate">+ New Deck</button>
      </div>

      <!-- Create / Edit Modal -->
      <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
        <div class="modal-box">
          <h2>{{ editingDeck ? 'Edit Deck' : 'Create Deck' }}</h2>
          <form @submit.prevent="submitForm">
            <div class="form-group">
              <input
                v-model="form.name"
                type="text"
                class="form-input"
                placeholder="Deck Name"
                maxlength="255"
                required
              />
              <input
                v-model="form.commander"
                type="text"
                class="form-input"
                placeholder="Commander (optional)"
                maxlength="255"
              />
              <textarea
                v-model="form.description"
                class="form-input form-textarea"
                placeholder="Description (optional)"
                rows="3"
              />
            </div>
            <p v-if="formError" class="error-msg">{{ formError }}</p>
            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="closeForm">Cancel</button>
              <button type="submit" class="btn-primary-inline" :disabled="submitting">
                {{ submitting ? (editingDeck ? 'Saving…' : 'Creating…') : (editingDeck ? 'Save' : 'Create') }}
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Deck list -->
      <div v-if="loading" class="decks-empty">Loading…</div>
      <div v-else-if="decks.length === 0" class="decks-empty">
        No decks yet. Create your first deck!
      </div>
      <div v-else class="decks-grid">
        <div
          v-for="deck in decks"
          :key="deck.pk_deck"
          class="deck-card"
        >
          <div class="deck-card-header">
            <span class="deck-card-name">{{ deck.name }}</span>
            <div class="deck-card-actions">
              <button class="btn-icon" @click="openEdit(deck)" title="Edit deck">✏️</button>
              <button class="btn-delete-match" @click="deleteDeck(deck)" title="Delete deck">✕</button>
            </div>
          </div>
          <p v-if="deck.commander" class="deck-card-commander">Commander: {{ deck.commander }}</p>
          <p v-if="deck.description" class="deck-card-desc">{{ deck.description }}</p>
          <div class="deck-card-meta">
            <span>Created {{ formatDate(deck.createdAt) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Sidebar from '../shared/Sidebar.vue'
import { deckService } from '../../services/deck.service'

export default {
  components: { Sidebar },
  setup() {
    function formatDate(dateStr) {
      if (!dateStr) return '—'
      const iso = String(dateStr).replace(' ', 'T')
      const d = new Date(iso)
      if (isNaN(d.getTime())) return '—'
      return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
    }
    return { formatDate }
  },
  data() {
    return {
      decks: [],
      loading: true,
      showForm: false,
      submitting: false,
      formError: '',
      editingDeck: null,
      form: { name: '', commander: '', description: '' },
    }
  },
  async mounted() {
    await this.loadDecks()
  },
  methods: {
    async loadDecks() {
      this.loading = true
      try {
        const res = await deckService.getMyDecks()
        this.decks = Array.isArray(res.data) ? res.data : []
      } catch {
        this.decks = []
      } finally {
        this.loading = false
      }
    },
    openCreate() {
      this.editingDeck = null
      this.form = { name: '', commander: '', description: '' }
      this.formError = ''
      this.showForm = true
    },
    openEdit(deck) {
      this.editingDeck = deck
      this.form = { name: deck.name, commander: deck.commander || '', description: deck.description || '' }
      this.formError = ''
      this.showForm = true
    },
    closeForm() {
      this.showForm = false
      this.editingDeck = null
      this.formError = ''
    },
    async submitForm() {
      if (!this.form.name.trim()) {
        this.formError = 'Deck name is required.'
        return
      }
      this.formError = ''
      this.submitting = true
      try {
        const payload = {
          name: this.form.name.trim(),
          commander: this.form.commander.trim() || undefined,
          description: this.form.description.trim() || undefined,
        }
        if (this.editingDeck) {
          await deckService.updateDeck(this.editingDeck.pk_deck, payload)
          const idx = this.decks.findIndex(d => d.pk_deck === this.editingDeck.pk_deck)
          if (idx !== -1) this.decks[idx] = { ...this.decks[idx], ...payload }
        } else {
          const res = await deckService.createDeck(payload)
          this.decks.unshift(res.data)
        }
        this.closeForm()
      } catch (err) {
        this.formError = err?.response?.data?.message || err?.message || 'Failed to save deck.'
      } finally {
        this.submitting = false
      }
    },
    async deleteDeck(deck) {
      try {
        await deckService.deleteDeck(deck.pk_deck)
        this.decks = this.decks.filter(d => d.pk_deck !== deck.pk_deck)
      } catch {
        // silently fail
      }
    },
  },
}
</script>

<style scoped src="./decks.css"></style>
