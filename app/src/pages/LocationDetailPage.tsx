import { useEffect, useState } from 'preact/hooks';
import { apiFetch } from '../lib/api';
import { currentTeam } from '../lib/store';
import type { Item, Location } from '../lib/store';
import { Link } from 'preact-router';

export function LocationDetailPage({ id }: { id: string }) {
  const [location, setLocation] = useState<Location | null>(null);
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const teamId = currentTeam.value?.id;

  useEffect(() => {
    if (teamId) {
      (async () => {
        const res = await apiFetch<{ location: Location; items: Item[] }>(`/locations/${id}`, { headers: { 'X-Team-Id': teamId } });
        if (res.ok && res.data) {
          setLocation(res.data.location);
          setItems(res.data.items);
        }
        setLoading(false);
      })();
    }
  }, [id, teamId]);

  const handleDelete = async () => {
    if (!confirm(`Delete "${location?.name}"?`)) return;
    if (!teamId) return;
    const res = await apiFetch(`/locations/${id}`, { method: 'DELETE', headers: { 'X-Team-Id': teamId } });
    if (res.ok) route('/locations');
  };

  if (loading) return <div class="text-center py-12 text-secondary">Loading…</div>;
  if (!location) return <div class="card text-center py-12 text-secondary">Location not found</div>;

  return (
    <div class="max-w-2xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <h1 class="font-display text-2xl font-semibold text-on-surface">{location.name}</h1>
        <button onClick={handleDelete} class="btn-ghost text-error border-error/30 hover:bg-error/10">Delete</button>
      </div>

      <div class="card mb-6">
        <h2 class="font-display text-lg font-semibold text-on-surface mb-3">Details</h2>
        {location.address && <p class="text-secondary mb-2">{location.address}</p>}
        {location.latitude && location.longitude && (
          <p class="text-sm text-secondary flex items-center gap-2">
            <span>📍</span> {location.latitude.toFixed(6)}, {location.longitude.toFixed(6)} (radius: {location.radius}m)
          </p>
        )}
        <p class="text-xs text-secondary mt-3">{items.length} item{items.length === 1 ? '' : 's'} at this location</p>
      </div>

      <div class="card">
        <h2 class="font-display text-lg font-semibold text-on-surface mb-3">Items</h2>
        {items.length === 0 ? (
          <p class="text-secondary text-center py-6">No items at this location yet</p>
        ) : (
          <div class="space-y-2">
            {items.map((item) => (
              <Link key={item.id} href={`/items/${item.id}`} class="flex items-center gap-3 py-2 px-2 -mx-2 hover:bg-neutral/50 rounded-md">
                <div class="w-3 h-3 bg-tertiary rounded-full flex-shrink-0"></div>
                <div class="flex-1 min-w-0">
                  <div class="font-semibold text-on-surface">{item.name}</div>
                  {item.details && <div class="text-sm text-secondary truncate">{item.details}</div>}
                </div>
                <svg class="w-4 h-4 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                </svg>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}