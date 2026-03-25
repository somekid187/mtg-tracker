import {
  createGuestService,
  getGuestByIdService,
  updateGuestService,
  deleteGuestService,
} from "../services/guest.service";

export async function createGuest(req: any, res: any) {
  const result = await createGuestService(req);
  res.status(201).json({ message: "Guest created successfully", data: result.data });
}

export async function getGuestById(req: any, res: any) {
  const result = await getGuestByIdService(req.params.id);
  res.status(200).json({ message: "Guest retrieved successfully", data: result.data });
}

export async function updateGuest(req: any, res: any) {
  const result = await updateGuestService(req.params.id, req.body);
  res.status(200).json({ message: "Guest updated successfully", data: result.data });
}

export async function deleteGuest(req: any, res: any) {
  const result = await deleteGuestService(req.params.id);
  res.status(200).json({ message: "Guest deleted successfully", data: result.data });
}
