import {
  createInviteCodeService,
  getInviteCodeByIdService,
  getInviteCodeByCodeService,
  expireInviteCodeService,
  deleteInviteCodeService,
  getInviteCodesByMatchService,
} from "../services/inviteCode.service";

export async function createInviteCode(req: any, res: any) {
  const result = await createInviteCodeService(req);
  res.status(201).json({ message: "Invite code created successfully", data: result.data });
}

export async function getInviteCodeById(req: any, res: any) {
  const result = await getInviteCodeByIdService(req.params.id);
  res.status(200).json({ message: "Invite code retrieved successfully", data: result.data });
}

export async function getInviteCodeByCode(req: any, res: any) {
  const result = await getInviteCodeByCodeService(req.params.code);
  res.status(200).json({ message: "Invite code retrieved successfully", data: result.data });
}

export async function expireInviteCode(req: any, res: any) {
  const result = await expireInviteCodeService(req.params.id);
  res.status(200).json({ message: "Invite code expired successfully", data: result.data });
}

export async function deleteInviteCode(req: any, res: any) {
  const result = await deleteInviteCodeService(req.params.id);
  res.status(200).json({ message: "Invite code deleted successfully", data: result.data });
}

export async function getInviteCodesByMatch(req: any, res: any) {
  const result = await getInviteCodesByMatchService(req.params.matchId);
  res.status(200).json({ message: "Invite codes retrieved successfully", data: result.data });
}
