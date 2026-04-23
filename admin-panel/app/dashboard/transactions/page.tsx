'use client';

import { Search, Filter, Download, ChevronLeft, ChevronRight, Activity, CreditCard, X } from 'lucide-react';
import { useState, useMemo } from 'react';

const mockTransactions = [
  { id: '1', date: '2026-04-21', category: 'Shopping', account: 'HDFC Bank', amount: 1250, type: 'expense' },
  { id: '2', date: '2026-04-20', category: 'Salary', account: 'Wallet', amount: 45000, type: 'income' },
  { id: '3', date: '2026-04-19', category: 'Food & Dining', account: 'ICICI Credit', amount: 840, type: 'expense' },
  { id: '4', date: '2026-04-18', category: 'Rent', account: 'HDFC Bank', amount: 15000, type: 'expense' },
  { id: '5', date: '2026-04-17', category: 'Freelance', account: 'Paypal', amount: 12000, type: 'income' },
  { id: '6', date: '2026-04-16', category: 'Utilities', account: 'HDFC Bank', amount: 3200, type: 'expense' },
  { id: '7', date: '2026-04-15', category: 'Entertainment', account: 'HDFC Bank', amount: 1200, type: 'expense' },
  { id: '8', date: '2026-04-14', category: 'Investment', account: 'Zerodha', amount: 10000, type: 'expense' },
];

