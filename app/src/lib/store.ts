import { signal, computed } from '@preact/signals';

export interface Item {
  id: string;
  name: string;
  details: string;
  customFields: Record<string, string>;
  qrCodeData: string;
  createdAt: string;
  updatedAt: string;
  locations?: ItemLocation[];
}

export interface Location {
  id: string;
  name: string;
  latitude: number | null;
  longitude: number | null;
  radius: number;
  address: string;
  createdAt: string;
  updatedAt: string;
  itemCount?: number;
}

export interface ItemLocation {
  id: string;
  itemId: string;
  locationId: string | null;
  latitude: number | null;
  longitude: number | null;
  address: string;
  notes: string;
  timestamp: string;
}

export interface User {
  id: string;
  email: string;
  name: string;
}

export interface Team {
  id: string;
  name: string;
  role: string;
}

// ─── Auth State ──────────────────────────────────────────────────────────────
export const currentUser = signal<User | null>(null);
export const currentTeam = signal<Team | null>(null);
export const teams = signal<Team[]>([]);
export const isAuthenticated = computed(() => currentUser.value !== null);

// ─── Data State ──────────────────────────────────────────────────────────────
export const items = signal<Item[]>([]);
export const locations = signal<Location[]>([]);
export const isLoading = signal(false);
export const error = signal<string | null>(null);