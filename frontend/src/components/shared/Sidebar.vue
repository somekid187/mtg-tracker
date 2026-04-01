<template>
    <nav class="sidebar">
        <div class="sidebar-header">
            <RouterLink to="/dashboard" class="logo-link">
                <img src="/assets/mtglogo.png" alt="MTG Tracker Logo" class="sidebar-logo" />
            </RouterLink>
        </div>
        <ul class="sidebar-nav">
            <li>
                <RouterLink to="/dashboard" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/assets/games.png" alt="Controller Icon" class="nav-icon" />
                    <span>Games</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/friends" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/assets/friends.png" alt="Friends Icon" class="nav-icon" />
                    <span>Friends</span>
                    <span v-if="totalNotifications > 0" class="nav-badge">{{ totalNotifications }}</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/stats" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/assets/stats.png" alt="Stats Icon" class="nav-icon" />
                    <span>Stats</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/event" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/assets/event.png" alt="Events Icon" class="nav-icon" />
                    <span>Events</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/decks" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/assets/cards.png" alt="Decks Icon" class="nav-icon" />
                    <span>Decks</span>
                </RouterLink>
            </li>
            <li>
                <RouterLink to="/settings" class="nav-link" active-class="active">
                    <div class="left-rectangle"></div>
                    <img src="/assets/settings.png" alt="Settings Icon" class="nav-icon" />
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
import { defineComponent, computed, onMounted, onBeforeUnmount } from 'vue';
import { useRouter } from 'vue-router';
import authService from '../../services/auth.service';
import { pendingFriendRequests, pendingGameInvites, refreshNotifications } from '../../utils/notifications';

export default defineComponent({
    name: 'Sidebar',
    setup() {
        const router = useRouter();

        const totalNotifications = computed(() => pendingFriendRequests.value + pendingGameInvites.value);

        let pollTimer: ReturnType<typeof setInterval> | null = null;

        async function handleLogout() {
            await authService.logout();
            router.push('/');
        }

        onMounted(async () => {
            await refreshNotifications();
            pollTimer = setInterval(refreshNotifications, 30_000);
        });

        onBeforeUnmount(() => {
            if (pollTimer) clearInterval(pollTimer);
        });

        return { handleLogout, totalNotifications };
    }
});
</script>

<style scoped src="./shared.css">
</style>
