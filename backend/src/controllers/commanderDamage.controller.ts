import {
  createCommanderDamageService,
  getCommanderDamageByIdService,
  updateCommanderDamageService,
  deleteCommanderDamageService,
  getCommanderDamageByMatchService,
} from "../services/commanderDamage.service";

export async function createCommanderDamage(req: any, res: any) {
  const result = await createCommanderDamageService(req);
  res.status(201).json({ message: "Commander damage created successfully", data: result.data });
}

export async function getCommanderDamageById(req: any, res: any) {
  const result = await getCommanderDamageByIdService(req.params.id);
  res.status(200).json({ message: "Commander damage retrieved successfully", data: result.data });
}

export async function updateCommanderDamage(req: any, res: any) {
  const result = await updateCommanderDamageService(req.params.id, req.body);
  res.status(200).json({ message: "Commander damage updated successfully", data: result.data });
}

export async function deleteCommanderDamage(req: any, res: any) {
  const result = await deleteCommanderDamageService(req.params.id);
  res.status(200).json({ message: "Commander damage deleted successfully", data: result.data });
}

export async function getCommanderDamageByMatch(req: any, res: any) {
  const result = await getCommanderDamageByMatchService(req.params.matchId);
  res.status(200).json({ message: "Commander damage records retrieved successfully", data: result.data });
}
