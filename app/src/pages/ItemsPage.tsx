import { useEffect } from 'preact/hooks';
import { items, isLoading, currentTeam } from '../lib/store';
import { fetchItems } from '../lib/actions';
import { Link, route } from 'preact-router';
import { ItemCard } from '../components/Cards';
import { useState } from 'preact/hooks';

export function ItemsPage() {
  const teamId = currentTeam.value?.id;
  const [search, setSearch] = useState('');

  useEffect(() => {
    if (teamId) fetchItems(teamId);
  }, [teamId]);

  const filtered = search
    ? items.value.filter((i) => i.name.toLowerCase().includes(search.toLowerCase()) || i.details.toLowerCase().includes(search.toLowerCase()))
    : items.value;

  return (
    <div>
      <div class="flex items-center justify-between mb-6">
        <h1 class="font-display text-2xl font-semibold text-on-surface">Items</h1>
        <Link href="/items/add" class="btn-primary">+ Add Item</Link>
      </div>

      <input
        type="text"
        placeholder="Search items…"
        value={search}
        onInput={(e) => setSearch((e.target as HTMLInputElement).value)}
        class="w-full px-4 py-3 rounded-md bg-surface border-none outline-none focus:ring-2 focus:ring-tertiary mb-4"
      />

      {filtered.length === 0 && !isLoading.value ? (
        <div class="card text-center py-12">
          <h2 class="font-display text-xl font-semibold text-on-surface mb-2">
            {search ? 'No matching items' : 'No items yet'}
          </h2>
          <p class="text-secondary mb-6">
            {search ? 'Try a different search term' : 'Add your first item to get started'}
          </p>
          {!search && <Link href="/items/add" class="btn-primary">+ Add Item</Link>}
        </div>
      ) : (
        <div class="space-y-2">
          {filtered.map((item) => (
            <ItemCard key={item.id} item={item} onClick={() => route(`/items/${item.id}`)} />
          ))}
        </div>
      )}
    </div>
  );
}