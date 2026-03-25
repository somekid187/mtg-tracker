import {
  createMatchService,
  joinMatchService,
  leaveMatchService,
  getMatchByIdService,
  updateMatchService,
  deleteMatchService,
  sendMatchInviteService,
} from "../services/match.service";

export async function createMatch(req: any, res: any) {
  const result = await createMatchService(req);
  res
    .status(201)
    .json({ message: "Match created successfully", data: result.data });
}

export async function joinMatch(req: any, res: any) {
  const result = await joinMatchService(req);
  res
    .status(200)
    .json({ message: "Joined match successfully", data: result.data });
}

export async function leaveMatch(req: any, res: any) {
  const result = await leaveMatchService(req);
  res
    .status(200)
    .json({ message: "Left match successfully", data: result.data });
}

export async function getMatchById(req: any, res: any) {
  const result = await getMatchByIdService(req.params.id);
  res
    .status(200)
    .json({ message: "Match retrieved successfully", data: result.data });
}

export async function updateMatch(req: any, res: any) {
  const result = await updateMatchService(req.params.id, req.body);
  res
    .status(200)
    .json({ message: "Match updated successfully", data: result.data });
}

export async function deleteMatch(req: any, res: any) {
  const result = await deleteMatchService(req.params.id);
  res
    .status(200)
    .json({ message: "Match deleted successfully", data: result.data });
}

export async function sendMatchInvite(req: any, res: any) {
  await sendMatchInviteService(req);
  res.status(200).json({ message: "Invite sent successfully" });
}
