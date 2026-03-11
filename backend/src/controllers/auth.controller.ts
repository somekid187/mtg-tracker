import { registerService, loginService, tokenService } from "../services/auth.service";

export async function register(req: any, res: any) {
    const result = await registerService(req);
    res.status(201).json({ message: "User registered successfully", data: result.data });
}

export async function login(req: any, res: any) {
    const result = await loginService(req);
    res.status(200).json({ message: "User logged in successfully", data: result.data });
}

export async function token(req:any, res: any) {
    const result = await tokenService(req);
    res.status(200).json({ token: result.token })
}
