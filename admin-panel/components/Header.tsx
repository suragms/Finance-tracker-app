'use client';

import { Bell, ChevronDown, Search } from 'lucide-react';
import { usePathname } from 'next/navigation';

export function Header() {
  const pathname = usePathname();
  const pageTitle = pathname.split('/').pop()?.replace(/^\w/, (c) => c.toUpperCase()) || 'Dashboard';

  return (
    <header className="flex h-20 items-center justify-between px-8 border-b border-mf-border backdrop-blur-md sticky top-0 z-30 bg-white/80">
      <div className="flex items-center gap-8">
        <h2 className="text-xl font-bold tracking-tight text-mf-dark lg:hidden">MoneyFlow AI</h2>
        <h2 className="text-xl font-bold tracking-tight text-mf-dark hidden lg:block">{pageTitle}</h2>
        <div className="relative hidden xl:block">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-mf-muted" />
          <input 
            type="text" 
            placeholder="Search transactions..." 
            className="w-72 rounded-xl bg-gray-50 border border-mf-border px-11 py-2.5 text-sm focus:outline-none focus:border-primary focus:bg-white transition-all text-mf-dark"
          />
        </div>
      </div>

      <div className="flex items-center gap-4">
        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-gray-50 border border-mf-border cursor-pointer hover:bg-gray-100 transition-all">
          <span className="text-[10px] font-bold text-mf-muted uppercase tracking-wider">Workspace:</span>
          <span className="text-xs font-bold text-mf-dark">Personal Ledger</span>
          <ChevronDown className="h-4 w-4 text-mf-muted" />
        </div>

        <button className="relative p-2.5 rounded-xl border border-mf-border text-mf-muted hover:text-mf-dark hover:bg-gray-50 transition-all">
          <Bell className="h-5 w-5" />
          <span className="absolute top-2.5 right-2.5 h-2 w-2 rounded-full bg-success border-2 border-white"></span>
        </button>

        <div className="flex items-center gap-3 pl-4 border-l border-mf-border">
          <div className="text-right hidden sm:block">
            <p className="text-sm font-bold text-mf-dark leading-none">Surag Ms</p>
            <p className="text-[10px] font-bold text-mf-muted uppercase tracking-wider mt-1">Upgrade To Pro</p>
          </div>
          <div className="h-10 w-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary text-sm font-bold border border-primary/20">
            SM
          </div>
        </div>
      </div>
    </header>
  );
}

