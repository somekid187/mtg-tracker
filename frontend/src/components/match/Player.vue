<template>
  <div>
    <h3>Add a New Player</h3>
    <form @submit.prevent="onSubmit">
      <label>Name:</label>
      <input type="text" v-model="player.name">

      <label>Starting Life:</label>
      <input type="number" v-model="player.life">

      <button type="submit">Add Player</button>
    </form>
  </div>
</template>

<script>
export default {
  data() {
    return {
      player: {
        name: '',
        life: 20
      }
    };
  },
  methods: {
    onSubmit() {
      this.$emit('add-player', this.player);
      this.player = {
        name: '',
        life: 20
      };
    }
  }
};
</script>