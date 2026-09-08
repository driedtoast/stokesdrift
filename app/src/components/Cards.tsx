export function ItemCard({ item, onClick }: { item: { id: string; name: string; details: string; qrCodeData: string }; onClick: () => void }) {
  return (
    <div onClick={onClick} class="card cursor-pointer hover:shadow-md transition-shadow">
      <div class="flex items-center gap-3">
        <div class="w-3 h-3 bg-tertiary rounded-full flex-shrink-0"></div>
        <div class="flex-1 min-w-0">
          <h3 class="font-display font-semibold text-on-surface truncate">{item.name}</h3>
          {item.details && (
            <p class="text-sm text-secondary truncate mt-0.5">{item.details}</p>
          )}
        </div>
        <svg class="w-5 h-5 text-secondary flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      </div>
    </div>
  );
}

export function LocationCard({ location, onClick }: { location: { id: string; name: string; address: string; itemCount?: number }; onClick: () => void }) {
  return (
    <div onClick={onClick} class="card cursor-pointer hover:shadow-md transition-shadow">
      <div class="flex items-center gap-3">
        <div class="w-3 h-3 bg-secondary rounded-full flex-shrink-0"></div>
        <div class="flex-1 min-w-0">
          <h3 class="font-display font-semibold text-on-surface truncate">{location.name}</h3>
          {location.address && (
            <p class="text-sm text-secondary truncate mt-0.5">{location.address}</p>
          )}
        </div>
        {location.itemCount !== undefined && (
          <span class="bg-tertiary text-on-primary text-xs font-semibold px-2 py-0.5 rounded-full">
            {location.itemCount}
          </span>
        )}
        <svg class="w-5 h-5 text-secondary flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      </div>
    </div>
  );
}

export function StatCard({ number, label }: { number: string | number; label: string }) {
  return (
    <div class="card text-center">
      <div class="font-display text-2xl font-semibold text-primary">{number}</div>
      <div class="text-xs uppercase tracking-widest text-secondary mt-1">{label}</div>
    </div>
  );
}