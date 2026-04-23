'use client';

import { apiFetch, getToken } from '@/lib/api';
import { Plus, Landmark, Wallet, CreditCard, ArrowUpRight, ShieldCheck, Zap, Globe, MoreHorizontal } from 'lucide-react';
import { useState, useEffect } from 'react';

type Account = {
  id: string;
  name: string;
  balance: number;
  type: string;
  bankName?: string;
  currency: string;
};

export default function AccountsPage() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAccounts = async () => {
      try {
        const data = await apiFetch<Account[]>('/accounts', { token: getToken() });
        setAccounts(data);
      } catch (err) {
        console.error('Failed to fetch accounts', err);
      } finally {
        setLoading(false);
      }
    };
    fetchAccounts();
  }, []);

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(val);
  };

  const getStepIcon = (type: string) => {
    switch (type.toLowerCase()) {
      case 'savings':
      case 'bank': return Landmark;
      case 'credit': return CreditCard;
      default: return Wallet;
    }
  };

  return (
    <div className="space-y-8 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Bank Accounts</h1>
          <p className="text-mf-muted text-sm mt-1">Manage and monitor balances across all your financial sources.</p>
        </div>
        <button className="btn-primary h-12 px-6">
          <Plus className="h-5 w-5" />
          Add Account
        </button>
      </div>

      {loading ? (
        <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="h-52 bg-gray-100 animate-pulse rounded-2xl border border-mf-border" />
          ))}
        </div>
      ) : (
        <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
          {accounts.map((acc) => {
            const Icon = getStepIcon(acc.type);
            return (
              <div key={acc.id} className="group bg-white border border-mf-border rounded-2xl p-6 shadow-sm hover:shadow-md transition-all cursor-pointer">
                <div className="flex justify-between items-start mb-6">
                  <div className="h-12 w-12 rounded-xl bg-primary/5 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white transition-colors">
                    <Icon className="h-6 w-6" />
                  </div>
                  <button className="p-1.5 rounded-lg hover:bg-gray-50 text-mf-muted transition-colors">
                    <MoreHorizontal className="h-5 w-5" />
                  </button>
                </div>

                <div>
                  <p className="text-[11px] font-bold text-mf-muted uppercase tracking-wider mb-1">{acc.name}</p>
                  <h4 className={`text-xl font-bold tracking-tight ${acc.balance < 0 ? 'text-error' : 'text-mf-dark'}`}>
                    {formatCurrency(acc.balance)}
                  </h4>
                  <div className="mt-4 flex items-center gap-2">
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-gray-100 text-mf-muted border border-mf-border">
                      {acc.type}
                    </span>
                    {acc.bankName && <span className="text-[10px] font-medium text-mf-muted">{acc.bankName}</span>}
                  </div>
                </div>

                <div className="mt-8 pt-4 border-t border-mf-border/50 flex items-center justify-between opacity-0 group-hover:opacity-100 transition-opacity">
                   <span className="text-[11px] font-bold text-primary uppercase tracking-wider flex items-center gap-1">
                     View Transactions <ArrowUpRight className="h-3 w-3" />
                   </span>
                </div>
              </div>
            );
          })}

          <button className="rounded-2xl border-2 border-dashed border-mf-border flex flex-col items-center justify-center gap-3 p-6 text-mf-muted hover:border-primary hover:text-primary hover:bg-primary/5 transition-all group min-h-[200px]">
            <div className="h-12 w-12 rounded-full bg-gray-50 flex items-center justify-center group-hover:bg-primary/10 transition-all">
              <Plus className="h-6 w-6 text-mf-muted group-hover:text-primary" />
            </div>
            <p className="font-bold text-xs uppercase tracking-wider">Connect New Soruce</p>
          </button>
        </div>
      )}
    </div>
  );
}