export default function TransactionsPage() {
  const [search, setSearch] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [typeFilter, setTypeFilter] = useState('All');
  const [accountFilter, setAccountFilter] = useState('All');

  const filtered = useMemo(() => {
    return mockTransactions.filter(tx => {
      const matchesSearch = tx.category.toLowerCase().includes(search.toLowerCase()) || 
                           tx.account.toLowerCase().includes(search.toLowerCase());
      const matchesType = typeFilter === 'All' || tx.type === typeFilter.toLowerCase();
      const matchesAccount = accountFilter === 'All' || tx.account === accountFilter;
      return matchesSearch && matchesType && matchesAccount;
    });
  }, [search, typeFilter, accountFilter]);

  return (
    <div className="space-y-8 pb-12">
      {/* Search and Filters Shell */}
      <div className="flex flex-col xl:flex-row gap-6 items-center justify-between bg-white/[0.02] border border-white/5 p-6 rounded-3xl backdrop-blur-md">
        <div className="relative w-full xl:w-[450px]">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-mf-muted group-focus-within:text-mf-accent transition-all" />
          <input 
            type="text" 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by category or account..." 
            className="w-full rounded-2xl bg-white/5 border border-white/10 px-12 py-3.5 text-sm font-bold text-white outline-none focus:border-mf-accent/50 focus:bg-white/[0.08] transition-all placeholder:text-mf-muted/50"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-4 top-1/2 -translate-y-1/2 text-mf-muted hover:text-white transition-all">
              <X className="h-4 w-4" />
            </button>
          )}
        </div>

        <div className="flex w-full xl:w-auto gap-4">
          <button 
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center gap-2 px-6 py-3.5 rounded-2xl border transition-all text-xs font-black uppercase tracking-[0.2em] ${showFilters ? 'bg-mf-accent text-white border-mf-accent' : 'bg-white/5 border-white/10 text-mf-muted hover:bg-white/10 hover:text-white'}`}
          >
            <Filter className="h-4 w-4" />
            Advanced
          </button>
          
          <button className="flex items-center gap-2 px-6 py-3.5 rounded-2xl bg-white/5 border border-white/10 text-white font-black text-xs uppercase tracking-[0.2em] hover:bg-white/10 transition-all">
            <Download className="h-4 w-4" />
            Export
          </button>
        </div>
      </div>

      {/* Advanced Filters Panel */}
      {showFilters && (
        <div className="glass-card rounded-3xl p-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 animate-in fade-in slide-in-from-top-4 duration-500">
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
            options={['All', 'HDFC Bank', 'ICICI Credit', 'Wallet', 'Paypal', 'Zerodha']} 
          />
          <div className="md:col-span-2 flex flex-col justify-end pb-1">
             <button 
               onClick={() => {setTypeFilter('All'); setAccountFilter('All'); setSearch('');}}
               className="text-[10px] font-black text-mf-accent uppercase tracking-[0.3em] hover:underline"
             >
               Reset All Parameters
             </button>
          </div>
        </div>
      )}

      {/* Transactions Table Body */}
      <div className="glass-card rounded-3xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="premium-table">
            <thead>
              <tr className="bg-white/[0.01]">
                <th className="pl-8">Date</th>
                <th>Category</th>
                <th>Account</th>
                <th className="text-right pr-8">Amount</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={4} className="py-20 text-center">
                    <p className="text-mf-muted font-bold text-sm italic uppercase tracking-widest opacity-50">No transactions match your criteria</p>
                  </td>
                </tr>
              ) : (
                filtered.map((tx) => (
                  <tr key={tx.id} className="group transition-all">
                    <td className="pl-8">
                       <span className="text-mf-muted text-xs font-black tracking-widest uppercase">{tx.date}</span>
                    </td>
                    <td>
                      <div className="flex items-center gap-4">
                        <div className={`h-10 w-10 rounded-xl flex items-center justify-center border border-white/5 transition-all group-hover:scale-110 ${tx.type === 'income' ? 'bg-mf-success/10 text-mf-success' : 'bg-mf-error/10 text-mf-error'}`}>
                          <Activity className="h-5 w-5" />
                        </div>
                        <span className="font-black text-white text-sm tracking-tight">{tx.category}</span>
                      </div>
                    </td>
                    <td>
                      <div className="flex items-center gap-2 opacity-70 group-hover:opacity-100 transition-all">
                         <CreditCard className="h-4 w-4 text-mf-muted" />
                         <span className="text-mf-muted text-xs font-black uppercase tracking-tighter">{tx.account}</span>
                      </div>
                    </td>
                    <td className={`text-right pr-8 font-black text-base ${tx.type === 'income' ? 'text-mf-success' : 'text-white'}`}>
                      {tx.type === 'income' ? '+' : '-'} ₹{tx.amount.toLocaleString('en-IN')}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Console */}
        {filtered.length > 0 && (
          <div className="px-8 py-6 flex items-center justify-between border-t border-white/5">
            <div className="flex items-center gap-4">
               <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.2em]">
                Page <span className="text-white">01</span> of <span className="text-white">16</span>
              </p>
            </div>
            <div className="flex gap-3">
              <button className="flex items-center gap-2 px-4 py-2 rounded-xl border border-white/10 text-mf-muted hover:text-white hover:bg-white/5 transition-all text-[10px] font-black uppercase tracking-widest">
                <ChevronLeft className="h-4 w-4" />
                Prev
              </button>
              <button className="flex items-center gap-2 px-4 py-2 rounded-xl bg-mf-accent text-white hover:bg-mf-accent/90 transition-all text-[10px] font-black uppercase tracking-widest shadow-neon-purple shadow-mf-accent/40">
                Next
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
      <label className="text-[10px] font-black uppercase tracking-[0.2em] text-mf-muted pl-1">{label}</label>
      <div className="flex flex-wrap gap-2">
        {options.map(opt => (
          <button
            key={opt}
            onClick={() => onChange(opt)}
            className={`px-3 py-1.5 rounded-lg text-[10px] font-black uppercase tracking-widest transition-all ${value === opt ? 'bg-mf-accent text-white shadow-neon-purple shadow-mf-accent/30' : 'bg-white/5 text-mf-muted border border-white/5 hover:bg-mf-white/10 hover:text-white'}`}
          >
            {opt}
          </button>
        ))}
      </div>
    </div>
  );
}
