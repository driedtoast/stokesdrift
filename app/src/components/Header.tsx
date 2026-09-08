import { isAuthenticated, currentUser } from '../lib/store';
import { clearToken } from '../lib/api';
import { Link } from 'preact-router';

export function Header() {
  const handleLogout = () => {
    clearToken();
    isAuthenticated.value = false;
    currentUser.value = null;
  };

  return (
    <header class="py-4 px-6 lg:px-12 flex justify-between items-center bg-surface border-b border-secondary/10">
      <Link href="/" class="flex items-center gap-3">
        <div class="w-9 h-9 bg-primary rounded-md flex items-center justify-center">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M2 12C3.5 9 5 8 7 9C9 10 10 14 12 12C14 10 15 8 17 9C19 10 20.5 12 22 12" stroke="white" stroke-width="2" stroke-linecap="round"/>
            <circle cx="19" cy="7" r="1.5" fill="white"/>
          </svg>
        </div>
        <span class="font-display font-bold text-xl tracking-tight text-on-surface">StokeDrift</span>
      </Link>

      {isAuthenticated.value ? (
        <nav class="flex items-center gap-6">
          <Link href="/items" class="font-sans text-sm font-semibold uppercase tracking-wider text-secondary hover:text-tertiary transition-colors">Items</Link>
          <Link href="/locations" class="font-sans text-sm font-semibold uppercase tracking-wider text-secondary hover:text-tertiary transition-colors">Locations</Link>
          <div class="flex items-center gap-3 ml-4 pl-4 border-l border-secondary/20">
            <span class="text-sm text-secondary">{currentUser.value?.name}</span>
            <button onClick={handleLogout} class="btn-ghost text-xs py-2 px-3">Sign Out</button>
          </div>
        </nav>
      ) : (
        <nav class="flex items-center gap-4">
          <Link href="/login" class="btn-ghost text-xs py-2 px-3">Sign In</Link>
          <Link href="/signup" class="btn-primary text-xs py-2 px-3">Get Started</Link>
        </nav>
      )}
    </header>
  );
}