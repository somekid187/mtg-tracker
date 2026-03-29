/**
 * This module provides a function to hash passwords using the argon2 algorithm.
 * Code inspired by the readme of the argon2 package: https://www.npmjs.com/package/argon2
 */

import argon2 from 'argon2';
import crypto from 'node:crypto';

const ALGO = "aes-256-gcm";
const KEY = Buffer.from(process.env.AES_KEY as string, "hex");

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

/**
 * Decrypt data encrypted with MySQL AES_ENCRYPT function
 * MySQL uses AES-128-ECB mode by default
 */
export function decryptAES(encrypted: Buffer, key: string): string {
    try {
        // MySQL pads the key to 16 bytes for AES-128
        const keyBuffer = Buffer.alloc(16);
        Buffer.from(key, 'utf8').copy(keyBuffer);

        // MySQL uses AES-128-ECB
        const decipher = crypto.createDecipheriv('aes-128-ecb', keyBuffer, null);
        decipher.setAutoPadding(true);
        
        let decrypted = decipher.update(encrypted);
        decrypted = Buffer.concat([decrypted, decipher.final()]);
        
        return decrypted.toString('utf8');
    } catch (err) {
        console.error('Error decrypting AES:', err);
        throw err;
    }
}



export function encrypt(text: string): string {
  const iv = crypto.randomBytes(12);

  const cipher = crypto.createCipheriv(ALGO, KEY, iv);

  const encrypted = Buffer.concat([
    cipher.update(text, "utf8"),
    cipher.final()
  ]);

  const tag = cipher.getAuthTag();

  const result = Buffer.concat([iv, tag, encrypted]);

  return result.toString("base64");
}

export function decrypt(data: string): string {
  const buffer = Buffer.from(data, "base64");

  const iv = buffer.subarray(0, 12);
  const tag = buffer.subarray(12, 28);
  const encrypted = buffer.subarray(28);

  const decipher = crypto.createDecipheriv(ALGO, KEY, iv) as crypto.DecipherGCM;

  decipher.setAuthTag(tag);

  const decrypted = Buffer.concat([
    decipher.update(encrypted),
    decipher.final()
  ]);

  return decrypted.toString("utf8");
}