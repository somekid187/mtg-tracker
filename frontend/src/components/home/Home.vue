<template>
    <Header />
    <!-- main -->
    <h1>
        Hello world!
    </h1>
    <p><a href="/dashboard">Learn more</a></p>
    <!-- Footer -->
</template>
<script lang="ts">
import { defineComponent } from 'vue';
import Header from '../shared/Header.vue';

export default defineComponent({
    name: 'Home',
    components: {
        Header
    }
});
</script>