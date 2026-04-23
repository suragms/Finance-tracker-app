'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  History, 
  LayoutDashboard, 
  LogOut, 
  PieChart, 
  Settings, 
  Wallet,
  Tags,
  Users,
  Target,
  RefreshCw,
  ArrowDownRight
} from 'lucide-react';



const navigationItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/dashboard/expenses', label: 'Expenses', icon: ArrowDownRight },
  { href: '/dashboard/accounts', label: 'Accounts', icon: Wallet },
  { href: '/dashboard/recurring', label: 'Recurring', icon: RefreshCw },
  { href: '/dashboard/transactions', label: 'History', icon: History },
  { href: '/dashboard/categories', label: 'Categories', icon: Tags },
  { href: '/dashboard/budgets', label: 'Budgets', icon: Target },
  { href: '/dashboard/reports', label: 'Reports', icon: PieChart },
  { href: '/dashboard/users', label: 'Users', icon: Users },
  { href: '/dashboard/settings', label: 'Settings', icon: Settings },
];




export function Sidebar({ onLogout }: { onLogout: () => void }) {
  const path = usePathname();

  return (
    <aside className="fixed left-0 top-0 hidden h-screen w-72 flex-col lg:flex overflow-hidden bg-white border-r border-mf-border z-40">
      <div className="flex h-20 items-center gap-3 px-8 border-b border-mf-border mb-4">
        <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-600">
          <Wallet className="h-5 w-5 text-white" />
        </div>
        <div>
          <h1 className="text-lg font-bold tracking-tight text-mf-dark">MoneyFlow AI</h1>

          <p className="text-[10px] font-bold uppercase tracking-wider text-mf-muted">Business Tracker</p>
        </div>
      </div>

      <nav className="flex-1 space-y-1 px-4 py-4 overflow-y-auto">
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
              <item.icon className="h-5 w-5" />
              <span className="text-sm font-semibold">{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-mf-border">
        <button
          onClick={onLogout}
          className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-mf-muted hover:text-error hover:bg-error/5 transition-all duration-200"
        >
          <LogOut className="h-5 w-5" />
          <span className="text-sm font-semibold">Sign Out</span>
        </button>
      </div>
    </aside>
  );
}

