'use client';

import { Plus, Calendar, Clock, ArrowRight, MoreHorizontal, RefreshCw, Zap, Bell } from 'lucide-react';
import { useState } from 'react';

const mockRecurring = [
  { id: '1', name: 'Netflix Premium', amount: 649, frequency: 'Monthly', nextDate: '24 Apr 2026', category: 'Entertainment', status: 'Active' },
  { id: '2', name: 'Office Rent', amount: 25000, frequency: 'Monthly', nextDate: '01 May 2026', category: 'Rent', status: 'Active' },
  { id: '3', name: 'AWS Cloud Services', amount: 12500, frequency: 'Monthly', nextDate: '15 May 2026', category: 'Software', status: 'Active' },
  { id: '4', name: 'Gym Membership', amount: 2500, frequency: 'Monthly', nextDate: '10 May 2026', category: 'Health', status: 'Paused' },
  { id: '5', name: 'GitHub Pro', amount: 840, frequency: 'Yearly', nextDate: '12 Dec 2026', category: 'Software', status: 'Active' },
];

export default function RecurringPage() {
  const [showAddModal, setShowAddModal] = useState(false);

  return (
    <div className="space-y-12 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h3 className="text-3xl font-black text-white tracking-widest uppercase mb-1">Subscriptions</h3>
          <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.3em]">Automated Financial Obligations</p>
        </div>
        <button 
          onClick={() => setShowAddModal(true)}
          className="flex items-center gap-3 px-8 py-4 rounded-2xl bg-mf-accent text-white hover:scale-[1.02] shadow-neon-purple shadow-mf-accent/30 transition-all text-[10px] font-black uppercase tracking-[0.2em]"
        >
          <Plus className="h-4 w-4" />
          Add Recurring
        </button>
      </div>

      {/* QUICK SUMMARY CARDS */}
      <div className="grid gap-6 grid-cols-1 md:grid-cols-3">
         <SummaryTile label="Total Commit" value="₹41,489" icon={RefreshCw} trend="Per Month" color="mf-accent" />
         <SummaryTile label="Active Streams" value="12" icon={Zap} trend="Obligations" color="mf-success" />
         <SummaryTile label="Upcoming (7d)" value="₹2,450" icon={Bell} trend="Approaching" color="mf-error" />
      </div>

      {/* LIST: Recurring Items */}
      <div className="space-y-4">
        {mockRecurring.map((item) => (
          <div key={item.id} className="group glass-card rounded-[28px] p-1 border-white/[0.02] hover:border-white/10 transition-all duration-500 hover:bg-white/[0.04]">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 p-7">
               {/* NAME & IDENTITY */}
               <div className="flex items-center gap-6 lg:w-[30%]">
                  <div className="h-14 w-14 rounded-2xl bg-white/[0.03] border border-white/5 flex items-center justify-center text-mf-accent transition-all group-hover:scale-110 group-hover:bg-mf-accent/10 group-hover:border-mf-accent/30">
                     <Calendar className="h-6 w-6" />
                  </div>
                  <div>
                    <h4 className="text-base font-black text-white tracking-tight uppercase">{item.name}</h4>
                    <p className="text-[10px] font-black text-mf-muted uppercase tracking-widest mt-1 opacity-60">{item.category}</p>
                  </div>
               </div>

               {/* FREQUENCY & DATA */}
               <div className="flex items-center gap-12 lg:w-[40%]">
                  <div className="space-y-1">
                    <p className="text-[9px] font-black text-mf-muted uppercase tracking-[0.2em]">Frequency</p>
                    <span className="inline-flex items-center gap-2 px-3 py-1 rounded-lg bg-white/5 border border-white/5 text-[10px] font-black text-white tracking-widest uppercase">
                       <Clock className="h-3 w-3 text-mf-accent" />
                       {item.frequency}
                    </span>
                  </div>

                  <div className="space-y-1">
                    <p className="text-[9px] font-black text-mf-muted uppercase tracking-[0.2em]">Next Maturity</p>
                    <p className="text-xs font-black text-white uppercase tracking-widest">{item.nextDate}</p>
                  </div>

                  <div className="hidden xl:block space-y-1">
                    <p className="text-[9px] font-black text-mf-muted uppercase tracking-[0.2em]">Health</p>
                    <div className="flex items-center gap-2">
                       <div className={`h-1.5 w-1.5 rounded-full ${item.status === 'Active' ? 'bg-mf-success animate-pulse' : 'bg-mf-muted'}`} />
                       <span className="text-[10px] font-black text-white uppercase tracking-widest">{item.status}</span>
                    </div>
                  </div>
               </div>

               {/* AMOUNT & ACTIONS */}
               <div className="flex items-center justify-between lg:justify-end gap-12 lg:w-[30%] border-t lg:border-t-0 border-white/5 pt-6 lg:pt-0">
                  <div className="text-right">
                    <p className="text-[9px] font-black text-mf-muted uppercase tracking-[0.2em] mb-1">Maturity Amount</p>
                    <p className="text-2xl font-black text-white tracking-tighter">₹{item.amount.toLocaleString('en-IN')}</p>
                  </div>
                  <div className="flex items-center gap-3">
                     <button className="h-10 w-10 rounded-xl bg-white/5 flex items-center justify-center text-mf-muted hover:text-white hover:bg-white/10 transition-all">
                        <MoreHorizontal className="h-5 w-5" />
                     </button>
                     <button className="h-10 w-10 rounded-xl bg-mf-accent/10 border border-mf-accent/20 flex items-center justify-center text-mf-accent hover:bg-mf-accent hover:text-white transition-all shadow-neon-purple shadow-mf-accent/20">
                        <ArrowRight className="h-5 w-5" />
                     </button>
                  </div>
               </div>
            </div>
          </div>
        ))}
      </div>

      {/* ADAPTIVE EMPTY STATE (Placeholder for logic) */}
      {mockRecurring.length === 0 && (
         <div className="flex flex-col items-center justify-center py-32 glass-card rounded-[40px] border-dashed">
            <RefreshCw className="h-16 w-16 text-mf-muted/20 mb-6 animate-spin-slow" />
            <h3 className="text-xl font-black text-white tracking-widest uppercase mb-2">Zero Obligations</h3>
            <p className="text-xs font-bold text-mf-muted uppercase tracking-widest">Your financial automation is waiting for input.</p>
         </div>
      )}
    </div>
  );
}

function SummaryTile({ label, value, icon: Icon, trend, color }: { label: string, value: string, icon: any, trend: string, color: string }) {
  return (
    <div className="glass-card rounded-[32px] p-8 group overflow-hidden relative">
      <div className={`absolute -right-6 -top-6 h-24 w-24 rounded-full bg-${color}/5 blur-[40px] transition-all group-hover:scale-150`} />
      <div className="relative z-10">
        <div className="flex items-center justify-between mb-6">
           <div className={`p-4 rounded-2xl bg-${color}/10 border border-${color}/20 text-${color}`}>
              <Icon className="h-6 w-6" />
           </div>
           <span className="text-[10px] font-black text-mf-muted uppercase tracking-[0.2em] opacity-40 group-hover:opacity-100 transition-all">{trend}</span>
        </div>
        <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.3em] mb-2">{label}</p>
        <h4 className="text-3xl font-black text-white tracking-widest">{value}</h4>
      </div>
    </div>
  );
}
