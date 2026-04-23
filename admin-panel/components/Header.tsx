'use client';

import { Bell, ChevronDown, Search } from 'lucide-react';
import { usePathname } from 'next/navigation';

export function Header() {
  const pathname = usePathname();
  const pageTitle = pathname.split('/').pop()?.replace(/^\w/, (c) => c.toUpperCase()) || 'Dashboard';

  return (
    <header className="flex h-24 items-center justify-between px-8 border-b border-mf-border/30 backdrop-blur-md sticky top-0 z-40 bg-mf-bg/50">
      <div className="flex items-center gap-8">
        <h2 className="text-2xl font-extrabold tracking-tight text-white">{pageTitle}</h2>
        <div className="relative hidden xl:block">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-mf-muted" />
          <input 
            type="text" 
            placeholder="Search transactions, accounts..." 
            className="w-80 rounded-2xl bg-white/5 border border-mf-border/30 px-12 py-3 text-sm focus:outline-none focus:border-mf-accent/50 focus:bg-white/[0.08] transition-all"
          />
        </div>
      </div>

      <div className="flex items-center gap-6">
        <div className="flex items-center gap-2 px-4 py-2 rounded-2xl bg-white/5 border border-white/10 cursor-pointer hover:bg-white/10 transition-all">
          <span className="text-xs font-bold text-mf-muted uppercase tracking-tighter">Account:</span>
          <span className="text-xs font-extrabold text-white">Household Wallet</span>
          <ChevronDown className="h-4 w-4 text-mf-muted" />
        </div>

        <button className="relative p-3 rounded-2xl bg-white/5 border border-white/10 text-mf-muted hover:text-white hover:bg-white/10 transition-all">
          <Bell className="h-5 w-5" />
          <span className="absolute top-3 right-3 h-2 w-2 rounded-full bg-mf-success border-2 border-mf-bg"></span>
        </button>

        <div className="flex items-center gap-3 pl-4 border-l border-mf-border/30">
          <div className="text-right hidden sm:block">
            <p className="text-sm font-extrabold text-white leading-none">Surag Ms</p>
            <p className="text-[10px] font-bold text-mf-muted uppercase tracking-widest mt-1">Pro Member</p>
          </div>
          <div className="h-12 w-12 rounded-2xl bg-gradient-to-br from-mf-accent to-mf-purple flex items-center justify-center text-lg font-bold shadow-neon-purple border-2 border-white/10">
            S
          </div>
        </div>
      </div>
    </header>
  );
}
