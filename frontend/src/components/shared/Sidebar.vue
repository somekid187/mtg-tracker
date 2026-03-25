<template>
    <nav class="sidebar">
        <div class="sidebar-header">
            <RouterLink to="/dashboard" class="logo-link">
                <img src="/public/assets/mtglogo.png" alt="MTG Tracker Logo" class="sidebar-logo" />
            </RouterLink>
        </div>
        <ul class="sidebar-nav">
            <li>
                <RouterLink to="/dashboard" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/public/assets/games.png" alt="Controller Icon" class="nav-icon" />
                    <span>Games</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/friends" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/public/assets/friends.png" alt="Friends Icon" class="nav-icon" />
                    <span>Friends</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/stats" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/public/assets/stats.png" alt="Stats Icon" class="nav-icon" />
                    <span>Stats</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/settings" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/public/assets/settings.png" alt="Settings Icon" class="nav-icon" />
                    <span>Settings</span>
                </RouterLink>
            </li>
        </ul>
        <div class="sidebar-footer">
            <button class="logout-btn" @click="handleLogout">Logout</button>
        </div>
    </nav>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useRouter } from 'vue-router';
import authService from '../../services/auth.service';

export default defineComponent({
    name: 'Sidebar',
    setup() {
        const router = useRouter();

        function handleLogout() {
            authService.logout();
            router.push('/');
        }

        return { handleLogout };
    }
});
</script>

<style scoped src="./shared.css">
</style>
