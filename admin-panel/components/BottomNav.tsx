'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  ArrowDownRight, 
  PieChart, 
  User,
  Plus
} from 'lucide-react';


export function BottomNav({ onAddClick }: { onAddClick?: () => void }) {
  const path = usePathname();

  const navItems = [
    { href: '/dashboard', label: 'Home', icon: LayoutDashboard },
    { href: '/dashboard/expenses', label: 'Expenses', icon: ArrowDownRight },
    { href: '/dashboard/reports', label: 'Reports', icon: PieChart },
    { href: '/dashboard/settings', label: 'Profile', icon: User },
  ];


  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-gray-200 h-16 safe-bottom flex justify-around items-center">
      <NavItem item={navItems[0]} isActive={path === '/dashboard'} />
      <NavItem item={navItems[1]} isActive={path === '/dashboard/transactions'} />
      
      {/* Central Add Button */}
      <button 
        onClick={onAddClick}
        className="relative -top-5 h-14 w-14 rounded-full bg-indigo-600 text-white shadow-lg shadow-indigo-200 flex items-center justify-center active:scale-95 transition-all"
      >
        <Plus className="h-7 w-7" />
      </button>

      <NavItem item={navItems[2]} isActive={path === '/dashboard/reports'} />
      <NavItem item={navItems[3]} isActive={path === '/dashboard/settings'} />
    </nav>
  );
}

function NavItem({ item, isActive }: { item: any, isActive: boolean }) {
  return (
    <Link
      href={item.href}
      className={`flex flex-col items-center gap-1 transition-all flex-1 ${isActive ? 'text-indigo-600' : 'text-gray-400'}`}
    >
      <item.icon className={`h-5 w-5 ${isActive ? 'stroke-[2.5px]' : 'stroke-[2px]'}`} />
      <span className="text-[10px] font-bold uppercase tracking-wider">{item.label}</span>
    </Link>
  );
}


