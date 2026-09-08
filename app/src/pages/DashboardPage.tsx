import { useEffect } from 'preact/hooks';
import { items, locations, isLoading, currentTeam } from '../lib/store';
import { fetchItems, fetchLocations } from '../lib/actions';
import { generateCsv, downloadCsv, canExportCsv } from '../lib/csv_export';
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
  const exportAllowed = canExportCsv();

  function handleExport() {
    if (!exportAllowed) {
      alert('CSV export is available on the Crew and Enterprise plans. Upgrade your plan to export your inventory data.');
      return;
    }
    const csv = generateCsv(items.value, locations.value);
    const date = new Date().toISOString().substring(0, 10);
    downloadCsv(csv, `stokesdrift_export_${date}.csv`);
  }

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
          <button
            onClick={handleExport}
            class="btn-ghost flex items-center gap-2"
            title={exportAllowed ? 'Export inventory to CSV' : 'Upgrade to export'}
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            Export CSV
          </button>
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