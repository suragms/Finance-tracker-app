'use client';

import { Sidebar } from '@/components/Sidebar';
import { Header } from '@/components/Header';
import { getToken, setToken } from '@/lib/api';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ok, setOk] = useState(false);

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
      <div className="flex min-h-screen items-center justify-center text-mf-muted bg-mf-bg">
        <div className="flex flex-col items-center gap-4">
          <div className="h-12 w-12 border-4 border-mf-accent border-t-transparent rounded-full animate-spin"></div>
          <p className="font-bold tracking-widest uppercase text-xs">MoneyFlow AI</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-mf-bg">
      <Sidebar onLogout={logout} />
      <div className="flex-1 lg:pl-72 flex flex-col min-h-screen">
        <Header />
        <main className="flex-1 w-full max-w-[1600px] mx-auto p-8 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
