import { registerService, loginService, refreshService, logoutService, activateService } from "../services/auth.service";

export async function register(req: any, res: any) {
    const result = await registerService(req);
    res.status(201).json({ message: "User registered successfully", data: result.data });
}

export async function login(req: any, res: any) {
    const result = await loginService(req);
    res.status(200).json({ message: "User logged in successfully", data: result.data });
}

export async function refresh(req:any, res: any) {
    const result = await refreshService(req);
    res.status(200).json({ message: "Token refreshed successfully", data: result.data });
}

export async function logout(req: any, res: any) {
    const result = await logoutService(req);
    res.status(200).json({ message: "Logged out successfully", data: result.data });
}

export async function activate(req: any, res: any) {
    const result = await activateService(req);
    res.status(200).json({ message: "Account activated successfully", data: result.data });
}
