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
				<div class="form-group">
					<label class="form-label">Password</label>
					<input class="form-input" type="password" v-model="password" placeholder="••••••••" required>
				</div>
				<button class="btn-primary" type="submit" :disabled="isSubmitting">
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
			isSubmitting: false,
			errorMessage: ''
		};
	},
	methods: {
		onSubmit() {
			this.errorMessage = '';
			this.isSubmitting = true;

			authService.register({
				username: this.username,
				email: this.email,
				password: this.password
			})
				.then((response) => {
					console.log('Registration successful', response);
					this.$router.push('/login');
				})
				.catch((error) => {
					console.error('Registration failed', error);
					this.errorMessage = 'Registration failed. Please try again.';
				})
				.finally(() => {
					this.isSubmitting = false;
				});
		}
	}
};
</script>

<style scoped src="./auth.css"></style>
