import { useEffect, useState } from 'preact/hooks';
import { apiFetch } from '../lib/api';
import { currentTeam } from '../lib/store';
import { Link, route } from 'preact-router';
import type { Item } from '../lib/store';

export function ItemDetailPage({ id }: { id: string }) {
  const [item, setItem] = useState<Item | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const teamId = currentTeam.value?.id;

  useEffect(() => {
    if (teamId) {
      (async () => {
        const res = await apiFetch<{ item: Item }>(`/items/${id}`, { headers: { 'X-Team-Id': teamId } });
        if (res.ok && res.data) {
          setItem(res.data.item);
        } else {
          setError(res.error || 'Failed to load item');
        }
        setLoading(false);
      })();
    }
  }, [id, teamId]);

  const handleDelete = async () => {
    if (!confirm(`Delete "${item?.name}"? This cannot be undone.`)) return;
    if (!teamId) return;
    const res = await apiFetch(`/items/${id}`, { method: 'DELETE', headers: { 'X-Team-Id': teamId } });
    if (res.ok) {
      route('/items');
    }
  };

  if (loading) return <div class="text-center py-12 text-secondary">Loading…</div>;
  if (error) return <div class="card text-center py-12 text-error">{error}</div>;
  if (!item) return <div class="card text-center py-12 text-secondary">Item not found</div>;

  return (
    <div class="max-w-2xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <h1 class="font-display text-2xl font-semibold text-on-surface">{item.name}</h1>
        <div class="flex gap-2">
          <button onClick={handleDelete} class="btn-ghost text-error border-error/30 hover:bg-error/10">Delete</button>
        </div>
      </div>

      {/* QR Code */}
      <div class="card text-center mb-6">
        <div class="inline-block p-4 bg-white rounded-lg">
          <div class="text-6xl leading-none">📱</div>
        </div>
        <p class="text-sm text-secondary mt-2">QR Code: <code class="text-xs bg-neutral px-2 py-1 rounded">{item.qrCodeData}</code></p>
      </div>

      {/* Details */}
      <div class="card mb-6">
        <h2 class="font-display text-lg font-semibold text-on-surface mb-3">Details</h2>
        {item.details && <p class="text-secondary mb-3">{item.details}</p>}
        {item.customFields && Object.keys(item.customFields).length > 0 && (
          <div class="space-y-2">
            <h3 class="text-xs uppercase tracking-widest text-secondary">Custom Fields</h3>
            {Object.entries(item.customFields).map(([key, value]) => (
              <div key={key} class="flex gap-2">
                <span class="text-xs uppercase tracking-widest text-secondary">{key}</span>
                <span class="text-on-surface">{value}</span>
              </div>
            ))}
          </div>
        )}
        <p class="text-xs text-secondary mt-4">
          Created {new Date(item.createdAt).toLocaleDateString()}
        </p>
      </div>

      {/* Location History */}
      {item.locations && item.locations.length > 0 && (
        <div class="card">
          <h2 class="font-display text-lg font-semibold text-on-surface mb-3">Location History</h2>
          <div class="space-y-3">
            {item.locations.map((loc) => (
              <div key={loc.id} class="flex items-start gap-3">
                <div class="w-2 h-2 bg-tertiary rounded-full mt-2 flex-shrink-0"></div>
                <div>
                  {loc.address && <div class="font-semibold text-on-surface">{loc.address}</div>}
                  {loc.latitude && loc.longitude && (
                    <div class="text-xs text-secondary">{loc.latitude.toFixed(6)}, {loc.longitude.toFixed(6)}</div>
                  )}
                  <div class="text-xs text-secondary">{new Date(loc.timestamp).toLocaleString()}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}