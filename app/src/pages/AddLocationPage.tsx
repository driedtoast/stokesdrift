import { useState } from 'preact/hooks';
import { createLocation } from '../lib/actions';
import { currentTeam } from '../lib/store';
import { route } from 'preact-router';

export function AddLocationPage() {
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [radius, setRadius] = useState('50');
  const [useGps, setUseGps] = useState(false);
  const [latitude, setLatitude] = useState<number | null>(null);
  const [longitude, setLongitude] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleToggleGps = async () => {
    if (!useGps) {
      try {
        const pos = await new Promise<GeolocationPosition>((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true });
        });
        setLatitude(pos.coords.latitude);
        setLongitude(pos.coords.longitude);
        setUseGps(true);
      } catch {
        setError('Location permission denied. Enable GPS in your browser settings.');
      }
    } else {
      setUseGps(false);
      setLatitude(null);
      setLongitude(null);
    }
  };

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    if (!name.trim()) return;
    setLoading(true);
    setError(null);

    const location = await createLocation(currentTeam.value?.id || '', {
      name: name.trim(),
      address: address.trim(),
      radius: parseFloat(radius) || 50,
      latitude: useGps ? latitude : null,
      longitude: useGps ? longitude : null,
    });

    if (location) {
      route(`/locations/${location.id}`);
    } else {
      setError('Failed to create location');
    }
    setLoading(false);
  };

  return (
    <div class="max-w-lg mx-auto">
      <h1 class="font-display text-2xl font-semibold text-on-surface mb-6">Add Location</h1>

      <form onSubmit={handleSubmit} class="card">
        {error && <div class="bg-error/10 text-error rounded-md px-4 py-2 mb-4 text-sm">{error}</div>}

        <div class="mb-4">
          <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Location Name</label>
          <input type="text" value={name} onInput={(e) => setName((e.target as HTMLInputElement).value)} placeholder="e.g. Main Stage, Warehouse B" class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" required />
        </div>

        <div class="mb-4">
          <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Address (optional)</label>
          <input type="text" value={address} onInput={(e) => setAddress((e.target as HTMLInputElement).value)} placeholder="e.g. 123 Main St, City, State" class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" />
        </div>

        <div class="mb-4">
          <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Proximity Radius (meters)</label>
          <input type="number" value={radius} onInput={(e) => setRadius((e.target as HTMLInputElement).value)} class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" />
          <p class="text-xs text-secondary mt-1">Items scanned within this radius will be automatically assigned to this location.</p>
        </div>

        <div class="mb-6">
          <button type="button" onClick={handleToggleGps} class={`w-full py-3 rounded-md font-sans text-sm font-semibold uppercase tracking-widest transition-all ${useGps ? 'bg-secondary text-on-primary' : 'bg-transparent text-secondary border border-secondary'}`}>
            {useGps ? '✓ GPS WILL BE USED' : 'USE CURRENT GPS'}
          </button>
          {useGps && latitude !== null && (
            <p class="text-xs text-secondary mt-2">📍 {latitude.toFixed(6)}, {longitude!.toFixed(6)}</p>
          )}
        </div>

        <button type="submit" disabled={loading || !name.trim()} class="btn-primary w-full">
          {loading ? 'Creating…' : 'CREATE LOCATION'}
        </button>
      </form>
    </div>
  );
}