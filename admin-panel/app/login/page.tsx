'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { apiLogin, setToken } from '@/lib/api';
import { Wallet, ShieldCheck, Zap, Globe } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@Money.com');
  const [password, setPassword] = useState('');
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    setLoading(true);
    try {
      const { accessToken } = await apiLogin(email.trim(), password);
      setToken(accessToken);
      router.push('/dashboard');
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen bg-mf-bg overflow-hidden">
      {/* LEFT: Branding Stage */}
      <div className="relative hidden w-1/2 flex-col justify-between bg-[#0D0F1A] lg:flex p-16 overflow-hidden">
        {/* Animated Orbs */}
        <div className="absolute top-[-10%] left-[-10%] h-96 w-96 rounded-full bg-mf-accent/10 blur-[120px] animate-pulse" />
        <div className="absolute bottom-[-10%] right-[-10%] h-96 w-96 rounded-full bg-mf-success/10 blur-[120px]" />
        
        <div className="relative z-10 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-mf-accent shadow-neon-purple shadow-mf-accent/30">
            <Wallet className="h-6 w-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-black text-white tracking-tight">MoneyFlow <span className="text-mf-accent">AI</span></h1>
          </div>
        </div>

        <div className="relative z-10">
          <h2 className="text-5xl font-black leading-tight tracking-tight text-white max-w-md">
            Manage your <span className="text-transparent bg-clip-text bg-gradient-to-r from-mf-accent to-mf-success">Wealth</span> with precision.
          </h2>
          <p className="mt-6 text-lg font-medium text-mf-muted/80 max-w-md leading-relaxed">
            The next generation of financial intelligence, designed for elite management and real-time telemetry.
          </p>
          
          <div className="mt-12 grid grid-cols-2 gap-8 max-w-sm">
            <div className="flex items-center gap-3">
              <ShieldCheck className="h-5 w-5 text-mf-success" />
              <span className="text-xs font-bold text-white uppercase tracking-widest">Secure Alpha</span>
            </div>
            <div className="flex items-center gap-3">
              <Zap className="h-5 w-5 text-mf-accent" />
              <span className="text-xs font-bold text-white uppercase tracking-widest">Real-time Sync</span>
            </div>
          </div>
        </div>

        <div className="relative z-10 flex items-center gap-2">
            <div className="h-1.5 w-1.5 rounded-full bg-mf-success animate-ping" />
            <span className="text-xs font-black text-mf-muted/60 uppercase tracking-[0.3em]">System Status: Operational</span>
        </div>
      </div>

      {/* RIGHT: Login Form */}
      <div className="flex flex-1 flex-col items-center justify-center px-8 sm:px-16 lg:bg-white/[0.01]">
        <div className="w-full max-w-md">
           <div className="mb-12 lg:hidden flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-mf-accent">
              <Wallet className="h-6 w-6 text-white" />
            </div>
            <h1 className="text-xl font-black text-white">MoneyFlow AI</h1>
          </div>

          <div className="mb-10 text-center lg:text-left">
            <h3 className="text-3xl font-black text-white tracking-widest uppercase mb-2">Sign In</h3>
            <p className="text-mf-muted font-bold tracking-tight">Enter your credentials to access the pro-ledger.</p>
          </div>

          <form onSubmit={onSubmit} className="space-y-6">
            <div className="space-y-2">
              <label className="text-[10px] font-black text-mf-muted uppercase tracking-[0.2em] ml-1">Identity (Email)</label>
              <div className="relative group">
                <Globe className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-white/10 group-focus-within:text-mf-accent transition-all" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full rounded-2xl border border-white/5 bg-white/[0.03] px-12 py-4 text-sm font-bold text-white outline-none focus:border-mf-accent/50 focus:bg-white/[0.08] transition-all"
                  placeholder="admin@moneyflow.ai"
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-[10px] font-black text-mf-muted uppercase tracking-[0.2em] ml-1">Signature (Password)</label>
              <div className="relative group">
                <ShieldCheck className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-white/10 group-focus-within:text-mf-accent transition-all" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-2xl border border-white/5 bg-white/[0.03] px-12 py-4 text-sm font-bold text-white outline-none focus:border-mf-accent/50 focus:bg-white/[0.08] transition-all"
                  placeholder="••••••••"
                  required
                />
              </div>
            </div>

            {err && (
              <div className="rounded-xl bg-mf-error/10 border border-mf-error/20 p-4">
                <p className="text-xs font-bold text-mf-error text-center">{err}</p>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="relative w-full group overflow-hidden rounded-2xl bg-mf-accent py-4 text-sm font-black text-white hover:scale-[1.02] active:scale-[0.98] transition-all shadow-neon-purple shadow-mf-accent/30 disabled:opacity-50"
            >
              <div className="absolute inset-0 bg-white/10 opacity-0 group-hover:opacity-100 transition-all duration-500" />
              <span className="relative z-10 uppercase tracking-[0.2em]">
                {loading ? 'Authenticating...' : 'Access Ledger'}
              </span>
            </button>
          </form>

          <div className="mt-10 text-center">
             <p className="text-[10px] font-black text-mf-muted/40 uppercase tracking-[0.3em]">
               Encrypted Session • High Availability
             </p>
          </div>
        </div>
      </div>
    </div>
  );
}
