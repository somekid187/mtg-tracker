export function validatePassword(
  password: string,
  minLength: number = 8,
  requireUppercase: boolean = true,
  requireLowercase: boolean = true,
  requireDigit: boolean = true,
  requireSpecialChar: boolean = true,
): { isValid: boolean; message: string } {
  const errors: string[] = [];

  if (password.length < minLength) {
    errors.push(`Password must be at least ${minLength} characters long`);
  }

  if (requireUppercase && !/[A-Z]/.test(password)) {
    errors.push("Password must contain at least one uppercase letter");
  }

  if (requireLowercase && !/[a-z]/.test(password)) {
    errors.push("Password must contain at least one lowercase letter");
  }

  if (requireDigit && !/\d/.test(password)) {
    errors.push("Password must contain at least one digit");
  }

  if (requireSpecialChar && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push(
      'Password must contain at least one of the following special characters: !@#$%^&*(),.?":{}|<>',
    );
  }

  return {
    isValid: errors.length === 0,
    message: errors.join("; "),
  };
}

export function validateEmail(email: string): {
  isValid: boolean;
  message: string;
} {
  const emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i;
  return {
    isValid: emailRegex.test(email),
    message: emailRegex.test(email) ? "" : "Invalid email format",
  };
}

export function validateUsername(
  username: string,
  minLength: number = 3,
  maxLength: number = 30,
): { isValid: boolean; message: string } {
    const errors: string[] = [];

    if (username.length < minLength) {
        errors.push(`Username must be at least ${minLength} characters long`);
    }

    if (username.length > maxLength) {
        errors.push(`Username must be less than ${maxLength} characters long`);
    }

    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
        errors.push("Username can only contain letters, numbers, and underscores");
    }

    return {
        isValid: errors.length === 0,
        message: errors.join("; "),
    };
}
