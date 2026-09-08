import { useEffect, useState } from 'preact/hooks';
import { locations, currentTeam } from '../lib/store';
import { fetchLocations } from '../lib/actions';
import { Link, route } from 'preact-router';
import { LocationCard } from '../components/Cards';

export function LocationsPage() {
  const teamId = currentTeam.value?.id;
  const [search, setSearch] = useState('');

  useEffect(() => {
    if (teamId) fetchLocations(teamId);
  }, [teamId]);

  const filtered = search
    ? locations.value.filter((l) => l.name.toLowerCase().includes(search.toLowerCase()) || l.address.toLowerCase().includes(search.toLowerCase()))
    : locations.value;

  return (
    <div>
      <div class="flex items-center justify-between mb-6">
        <h1 class="font-display text-2xl font-semibold text-on-surface">Locations</h1>
        <Link href="/locations/add" class="btn-primary">+ Add Location</Link>
      </div>

      <input
        type="text"
        placeholder="Search locations…"
        value={search}
        onInput={(e) => setSearch((e.target as HTMLInputElement).value)}
        class="w-full px-4 py-3 rounded-md bg-surface border-none outline-none focus:ring-2 focus:ring-tertiary mb-4"
      />

      {filtered.length === 0 ? (
        <div class="card text-center py-12">
          <h2 class="font-display text-xl font-semibold text-on-surface mb-2">
            {search ? 'No matching locations' : 'No locations yet'}
          </h2>
          <p class="text-secondary mb-6">
            {search ? 'Try a different search term' : 'Add locations to group items by place'}
          </p>
          {!search && <Link href="/locations/add" class="btn-primary">+ Add Location</Link>}
        </div>
      ) : (
        <div class="space-y-2">
          {filtered.map((loc) => (
            <LocationCard key={loc.id} location={loc} onClick={() => route(`/locations/${loc.id}`)} />
          ))}
        </div>
      )}
    </div>
  );
}