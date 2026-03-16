import { deleteUserService, getUserProfileService, updateUserProfileService, changePasswordService, requestPasswordResetService } from "../services/user.service";

export async function getUserProfile(req: any, res: any) {
    const userId = (req as any).user.userId;
    const result = await getUserProfileService(userId);
    res.status(200).json({ message: "User profile retrieved successfully", data: result.data });
}

export async function updateUserProfile(req: any, res: any) {
    const userId = (req as any).user.userId;
    const result = await updateUserProfileService(userId, req.body);
    res.status(200).json({ message: "User profile updated successfully", data: result.data });
}

export async function deleteUserProfile(req: any, res: any) {
    const userId = (req as any).user.userId;
    const result = await deleteUserService(userId);
    res.status(200).json({ message: "User profile deleted successfully", data: result.data });
}

export async function changePassword(req: any, res: any) {
    const result = await changePasswordService(req.body);
    res.status(200).json({ message: "Password changed successfully", data: result.data });
}

export async function requestPasswordReset(req:any, res:any) {
    const result = await requestPasswordResetService(req);
    res.status(200).json({ message: "Password reset requested successfully"});
}