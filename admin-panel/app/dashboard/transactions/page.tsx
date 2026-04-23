'use client';

import { apiFetch,getToken } from '@/lib/api';
import { Search, Filter, Download, ChevronLeft, ChevronRight, Activity, CreditCard, X, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import { useState, useMemo, useEffect } from 'react';

type Transaction = {
  id: string;
  date: string;
  category: string;
  amount: number;
  type: 'income' | 'expense';
  account: string;
  note?: string;
};

export default function TransactionsPage() {
  const [search, setSearch] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [typeFilter, setTypeFilter] = useState('All');
  const [accountFilter, setAccountFilter] = useState('All');
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [expenses, incomes] = await Promise.all([
          apiFetch<any[]>('/expenses', { token: getToken() }),
          apiFetch<any[]>('/incomes', { token: getToken() }),
        ]);

        const merged: Transaction[] = [
          ...expenses.map(e => ({
            id: e.id,
            date: e.date,
            category: e.category?.name || 'Expense',
            amount: Number(e.amount),
            type: 'expense' as const,
            account: e.account?.name || 'Unknown',
            note: e.note
          })),
          ...incomes.map(i => ({
            id: i.id,
            date: i.date,
            category: i.source || 'Income',
            amount: Number(i.amount),
            type: 'income' as const,
            account: i.account?.name || 'Unknown',
            note: i.note
          }))
        ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

        setTransactions(merged);
      } catch (err) {
        console.error('Failed to fetch transactions', err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const accountsList = useMemo(() => {
    const sets = new Set(transactions.map(t => t.account));
    return ['All', ...Array.from(sets)];
  }, [transactions]);

  const filtered = useMemo(() => {
    return transactions.filter(tx => {
      const matchesSearch = tx.category.toLowerCase().includes(search.toLowerCase()) || 
                           (tx.note || '').toLowerCase().includes(search.toLowerCase()) ||
                           tx.account.toLowerCase().includes(search.toLowerCase());
      const matchesType = typeFilter === 'All' || tx.type === typeFilter.toLowerCase();
      const matchesAccount = accountFilter === 'All' || tx.account === accountFilter;
      return matchesSearch && matchesType && matchesAccount;
    });
  }, [search, typeFilter, accountFilter, transactions]);

  const formatCurrency = (val: number) => {
    const isNegative = val < 0;
    const absVal = Math.abs(val);
    const formatted = new Intl.NumberFormat('en-IN', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(absVal);
    return `${isNegative ? '-' : ''}₹${formatted}`;
  };

  return (
    <div className="space-y-8 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Transactions</h1>
          <p className="text-mf-muted text-sm mt-1">Manage and track all your financial activities.</p>
        </div>
        <button className="btn-secondary h-11 text-sm bg-white">
          <Download className="h-4 w-4" />
          Export Data
        </button>
      </div>

      {/* Search and Filters */}
      <div className="bg-white border border-mf-border p-4 rounded-2xl shadow-sm flex flex-col lg:flex-row gap-4 items-center">
        <div className="relative flex-1 w-full">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-mf-muted" />
          <input 
            type="text" 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search transactions..." 
            className="w-full rounded-xl bg-gray-50 border border-mf-border px-11 py-2.5 text-sm outline-none focus:border-primary focus:bg-white transition-all text-mf-dark"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-4 top-1/2 -translate-y-1/2 text-mf-muted hover:text-mf-dark">
              <X className="h-4 w-4" />
            </button>
          )}
        </div>

        <div className="flex gap-3 w-full lg:w-auto">
          <button 
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl border text-sm font-semibold transition-all ${showFilters ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-white border-mf-border text-mf-dark hover:bg-gray-50'}`}
          >
            <Filter className="h-4 w-4" />
            Filters
          </button>

        </div>
      </div>

      {/* Advanced Filters */}
      {showFilters && (
        <div className="bg-white border border-mf-border rounded-2xl p-6 grid grid-cols-1 md:grid-cols-2 gap-6 shadow-sm animate-in fade-in slide-in-from-top-2 duration-300">
          <FilterGroup 
            label="Transaction Type" 
            value={typeFilter} 
            onChange={setTypeFilter} 
            options={['All', 'Income', 'Expense']} 
          />
          <FilterGroup 
            label="Account Source" 
            value={accountFilter} 
            onChange={setAccountFilter} 
            options={accountsList} 
          />
        </div>
      )}

      {/* Transactions Table */}
      <div className="bg-white border border-mf-border rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="py-20 flex flex-col items-center justify-center gap-4">
             <div className="h-8 w-8 border-3 border-primary border-t-transparent rounded-full animate-spin" />
             <p className="text-sm font-medium text-mf-muted">Fetching transactions...</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="premium-table">
              <thead>
                <tr>
                  <th className="pl-8">Date</th>
                  <th>Description</th>
                  <th>Category</th>
                  <th>Account</th>
                  <th className="text-right pr-8">Amount</th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-20 text-center">
                      <p className="text-mf-muted font-medium text-sm">No transactions found</p>
                    </td>
                  </tr>
                ) : (
                  filtered.map((tx) => (
                    <tr key={tx.id} className="hover:bg-gray-50/50 transition-all">
                      <td className="pl-8">
                         <span className="text-mf-muted text-xs font-semibold uppercase">{new Date(tx.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}</span>
                      </td>
                      <td>
                        <p className="text-sm font-bold text-mf-dark">{tx.note || tx.category}</p>
                      </td>
                      <td>
                        <span className={`px-2.5 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider ${tx.type === 'income' ? 'bg-green-50 text-green-600' : 'bg-amber-50 text-amber-600'}`}>
                          {tx.category}
                        </span>
                      </td>
                      <td>
                        <div className="flex items-center gap-2 text-mf-muted">
                           <CreditCard className="h-3.5 w-3.5" />
                           <span className="text-xs font-medium uppercase">{tx.account}</span>
                        </div>
                      </td>
                      <td className={`text-right pr-8 font-bold text-sm ${tx.type === 'income' ? 'text-green-600' : 'text-gray-900'}`}>
                        {tx.type === 'income' ? '+' : '-'}{formatCurrency(tx.amount).replace(/^-/, '')}
                      </td>
                    </tr>
                  ))

                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Info Footer */}
        {!loading && filtered.length > 0 && (
          <div className="px-8 py-4 bg-gray-50/50 border-t border-mf-border flex items-center justify-between">
            <p className="text-[11px] font-bold text-mf-muted uppercase tracking-wider">
              Showing {filtered.length} transactions
            </p>
            <div className="flex gap-2">
              <button className="p-2 rounded-lg border border-mf-border bg-white text-mf-muted hover:text-mf-dark disabled:opacity-30" disabled>
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button className="p-2 rounded-lg border border-mf-border bg-white text-mf-muted hover:text-mf-dark disabled:opacity-30" disabled>
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function FilterGroup({ label, value, options, onChange }: { label: string, value: string, options: string[], onChange: (v: string) => void }) {
  return (
    <div className="space-y-3">
      <label className="text-[10px] font-bold uppercase tracking-wider text-mf-muted">{label}</label>
      <div className="flex flex-wrap gap-2">
        {options.map(opt => (
          <button
            key={opt}
            onClick={() => onChange(opt)}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all ${value === opt ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-mf-muted hover:bg-gray-200'}`}
          >
            {opt}
          </button>
        ))}
      </div>
    </div>
  );
}

