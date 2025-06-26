export enum EntitlementStatus {
	ISSUED = "ISSUED",
	ACTIVE = "ACTIVE",
	REDEEMED = "REDEEMED",
	EXPIRED = "EXPIRED",
	CANCELLED = "CANCELLED",
}

export const validTransitions: Record<EntitlementStatus, EntitlementStatus[]> =
	{
		[EntitlementStatus.ISSUED]: [
			EntitlementStatus.ACTIVE,
			EntitlementStatus.CANCELLED,
		],
		[EntitlementStatus.ACTIVE]: [
			EntitlementStatus.REDEEMED,
			EntitlementStatus.EXPIRED,
			EntitlementStatus.CANCELLED,
		],
		[EntitlementStatus.REDEEMED]: [], // Terminal state
		[EntitlementStatus.EXPIRED]: [], // Terminal state
		[EntitlementStatus.CANCELLED]: [], // Terminal state
	};

export function canTransition(
	from: EntitlementStatus,
	to: EntitlementStatus,
): boolean {
	return validTransitions[from]?.includes(to) || false;
}

export function validateStatusTransition(
	currentStatus: string,
	newStatus: string,
): boolean {
	const from = currentStatus as EntitlementStatus;
	const to = newStatus as EntitlementStatus;

	if (
		!Object.values(EntitlementStatus).includes(from) ||
		!Object.values(EntitlementStatus).includes(to)
	) {
		return false;
	}

	return canTransition(from, to);
}
