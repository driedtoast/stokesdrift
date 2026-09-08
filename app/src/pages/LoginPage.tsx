import { useState } from 'preact/hooks';
import { apiFetch, setToken } from '../lib/api';
import { currentUser, teams, currentTeam } from '../lib/store';
import { Link } from 'preact-router';

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const res = await apiFetch<{ token: string; user: { id: string; email: string; name: string }; teams: { id: string; name: string; role: string }[] }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });

    if (res.ok && res.data) {
      setToken(res.data.token);
      currentUser.value = res.data.user;
      teams.value = res.data.teams;
      if (res.data.teams.length > 0) {
        currentTeam.value = res.data.teams[0];
      }
    } else {
      setError(res.error || 'Login failed');
    }
    setLoading(false);
  };

  return (
    <div class="max-w-md mx-auto mt-20">
      <div class="card">
        <h1 class="font-display text-2xl font-semibold text-on-surface text-center mb-6">Sign In</h1>
        {error && <div class="bg-error/10 text-error rounded-md px-4 py-2 mb-4 text-sm">{error}</div>}
        <form onSubmit={handleSubmit} class="space-y-4">
          <div>
            <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Email</label>
            <input type="email" value={email} onInput={(e) => setEmail((e.target as HTMLInputElement).value)} class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" required />
          </div>
          <div>
            <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Password</label>
            <input type="password" value={password} onInput={(e) => setPassword((e.target as HTMLInputElement).value)} class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" required />
          </div>
          <button type="submit" disabled={loading} class="btn-primary w-full">
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
        <p class="text-sm text-secondary text-center mt-4">
          Don't have an account? <Link href="/signup" class="text-tertiary hover:underline">Sign Up</Link>
        </p>
      </div>
    </div>
  );
}