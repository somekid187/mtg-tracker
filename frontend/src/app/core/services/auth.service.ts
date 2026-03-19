import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

interface Response {
  success: boolean;
  data: any;
  message?: string;
  error?: any;
}
  
@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private http = inject(HttpClient);
  private apiUrl = 'http://localhost:3000/auth';

  private accessTokenKey = 'accessToken';
  private refreshTokenKey = 'refreshToken';

  setTokens(accessToken: string, refreshToken: string) {
    localStorage.setItem(this.accessTokenKey, accessToken);
    localStorage.setItem(this.refreshTokenKey, refreshToken);
  }

  getAccessToken(): string | null {
    return localStorage.getItem(this.accessTokenKey);
  }

  getRefreshToken(): string | null {
    return localStorage.getItem(this.refreshTokenKey);
  }

  clearTokens() {
    localStorage.removeItem(this.accessTokenKey);
    localStorage.removeItem(this.refreshTokenKey);
  }

  async login(email: string, password: string) {
    try {
      const response: Response = await firstValueFrom(
        this.http.post<Response>(`${this.apiUrl}/login`, { email, password },{ withCredentials: true }),
      );
      this.setTokens(response.data.accessToken, response.data.refreshToken);
      return response;
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  }

  async register(username: string, email: string, password: string) {
    try {
      const response: Response = await firstValueFrom(
        this.http.post<Response>(`${this.apiUrl}/register`, { username, email, password }),
      );
      return response;
    } catch (error) {
      console.error('Registration failed:', error);
      throw error;
    }
  }

  async refreshToken() {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }

    try {
      const response: any = await firstValueFrom(
        this.http.post(`${this.apiUrl}/refresh`, { refreshToken }, { withCredentials: true }),
      );
      
      if (response && response.data && response.data.accessToken && response.data.refreshToken) {
        this.setTokens(response.data.accessToken, response.data.refreshToken);
        return response;
      } else {
        throw new Error('Invalid refresh response: ' + JSON.stringify(response));
      }
    } catch (error: any) {
      // Check for specific error codes
      if (error.error && error.error.code === 'VALIDATION_TOKEN_ALREADY_REVOKED') {
        // This is not actually an error - the token is already in the desired state
      } else {
        console.error('Token refresh failed:', error);
      }
      this.clearTokens();
      throw new Error('Token refresh failed: ' + (error.message || 'Unknown error'));
    }
  }

  async logout() {
    await firstValueFrom(
      this.http.post(`${this.apiUrl}/logout`, { refreshToken: this.getRefreshToken() }),
    );

    this.clearTokens();
  }
}
