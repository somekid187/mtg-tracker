import axios from 'axios'

const apiURL = import.meta.env.VITE_API_URL || 'http://localhost:3000'

const accessTokenKey = 'accessToken'
const refreshTokenKey = 'refreshToken'

function normalizeToken(value: unknown) {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  if (!trimmed || trimmed === 'undefined' || trimmed === 'null') return null
  return trimmed
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

  getRefreshToken() {
    const token = normalizeToken(localStorage.getItem(refreshTokenKey))
    if (!token) {
      localStorage.removeItem(refreshTokenKey)
    }
    return token
  },

  logout() {
    localStorage.removeItem(accessTokenKey)
    localStorage.removeItem(refreshTokenKey)
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
