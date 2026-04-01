import {
  sendInviteService,
  acceptInviteService,
  declineInviteService,
  cancelInviteService,
  getPendingInvitesService,
  getInvitesByMatchService,
} from "../services/invite.service";

export async function sendInvite(req: any, res: any) {
  const result = await sendInviteService(req);
  res.status(201).json({ message: "Invite sent successfully", data: result.data });
}

export async function acceptInvite(req: any, res: any) {
  const result = await acceptInviteService(req);
  res.status(200).json({ message: "Invite accepted", data: result.data });
}

export async function declineInvite(req: any, res: any) {
  const result = await declineInviteService(req);
  res.status(200).json({ message: "Invite declined", data: result.data });
}

export async function cancelInvite(req: any, res: any) {
  const result = await cancelInviteService(req);
  res.status(200).json({ message: "Invite cancelled", data: result.data });
}

export async function getPendingInvites(req: any, res: any) {
  const result = await getPendingInvitesService(req);
  res.status(200).json({ message: "Pending invites retrieved successfully", data: result.data });
}

export async function getInvitesByMatch(req: any, res: any) {
  const result = await getInvitesByMatchService(req);
  res.status(200).json({ message: "Match invites retrieved successfully", data: result.data });
}
