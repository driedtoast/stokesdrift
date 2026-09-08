import { useEffect } from 'preact/hooks';
import { items, locations, isLoading, currentTeam } from '../lib/store';
import { fetchItems, fetchLocations } from '../lib/actions';
import { Link, route } from 'preact-router';
import { StatCard } from '../components/Cards';

export function DashboardPage() {
  const teamId = currentTeam.value?.id;

  useEffect(() => {
    if (teamId) {
      fetchItems(teamId);
      fetchLocations(teamId);
    }
  }, [teamId]);

  const recentItems = items.value.slice(0, 5);

  return (
    <div>
      {/* Stats */}
      <div class="grid grid-cols-3 gap-4 mb-8">
        <StatCard number={items.value.length} label="Items" />
        <StatCard number={locations.value.length} label="Locations" />
        <StatCard number="—" label="Recent Scans" />
      </div>

      {/* Quick Actions */}
      <div class="card mb-8">
        <h2 class="font-display text-lg font-semibold text-on-surface mb-4">Quick Actions</h2>
        <div class="flex gap-3">
          <Link href="/items/add" class="btn-primary">+ Add Item</Link>
          <Link href="/locations/add" class="btn-ghost">+ Add Location</Link>
        </div>
      </div>

      {/* Recent Items */}
      {recentItems.length > 0 && (
        <div class="card">
          <div class="flex items-center justify-between mb-4">
            <h2 class="font-display text-lg font-semibold text-on-surface">Recent Items</h2>
            <Link href="/items" class="text-sm text-tertiary hover:underline">View All</Link>
          </div>
          <div class="space-y-2">
            {recentItems.map((item) => (
              <div
                key={item.id}
                class="flex items-center gap-3 py-2 cursor-pointer hover:bg-neutral/50 rounded-md px-2 -mx-2"
                onClick={() => route(`/items/${item.id}`)}
              >
                <div class="w-3 h-3 bg-tertiary rounded-full flex-shrink-0"></div>
                <div class="flex-1 min-w-0">
                  <div class="font-semibold text-on-surface">{item.name}</div>
                  {item.details && <div class="text-sm text-secondary truncate">{item.details}</div>}
                </div>
                <svg class="w-4 h-4 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                </svg>
              </div>
            ))}
          </div>
        </div>
      )}

      {items.value.length === 0 && !isLoading.value && (
        <div class="card text-center py-12">
          <h2 class="font-display text-xl font-semibold text-on-surface mb-2">No items yet</h2>
          <p class="text-secondary mb-6">Add your first item to start tracking.</p>
          <Link href="/items/add" class="btn-primary">+ Add Item</Link>
        </div>
      )}
    </div>
  );
}