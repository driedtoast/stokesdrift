import { apiFetch } from './api';
import { items, locations, isLoading, error } from './store';
import type { Item, Location } from './store';

export async function fetchItems(teamId: string) {
  isLoading.value = true;
  error.value = null;
  const res = await apiFetch<{ items: Item[] }>(`/items?teamId=${teamId}`);
  if (res.ok && res.data) {
    items.value = res.data.items;
  } else {
    error.value = res.error || 'Failed to fetch items';
  }
  isLoading.value = false;
}

export async function createItem(teamId: string, data: { name: string; details?: string; customFields?: Record<string, string> }) {
  const res = await apiFetch<{ item: Item }>('/items', {
    method: 'POST',
    body: JSON.stringify(data),
    headers: { 'X-Team-Id': teamId },
  });
  if (res.ok && res.data) {
    items.value = [res.data.item, ...items.value];
    return res.data.item;
  }
  error.value = res.error || 'Failed to create item';
  return null;
}

export async function updateItem(teamId: string, id: string, data: Partial<Pick<Item, 'name' | 'details' | 'customFields'>>) {
  const res = await apiFetch<{ item: Item }>(`/items/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
    headers: { 'X-Team-Id': teamId },
  });
  if (res.ok && res.data) {
    items.value = items.value.map((i) => (i.id === id ? res.data!.item : i));
    return res.data.item;
  }
  error.value = res.error || 'Failed to update item';
  return null;
}

export async function deleteItem(teamId: string, id: string) {
  const res = await apiFetch(`/items/${id}`, {
    method: 'DELETE',
    headers: { 'X-Team-Id': teamId },
  });
  if (res.ok) {
    items.value = items.value.filter((i) => i.id !== id);
  } else {
    error.value = res.error || 'Failed to delete item';
  }
}

export async function fetchLocations(teamId: string) {
  isLoading.value = true;
  error.value = null;
  const res = await apiFetch<{ locations: Location[] }>(`/locations?teamId=${teamId}`);
  if (res.ok && res.data) {
    locations.value = res.data.locations;
  } else {
    error.value = res.error || 'Failed to fetch locations';
  }
  isLoading.value = false;
}

export async function createLocation(teamId: string, data: { name: string; latitude?: number | null; longitude?: number | null; radius?: number; address?: string }) {
  const res = await apiFetch<{ location: Location }>('/locations', {
    method: 'POST',
    body: JSON.stringify(data),
    headers: { 'X-Team-Id': teamId },
  });
  if (res.ok && res.data) {
    locations.value = [...locations.value, res.data.location];
    return res.data.location;
  }
  error.value = res.error || 'Failed to create location';
  return null;
}