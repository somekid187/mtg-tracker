import { getUserProfileService } from "../services/user.service";

export async function getUserProfile(req: any, res: any) {
    const userId = (req as any).user.userId;
    const result = await getUserProfileService(userId);
    res.status(200).json({ message: "User profile retrieved successfully", data: result.data });
}