import axios from 'axios'

const apiURL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:3000'

const accessTokenKey = 'accessToken'
const refreshTokenKey = 'refreshToken'
const usernameKey = 'username'

function normalizeToken(value: unknown) {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  if (!trimmed || trimmed === 'undefined' || trimmed === 'null') return null
  return trimmed
}

function decodeJwtPayload(token: string): any {
  try {
    const base64 = token.split('.')[1]?.replace(/-/g, '+').replace(/_/g, '/') ?? ''
    return JSON.parse(atob(base64))
  } catch {
    return null
  }
}

function extractAuthData(payload: any) {
  if (payload?.data && typeof payload.data === 'object') {
    return payload.data
  }
  return payload
}

const authService = {
  login(credentials: { email: string; password: string }) {
    return axios
      .post(`${apiURL}/auth/login`, credentials, { withCredentials: true })
      .then((response: any) => {
        const authData = extractAuthData(response.data)
        const accessToken = normalizeToken(authData?.accessToken)
        const refreshToken = normalizeToken(authData?.refreshToken)

        if (!accessToken || !refreshToken) {
          throw new Error('Login response missing tokens')
        }

        localStorage.setItem(accessTokenKey, accessToken)
        localStorage.setItem(refreshTokenKey, refreshToken)
        if (authData?.username) {
          localStorage.setItem(usernameKey, authData.username)
        }
        return response.data
      })
      .catch((error: unknown) => {
        console.error('Login failed:', error)
        throw error
      })
  },

  register(userInfo: { username: string; email: string; password: string }) {
    return axios
      .post(`${apiURL}/auth/register`, userInfo)
      .then((response: any) => response.data)
      .catch((error: unknown) => {
        console.error('Registration failed:', error)
        throw error
      })
  },

  activateAccount(token: string) {
    return axios
      .put(`${apiURL}/auth/activate`, { token })
      .then((response: any) => response.data)
      .catch((error: unknown) => {
        console.error('Activation failed:', error)
        throw error
      })
  },

  getAccessToken() {
    const token = normalizeToken(localStorage.getItem(accessTokenKey))
    if (!token) {
      localStorage.removeItem(accessTokenKey)
    }
    return token
  },

  getUserId(): number | null {
    const token = this.getAccessToken()
    if (!token) return null
    const payload = decodeJwtPayload(token)
    return payload?.userId ?? null
  },

  getUsername(): string | null {
    // First try localStorage (set on login, always fresh)
    const stored = localStorage.getItem(usernameKey)
    if (stored) return stored
    // Fallback: decode from JWT (works if token has username claim)
    const token = this.getAccessToken()
    if (!token) return null
    const payload = decodeJwtPayload(token)
    return payload?.username ?? null
  },

  getRefreshToken() {
    const token = normalizeToken(localStorage.getItem(refreshTokenKey))
    if (!token) {
      localStorage.removeItem(refreshTokenKey)
    }
    return token
  },

  isAuthenticated(): boolean {
    return !!this.getAccessToken()
  },

  logout() {
    localStorage.removeItem(accessTokenKey)
    localStorage.removeItem(refreshTokenKey)
    localStorage.removeItem(usernameKey)
  },

  refreshToken() {
    const refreshToken = this.getRefreshToken()
    if (!refreshToken) {
      return Promise.reject(new Error('No refresh token available'))
    } else {
      return axios
        .post(`${apiURL}/auth/refresh`, { refreshToken }, { withCredentials: true })
        .then((response: any) => {
          const authData = extractAuthData(response.data)
          const nextAccessToken = normalizeToken(authData?.accessToken)
          const nextRefreshToken = normalizeToken(authData?.refreshToken)

          if (!nextAccessToken) {
            throw new Error('Refresh response missing access token')
          }

          localStorage.setItem(accessTokenKey, nextAccessToken)
          if (nextRefreshToken) {
            localStorage.setItem(refreshTokenKey, nextRefreshToken)
          }

          return nextAccessToken
        })
        .catch((error: unknown) => {
          console.error('Token refresh failed:', error)
          this.logout()
          throw error
        })
    }
  },
}

export default authService
