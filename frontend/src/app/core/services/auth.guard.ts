import { Injectable, inject } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class AuthGuard implements CanActivate {
  private authService = inject(AuthService);
  private router = inject(Router);

  async canActivate(): Promise<boolean> {
    const accessToken = this.authService.getAccessToken();
    const refreshToken = this.authService.getRefreshToken();

    // If we have a valid access token, allow access
    if (accessToken) {
      return true;
    }

    // If we have a refresh token but no access token, try to refresh
    if (refreshToken) {
      try {
        await this.authService.refreshToken();
        // After successful refresh, we should have a new access token
        if (this.authService.getAccessToken()) {
          return true;
        }
      } catch (error: any) {
        // If refresh fails, clear tokens (already done in refreshToken method)
      }
    }

    // No valid tokens, redirect to login
    this.router.navigate(['/login']);
    return false;
  }
}