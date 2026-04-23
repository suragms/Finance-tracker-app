'use client';

import { Plus, Landmark, Wallet, CreditCard, ArrowUpRight, ShieldCheck, Zap, Globe } from 'lucide-react';
import { useState } from 'react';

const mockAccounts = [
  { id: '1', name: 'HDFC Savings', balance: 145000, color: '#8B7DFF', icon: Landmark, type: 'CUSTODIAN' },
  { id: '2', name: 'ICICI Platinum', balance: -12000, color: '#F07070', icon: CreditCard, type: 'CREDIT' },
  { id: '3', name: 'Personal Wallet', balance: 4500, color: '#22C697', icon: Wallet, type: 'CASH' },
  { id: '4', name: 'Paytm Wallet', balance: 2800, color: '#667EEA', icon: Wallet, type: 'DIGITAL' },
  { id: '5', name: 'Federal Reserve', balance: 85200, color: '#FFD166', icon: Landmark, type: 'CUSTODIAN' },
  { id: '6', name: 'Crypto Ledger', balance: 12400, color: '#8B7DFF', icon: ShieldCheck, type: 'ASSET' },
];

export default function AccountsPage() {
  return (
    <div className="space-y-12 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h3 className="text-3xl font-black text-white tracking-widest uppercase mb-1">Liquidity</h3>
          <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.3em]">Capital Distribution Vectors</p>
        </div>
        <button className="flex items-center gap-3 px-8 py-4 rounded-2xl bg-mf-accent text-white hover:scale-[1.02] shadow-neon-purple shadow-mf-accent/30 transition-all text-[10px] font-black uppercase tracking-[0.2em]">
          <Plus className="h-4 w-4" />
          Initialize Source
        </button>
      </div>

      {/* GRID: 4 Columns on Large Screens */}
      <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {mockAccounts.map((acc) => (
          <div key={acc.id} className="relative group cursor-pointer overflow-hidden transition-all duration-500 hover:scale-[1.02] active:scale-[0.98]">
            {/* Visual Backglow */}
            <div 
              className="absolute -inset-2 rounded-[32px] opacity-0 group-hover:opacity-20 blur-2xl transition-all duration-700"
              style={{ background: acc.color }}
            />
            
            <div className="relative glass-card rounded-[32px] p-8 h-full flex flex-col justify-between border-white/[0.03] group-hover:bg-white/[0.06] transition-all duration-500">
              <div className="flex justify-between items-start mb-10">
                <div 
                  className="h-14 w-14 rounded-2xl flex items-center justify-center border transition-all duration-500 shadow-xl"
                  style={{ 
                    backgroundColor: `${acc.color}11`, 
                    borderColor: `${acc.color}33`,
                    color: acc.color 
                  }}
                >
                  <acc.icon className="h-7 w-7" />
                </div>
                <div className="h-1.5 w-1.5 rounded-full bg-mf-success animate-pulse shadow-[0_0_8px_rgba(34,198,151,0.5)]" title="Synchronized" />
              </div>

              <div>
                <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.2em] mb-2">{acc.name}</p>
                <div className="flex items-baseline gap-2">
                  <h4 className="text-2xl font-black text-white tracking-widest leading-none">₹{Math.abs(acc.balance).toLocaleString('en-IN')}</h4>
                  {acc.balance < 0 && <span className="text-mf-error text-[9px] font-black uppercase tracking-widest mt-1">Due</span>}
                </div>
                <p className="text-[10px] font-black text-mf-muted/40 uppercase tracking-[0.2em] mt-3">{acc.type}</p>
              </div>

              <div className="mt-10 flex items-center justify-between">
                <div className="flex gap-2">
                   <Zap className="h-3 w-3 text-mf-accent opacity-30 group-hover:opacity-100 transition-all" />
                   <Globe className="h-3 w-3 text-mf-muted opacity-30 group-hover:opacity-100 transition-all" />
                </div>
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/5 border border-white/5 text-white opacity-0 group-hover:opacity-100 transition-all translate-x-4 group-hover:translate-x-0 group-hover:bg-mf-accent group-hover:shadow-neon-purple">
                  <ArrowUpRight className="h-5 w-5" />
                </div>
              </div>
            </div>
          </div>
        ))}

        {/* CONNECTION PROTOCOL CARD */}
        <div className="rounded-[32px] border-2 border-dashed border-white/10 flex flex-col items-center justify-center gap-4 p-8 text-mf-muted hover:border-mf-accent/50 hover:text-white hover:bg-white/[0.02] transition-all duration-500 cursor-pointer group h-full min-h-[260px]">
          <div className="h-16 w-16 rounded-full border-2 border-dashed border-white/20 flex items-center justify-center group-hover:border-mf-accent group-hover:bg-mf-accent/10 transition-all duration-500 group-hover:rotate-90">
            <Plus className="h-8 w-8" />
          </div>
          <p className="font-black text-[10px] uppercase tracking-[0.3em] text-center px-4 leading-relaxed">Connect New Source</p>
        </div>
      </div>
    </div>
  );
}
