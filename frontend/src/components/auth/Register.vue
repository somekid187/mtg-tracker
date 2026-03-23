<template>
	<div>
		<h2>Register</h2>
		<form @submit.prevent="onSubmit">
			<label>Username:</label>
			<input type="text" v-model="username" required>

			<label>Email:</label>
			<input type="email" v-model="email" required>

			<label>Password:</label>
			<input type="password" v-model="password" required>

			<button type="submit" :disabled="isSubmitting">
				{{ isSubmitting ? 'Registering...' : 'Register' }}
			</button>
		</form>

		<p v-if="errorMessage">{{ errorMessage }}</p>
		<p>Already have an account? <router-link to="/login">Login here</router-link>.</p>
	</div>
</template>

<script>
import authService from '../../services/auth.service';

export default {
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
