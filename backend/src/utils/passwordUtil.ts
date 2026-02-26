/**
 * This module provides a function to hash passwords using the argon2 algorithm.
 * Code inspired by the readme of the argon2 package: https://www.npmjs.com/package/argon2
 */

import argon2 from 'argon2';

export async function hashPassword(password:string) :Promise<string> {
    try {
        // Hash the password using argon2
        const hash = await argon2.hash(password);
        return hash;
    } catch (err) {
        // Handle error
        console.error('Error hashing password:', err);
        throw err;
    }
}

export async function verifyPassword(hash:string, password:string): Promise<boolean> {
    try {
        if( await argon2.verify(hash, password) ) {
            // Password match
            return true;
        } else {
            // Password did not match
            return false;
        }
    } catch (err) {
        // Handle error        
        console.error('Error verifying password:', err);
        throw err;
    }
}