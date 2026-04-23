'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  BarChart3, 
  CreditCard, 
  History, 
  LayoutDashboard, 
  LogOut, 
  PieChart, 
  Settings, 
  Wallet,
  Tags
} from 'lucide-react';

const navigationItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/dashboard/transactions', label: 'Transactions', icon: History },
  { href: '/dashboard/categories', label: 'Categories', icon: Tags },
  { href: '/dashboard/reports', label: 'Reports', icon: PieChart },
  { href: '/dashboard/accounts', label: 'Accounts', icon: Wallet },
  { href: '/dashboard/settings', label: 'Settings', icon: Settings },
];

export function Sidebar({ onLogout }: { onLogout: () => void }) {
  const path = usePathname();

  return (
    <aside className="glass-sidebar fixed left-0 top-0 hidden h-screen w-72 flex-col lg:flex overflow-hidden">
      <div className="flex h-24 items-center gap-3 px-8">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-mf-accent shadow-neon-purple">
          <Wallet className="h-6 w-6 text-white" />
        </div>
        <div>
          <h1 className="text-xl font-extrabold tracking-tight text-white">MoneyFlow <span className="text-mf-accent">AI</span></h1>
          <p className="text-[10px] font-bold uppercase tracking-widest text-mf-muted opacity-60">Wealth Management</p>
        </div>
      </div>

      <nav className="flex-1 space-y-2 px-6 py-4 overflow-y-auto">
        {navigationItems.map((item) => {
          const isActive = item.href === '/dashboard' 
            ? path === '/dashboard'
            : path === item.href || path.startsWith(item.href + '/');
          
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`nav-item ${isActive ? 'nav-item-active' : ''}`}
            >
              <item.icon className={`h-5 w-5 ${isActive ? 'text-mf-accent' : ''}`} />
              <span className="font-semibold tracking-wide">{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="p-6 border-t border-mf-border/30">
        <button
          onClick={onLogout}
          className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-mf-error hover:bg-mf-error/10 transition-all duration-300"
        >
          <LogOut className="h-5 w-5" />
          <span className="font-bold tracking-wide">Sign Out</span>
        </button>
      </div>
    </aside>
  );
}
