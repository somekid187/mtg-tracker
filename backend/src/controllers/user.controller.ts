import {
  deleteUserService, getUserProfileService, updateUserProfileService,
  changePasswordService, requestPasswordResetService,
  sendFriendRequestService, acceptFriendRequestService, rejectFriendRequestService,
  removeFriendService, getFriendsService, getFriendRequestsService,
  getUserByUsernameService, getUserStatsService, getLeaderboardService,
} from "../services/user.service";

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

export async function getUserStats(req: any, res: any) {
    const userId = req.user.userId;
    const result = await getUserStatsService(userId);
    res.status(200).json({ message: "Stats retrieved successfully", data: result.data });
}

export async function getLeaderboard(_req: any, res: any) {
    const result = await getLeaderboardService();
    res.status(200).json({ message: "Leaderboard retrieved successfully", data: result.data });
}

export async function searchUser(req: any, res: any) {
    const { username } = req.query;
    const result = await getUserByUsernameService(username as string);
    res.status(200).json({ message: "User found", data: result.data });
}

export async function sendFriendRequest(req: any, res: any) {
    const requesterId = req.user.userId;
    const { receiverId } = req.body;
    const result = await sendFriendRequestService(requesterId, receiverId);
    res.status(201).json({ message: "Friend request sent", data: result.data });
}

export async function acceptFriendRequest(req: any, res: any) {
    const userId = req.user.userId;
    const result = await acceptFriendRequestService(req.params.id, userId);
    res.status(200).json({ message: "Friend request accepted", data: result.data });
}

export async function rejectFriendRequest(req: any, res: any) {
    const userId = req.user.userId;
    const result = await rejectFriendRequestService(req.params.id, userId);
    res.status(200).json({ message: "Friend request rejected", data: result.data });
}

export async function removeFriend(req: any, res: any) {
    const userId = req.user.userId;
    const result = await removeFriendService(req.params.id, userId);
    res.status(200).json({ message: "Friend removed", data: result.data });
}

export async function getFriends(req: any, res: any) {
    const userId = req.user.userId;
    const result = await getFriendsService(userId);
    res.status(200).json({ message: "Friends retrieved successfully", data: result.data });
}

export async function getFriendRequests(req: any, res: any) {
    const userId = req.user.userId;
    const result = await getFriendRequestsService(userId);
    res.status(200).json({ message: "Friend requests retrieved successfully", data: result.data });
}