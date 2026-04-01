<template>
	<div class="auth-page">
		<Header />
		<div class="auth-body">
			<div class="auth-card">
			<h2 class="auth-title">Register</h2>
			<form class="auth-form" @submit.prevent="onSubmit">
				<div class="form-group">
					<label class="form-label">Username</label>
					<input class="form-input" type="text" v-model="username" placeholder="your_username" required>
				</div>
				<div class="form-group">
					<label class="form-label">Email</label>
					<input class="form-input" type="email" v-model="email" placeholder="your@email.com" required>
				</div>
				<div class="form-group password-group">
					<label class="form-label">Password</label>
					<input class="form-input" type="password" v-model="password" placeholder="••••••••" required
						@focus="passwordFocused = true" @blur="passwordFocused = false">
					<ul v-if="password.length > 0 && passwordFocused" class="password-requirements">
						<li :class="hasMinLength ? 'requirement met' : 'requirement unmet'">At least 8 characters</li>
						<li :class="hasUppercase ? 'requirement met' : 'requirement unmet'">One uppercase letter</li>
						<li :class="hasLowercase ? 'requirement met' : 'requirement unmet'">One lowercase letter</li>
						<li :class="hasDigit ? 'requirement met' : 'requirement unmet'">One digit</li>
						<li :class="hasSpecialChar ? 'requirement met' : 'requirement unmet'">One special character</li>
					</ul>
				</div>
				<div class="form-group">
					<label class="form-label">Confirm Password</label>
					<input class="form-input" type="password" v-model="confirmPassword" placeholder="••••••••" required>
					<p v-if="confirmPassword.length > 0 && !passwordsMatch" class="password-mismatch">Passwords do not match</p>
				</div>
				<button class="btn-primary" type="submit" :disabled="isSubmitting || !passwordValid">
					{{ isSubmitting ? 'Registering...' : 'Register' }}
				</button>
			</form>
			<p v-if="errorMessage" class="auth-message">{{ errorMessage }}</p>
				<p class="auth-footer">Already have an account? <router-link to="/login">Login here</router-link>.</p>
			</div>
		</div>
	</div>
</template>

<script>
import authService from '../../services/auth.service';
import Header from '../shared/Header.vue';

export default {
	components: { Header },
	data() {
		return {
			username: '',
			email: '',
			password: '',
			confirmPassword: '',
			isSubmitting: false,
			errorMessage: '',
			passwordFocused: false
		};
	},
	computed: {
		hasMinLength() { return this.password.length >= 8; },
		hasUppercase() { return /[A-Z]/.test(this.password); },
		hasLowercase() { return /[a-z]/.test(this.password); },
		hasDigit() { return /\d/.test(this.password); },
		hasSpecialChar() { return /[!@#$%^&*(),.?":{}|<>]/.test(this.password); },
		passwordsMatch() { return this.password === this.confirmPassword && this.confirmPassword.length > 0; },
		passwordValid() {
			return this.hasMinLength && this.hasUppercase && this.hasLowercase
				&& this.hasDigit && this.hasSpecialChar && this.passwordsMatch;
		}
	},
	methods: {
		onSubmit() {
			if (!this.passwordValid) return;
			this.errorMessage = '';
			this.isSubmitting = true;

			authService.register({
				username: this.username,
				email: this.email,
				password: this.password
			})
				.then((response) => {
					console.log('Registration successful', response);
					this.$router.push('/login?registeringSuccess=true');
				})
				.catch((error) => {
					console.error('Registration failed', error);
					this.errorMessage = error?.response?.data?.message || error?.message || 'Registration failed. Please try again.';
				})
				.finally(() => {
					this.isSubmitting = false;
				});
		}
	}
};
</script>

<style scoped src="./auth.css"></style>
