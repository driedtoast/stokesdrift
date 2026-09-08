import { items, locations, currentTeam } from '../store';
import { fetchItems, fetchLocations } from './actions';
import type { Item, ItemLocation } from './store';

const API_BASE = import.meta.env.VITE_API_URL || '/api';

async function fetchItemLocations(teamId: string, itemId: string): Promise<ItemLocation[]> {
  const token = localStorage.getItem('stokedrift_token');
  const res = await fetch(`${API_BASE}/items/${itemId}/locations?teamId=${teamId}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) return [];
  const data = await res.json();
  return data.locations ?? [];
}

function escapeCsvField(field: string): string {
  if (field.includes(',') || field.includes('"') || field.includes('\n')) {
    return `"${field.replace(/"/g, '""')}"`;
  }
  return field;
}

export function generateCsv(itemList: Item[], locationList: { id: string; name: string; address: string }[]): string {
  const lines: string[] = [];

  // Header
  lines.push('Name,Details,Custom Fields,Latitude,Longitude,Address,Last Seen,Created At');

  for (const item of itemList) {
    const name = escapeCsvField(item.name);
    const details = escapeCsvField(item.details || '');
    const fields = escapeCsvField(
      Object.entries(item.customFields || {})
        .map(([k, v]) => `${k}: ${v}`)
        .join('; ')
    );

    // Find latest location for this item
    const latestLoc = (item as any).latestLocation as
      | { latitude: number | null; longitude: number | null; address: string; timestamp: string }
      | undefined;
    const lat = latestLoc?.latitude?.toString() ?? '';
    const lon = latestLoc?.longitude?.toString() ?? '';
    const address = escapeCsvField(latestLoc?.address ?? '');
    const lastSeen = latestLoc?.timestamp ?? '';
    const createdAt = item.createdAt;

    lines.push(`${name},${details},${fields},${lat},${lon},${address},${lastSeen},${createdAt}`);
  }

  return lines.join('\n');
}

export function downloadCsv(csv: string, filename: string) {
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

/**
 * Check if the current user's plan allows CSV export.
 * This will be replaced with a proper subscription check once
 * the API returns plan info. For now, it returns false for free tier.
 */
export function canExportCsv(): boolean {
  // TODO: Replace with actual plan check from API
  // For now, check if the user has a team (which implies paid plan)
  return currentTeam.value !== null;
}