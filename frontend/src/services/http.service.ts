import axios from "axios";
import authService from "./auth.service";

const api = axios.create({
  baseURL: import.meta.env.VITE_BACKEND_URL || "http://localhost:3000",
  withCredentials: true, // Include cookies in requests
});

// Shared promise for any in-flight token refresh.
// All concurrent 401s wait on this instead of each spawning their own rotation.
let refreshPromise: Promise<string> | null = null;

// Add a request interceptor to include the access token in headers
api.interceptors.request.use(
  (config: any) => {
    const accessToken = authService.getAccessToken();
    if (accessToken) {
      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${accessToken}`;
    }
    return config;
  },
  (error: unknown) => {
    return Promise.reject(error);
  }
);

// Add a response interceptor
api.interceptors.response.use(
  (response: any) => {
    return response;
  },
  async (error: any) => {
    const originalRequest = error?.config;

    if (error?.response?.status === 401 && originalRequest && !originalRequest._retry) {
      originalRequest._retry = true;
      try {
        // If another request already started a refresh, reuse that promise
        // so we never call refreshToken() more than once concurrently.
        if (!refreshPromise) {
          refreshPromise = authService.refreshToken().finally(() => {
            refreshPromise = null;
          });
        }
        const newAccessToken = await refreshPromise;
        originalRequest.headers = originalRequest.headers || {};
        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        await authService.logout();
        window.location.href = "/login";
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export default api;