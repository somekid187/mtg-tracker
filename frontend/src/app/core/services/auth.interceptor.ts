import { Injectable, inject } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, switchMap, throwError, from, of } from 'rxjs';
import { AuthService } from './auth.service';
import { Router } from '@angular/router';

/**
 * This class implements an HTTP interceptor that automatically adds the access token 
 * to outgoing requests and handles token refresh. It proactively checks for expired 
 * access tokens and attempts to refresh them before making API calls.
 */
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  private authService = inject(AuthService);
  private router = inject(Router);

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const accessToken = this.authService.getAccessToken();
    const refreshToken = this.authService.getRefreshToken();

    // If we have a refresh token but no access token, try to refresh first
    if (!accessToken && refreshToken && !request.url.includes('/auth/refresh')) {
      return from(this.authService.refreshToken()).pipe(
        switchMap(() => {
          const newAccessToken = this.authService.getAccessToken();
          if (newAccessToken) {
            // Add the new access token to the request
            request = request.clone({
              setHeaders: {
                Authorization: `Bearer ${newAccessToken}`,
              },
            });
            return next.handle(request);
          }
          // If refresh failed, clear tokens and redirect to login
          this.authService.clearTokens();
          this.router.navigate(['/login']);
          return throwError(() => new Error('Session expired'));
        }),
        catchError((refreshError) => {
          console.error('Token refresh failed:', refreshError);
          this.authService.clearTokens();
          this.router.navigate(['/login']);
          return throwError(() => refreshError);
        })
      );
    }

    // If we have an access token, add it to the request
    if (accessToken) {
      request = request.clone({
        setHeaders: {
          Authorization: `Bearer ${accessToken}`,
        },
      });
    }

    // Handle the request and catch errors
    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401 && !request.url.includes('/auth/refresh')) {
          return this.handle401Error(request, next);
        }
        return throwError(() => error);
      })
    );
  }

  // Handle 401 errors by attempting to refresh the token
  private handle401Error(request: HttpRequest<any>, next: HttpHandler) {
    return from(this.authService.refreshToken()).pipe(
      switchMap(() => {
        const newAccessToken = this.authService.getAccessToken();
        if (newAccessToken) {
          request = request.clone({
            setHeaders: {
              Authorization: `Bearer ${newAccessToken}`,
            },
          });
          return next.handle(request);
        }
        return throwError(() => new Error('Session expired'));
      }),
      catchError((refreshError) => {
        console.error('Token refresh failed in 401 handler:', refreshError);
        this.authService.clearTokens();
        this.router.navigate(['/login']);
        return throwError(() => refreshError);
      })
    );
  }
}