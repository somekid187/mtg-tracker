import {
  createPlayerService,
  getPlayerByIdService,
  updatePlayerService,
  deletePlayerService,
  getPlayersByMatchService,
} from "../services/player.service";

export async function createPlayer(req: any, res: any) {
  const result = await createPlayerService(req);
  res.status(201).json({ message: "Player created successfully", data: result.data });
}

export async function getPlayerById(req: any, res: any) {
  const result = await getPlayerByIdService(req.params.id);
  res.status(200).json({ message: "Player retrieved successfully", data: result.data });
}

export async function updatePlayer(req: any, res: any) {
  const result = await updatePlayerService(req.params.id, req.body);
  res.status(200).json({ message: "Player updated successfully", data: result.data });
}

export async function deletePlayer(req: any, res: any) {
  const result = await deletePlayerService(req.params.id);
  res.status(200).json({ message: "Player deleted successfully", data: result.data });
}

export async function getPlayersByMatch(req: any, res: any) {
  const result = await getPlayersByMatchService(req.params.matchId);
  res.status(200).json({ message: "Players retrieved successfully", data: result.data });
}
