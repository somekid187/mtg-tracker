import { createRouter, createWebHistory } from 'vue-router'
import authService from '../services/auth.service'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/login', component: () => import('../components/auth/Login.vue'), meta: { public: true } },
    { path: '/register', component: () => import('../components/auth/Register.vue'), meta: { public: true } },
    { path: '/activate', component: () => import('../components/auth/Activate.vue'), meta: { public: true } },
    { path: '/match', component: () => import('../components/match/Match.vue') },
    { path: '/match/join', component: () => import('../components/match/JoinMatch.vue') },
    { path: '/match/:id', component: () => import('../components/match/MatchField.vue') },
    { path: '/', component: () => import('../components/home/Home.vue') },
    { path: '/dashboard', component: () => import('../components/dashboard/Dashboard.vue') },
  ],
})

router.beforeEach(async (to) => {
  const isPublicRoute = to.matched.some((record) => record.meta.public)
  if (isPublicRoute) {
    return true
  }

  const accessToken = authService.getAccessToken()
  if (accessToken) {
    return true
  }

  const refreshToken = authService.getRefreshToken()
  if (!refreshToken) {
    return { path: '/login' }
  }

  try {
    await authService.refreshToken()
    return true
  } catch {
    authService.logout()
    return { path: '/login' }
  }
})

export default router
