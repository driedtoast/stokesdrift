import { useState } from 'preact/hooks';
import { createItem } from '../lib/actions';
import { currentTeam } from '../lib/store';
import { route } from 'preact-router';

interface CustomField {
  key: string;
  value: string;
}

export function AddItemPage() {
  const [name, setName] = useState('');
  const [details, setDetails] = useState('');
  const [customFields, setCustomFields] = useState<CustomField[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    if (!name.trim()) return;
    setLoading(true);
    setError(null);

    const fields: Record<string, string> = {};
    for (const f of customFields) {
      if (f.key.trim()) fields[f.key.trim()] = f.value.trim();
    }

    const item = await createItem(currentTeam.value?.id || '', {
      name: name.trim(),
      details: details.trim(),
      customFields: fields,
    });

    if (item) {
      route(`/items/${item.id}`);
    } else {
      setError('Failed to create item');
    }
    setLoading(false);
  };

  return (
    <div class="max-w-lg mx-auto">
      <h1 class="font-display text-2xl font-semibold text-on-surface mb-6">Add Item</h1>

      <form onSubmit={handleSubmit} class="card">
        {error && <div class="bg-error/10 text-error rounded-md px-4 py-2 mb-4 text-sm">{error}</div>}

        <div class="mb-4">
          <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Item Name</label>
          <input type="text" value={name} onInput={(e) => setName((e.target as HTMLInputElement).value)} placeholder="e.g. Shure SM58 Microphone" class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" required />
        </div>

        <div class="mb-4">
          <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Details</label>
          <textarea value={details} onInput={(e) => setDetails((e.target as HTMLTextAreaElement).value)} placeholder="Description, serial number, notes…" rows={3} class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary resize-none" />
        </div>

        {/* Custom Fields */}
        <div class="mb-4">
          <label class="block text-xs uppercase tracking-widest text-secondary mb-2">Custom Fields</label>
          <div class="space-y-2">
            {customFields.map((f, i) => (
              <div key={i} class="flex gap-2">
                <input type="text" value={f.key} onInput={(e) => {
                  const updated = [...customFields];
                  updated[i] = { ...updated[i], key: (e.target as HTMLInputElement).value };
                  setCustomFields(updated);
                }} placeholder="Field name" class="flex-1 px-3 py-2 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary text-sm" />
                <input type="text" value={f.value} onInput={(e) => {
                  const updated = [...customFields];
                  updated[i] = { ...updated[i], value: (e.target as HTMLInputElement).value };
                  setCustomFields(updated);
                }} placeholder="Value" class="flex-[2] px-3 py-2 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary text-sm" />
                <button type="button" onClick={() => setCustomFields(customFields.filter((_, idx) => idx !== i))} class="text-error hover:bg-error/10 rounded-md px-2">✕</button>
              </div>
            ))}
          </div>
          <button type="button" onClick={() => setCustomFields([...customFields, { key: '', value: '' }])} class="btn-ghost text-xs mt-2">+ Add Field</button>
        </div>

        <p class="text-sm text-secondary mb-6">A QR code will be generated automatically when you create the item.</p>

        <button type="submit" disabled={loading || !name.trim()} class="btn-primary w-full">
          {loading ? 'Creating…' : 'CREATE ITEM'}
        </button>
      </form>
    </div>
  );
}