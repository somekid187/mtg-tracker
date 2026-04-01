import {
  createEventService,
  getEventByIdService,
  getEventsByUserService,
  updateEventService,
  deleteEventService,
  addMatchToEventService,
  removeMatchFromEventService,
  getEventStatsService,
} from "../services/event.service";

export async function createEvent(req: any, res: any) {
  const result = await createEventService(req);
  res.status(201).json({ message: "Event created successfully", data: result.data });
}

export async function getEventById(req: any, res: any) {
  const result = await getEventByIdService(req.params.id, req.user.userId);
  res.status(200).json({ message: "Event retrieved successfully", data: result.data });
}

export async function getMyEvents(req: any, res: any) {
  const result = await getEventsByUserService(req.user.userId);
  res.status(200).json({ message: "Events retrieved successfully", data: result.data });
}

export async function updateEvent(req: any, res: any) {
  const result = await updateEventService(req.params.id, req.user.userId, req.body);
  res.status(200).json({ message: "Event updated successfully", data: result.data });
}

export async function deleteEvent(req: any, res: any) {
  const result = await deleteEventService(req.params.id, req.user.userId);
  res.status(200).json({ message: "Event deleted successfully", data: result.data });
}

export async function addMatchToEvent(req: any, res: any) {
  const result = await addMatchToEventService(req.params.id, req.body.matchId, req.user.userId);
  res.status(200).json({ message: "Match added to event", data: result.data });
}

export async function removeMatchFromEvent(req: any, res: any) {
  const result = await removeMatchFromEventService(req.params.id, req.params.matchId, req.user.userId);
  res.status(200).json({ message: "Match removed from event", data: result.data });
}

export async function getEventStats(req: any, res: any) {
  const result = await getEventStatsService(req.params.id);
  res.status(200).json({ message: "Event stats retrieved", data: result.data });
}
