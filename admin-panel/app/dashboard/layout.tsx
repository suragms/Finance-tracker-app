'use client';

import { Sidebar } from '@/components/Sidebar';
import { Header } from '@/components/Header';
import { BottomNav } from '@/components/BottomNav';
import AddTransactionModal from '@/components/AddTransactionModal';
import { getToken, setToken } from '@/lib/api';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Plus } from 'lucide-react';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ok, setOk] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    if (!getToken()) router.replace('/login');
    else setOk(true);
  }, [router]);

  function logout() {
    setToken(null);
    router.replace('/login');
  }

  if (!ok) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          <p className="font-bold tracking-wider text-sm text-mf-dark">MoneyFlow AI</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-gray-50 relative overflow-x-hidden">
      <Sidebar onLogout={logout} />
      <div className="flex-1 lg:pl-72 min-h-screen flex flex-col w-full max-w-full overflow-x-hidden">
        <Header />
        <main className="flex-1 w-full max-w-[1400px] mx-auto px-4 py-6 md:py-8 lg:px-8 mb-20 lg:mb-0">
          <div className="max-w-md mx-auto lg:max-w-none w-full">
            {children}
          </div>
        </main>
        <BottomNav onAddClick={() => setIsModalOpen(true)} />
      </div>

      {/* Global FAB - Hidden on mobile if integrated in BottomNav, or visible if floating */}

      <button 
        onClick={() => setIsModalOpen(true)}
        className="fixed bottom-24 right-6 lg:bottom-10 lg:right-10 h-14 w-14 lg:h-16 lg:w-16 rounded-full bg-primary text-white shadow-lg shadow-primary/30 flex items-center justify-center hover:scale-110 active:scale-95 transition-all z-50 group"
        aria-label="Add Transaction"
      >
        <Plus className="h-7 w-7 lg:h-8 lg:w-8 group-hover:rotate-90 transition-transform duration-300" />
      </button>

      {/* Global Transaction Modal */}
      <AddTransactionModal 
        isOpen={isModalOpen} 
        onClose={() => setIsModalOpen(false)} 
        onSuccess={() => {
           // We might need a way to refresh current page data
           // For now, partial page reloads or just assuming it worked
           router.refresh();
        }}
      />
    </div>
  );
}


