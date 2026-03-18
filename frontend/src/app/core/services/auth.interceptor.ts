import { Injectable, inject } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, switchMap, throwError, from } from 'rxjs';
import { AuthService } from './auth.service';
import { Router } from '@angular/router';

/**
 * This class implements an HTTP interceptor that automatically adds the access token 
 * to outgoing requests and handles 401 errors by attempting to refresh the token. 
 * If the refresh fails, it clears the tokens and redirects the user to the login page.
 */
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  private authService = inject(AuthService);
  private router = inject(Router);

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const accessToken = this.authService.getAccessToken();

    // Clone the request and add the token to the header
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
        this.authService.clearTokens();
        this.router.navigate(['/login']);
        return throwError(() => refreshError);
      })
    );
  }
}