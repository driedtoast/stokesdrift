import { useState } from 'preact/hooks';
import { apiFetch, setToken } from '../lib/api';
import { currentUser, teams, currentTeam } from '../lib/store';
import { Link } from 'preact-router';

export function SignupPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const res = await apiFetch<{ token: string; user: { id: string; email: string; name: string }; teamId: string }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email, password, name }),
    });

    if (res.ok && res.data) {
      setToken(res.data.token);
      currentUser.value = res.data.user;
      currentTeam.value = { id: res.data.teamId, name: `${name}'s Team`, role: 'OWNER' };
      teams.value = [currentTeam.value!];
    } else {
      setError(res.error || 'Registration failed');
    }
    setLoading(false);
  };

  return (
    <div class="max-w-md mx-auto mt-20">
      <div class="card">
        <h1 class="font-display text-2xl font-semibold text-on-surface text-center mb-6">Create Account</h1>
        {error && <div class="bg-error/10 text-error rounded-md px-4 py-2 mb-4 text-sm">{error}</div>}
        <form onSubmit={handleSubmit} class="space-y-4">
          <div>
            <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Name</label>
            <input type="text" value={name} onInput={(e) => setName((e.target as HTMLInputElement).value)} class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" required />
          </div>
          <div>
            <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Email</label>
            <input type="email" value={email} onInput={(e) => setEmail((e.target as HTMLInputElement).value)} class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" required />
          </div>
          <div>
            <label class="block text-xs uppercase tracking-widest text-secondary mb-1">Password</label>
            <input type="password" value={password} onInput={(e) => setPassword((e.target as HTMLInputElement).value)} class="w-full px-4 py-3 rounded-md bg-neutral border-none outline-none focus:ring-2 focus:ring-tertiary" required minLength={8} />
          </div>
          <button type="submit" disabled={loading} class="btn-primary w-full">
            {loading ? 'Creating account…' : 'Get Started Free'}
          </button>
        </form>
        <p class="text-sm text-secondary text-center mt-4">
          Already have an account? <Link href="/login" class="text-tertiary hover:underline">Sign In</Link>
        </p>
      </div>
    </div>
  );
}