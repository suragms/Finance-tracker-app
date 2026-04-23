'use client';

import { apiFetch, getToken } from '@/lib/api';
import { useEffect, useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  Area,
  AreaChart,
} from 'recharts';
import { 
  ArrowDownRight, 
  ArrowUpRight, 
  Wallet, 
  Plus, 
  Download,
  MoreVertical,
  Activity,
  CreditCard
} from 'lucide-react';

type Overview = {
  cards: {
    totalTransactions: number;
    totalExpense: number;
    totalIncome: number;
    balance: number;
  };
  charts: {
    userGrowth: { month: string; count: number }[];
    dailyTransactions: { day: string; expenses: number; incomes: number }[];
  };
  recentTransactions: {
    id: string;
    date: string;
    category: string;
    account: string;
    amount: number;
    type: 'income' | 'expense';
  }[];
};

export default function DashboardPage() {
  const [data, setData] = useState<Overview | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    apiFetch<any>('/admin/dashboard/overview', { token: getToken() })
      .then((res) => {
        setData({
          cards: {
            totalTransactions: res.cards.totalTransactions,
            totalExpense: res.cards.totalExpense,
            totalIncome: res.cards.totalIncome,
            balance: res.cards.totalIncome - res.cards.totalExpense,
          },
          charts: {
            userGrowth: res.charts.userGrowth,
            dailyTransactions: res.charts.dailyTransactions,
          },
          recentTransactions: [
            { id: '1', date: '2026-04-21', category: 'Shopping', account: 'HDFC Bank', amount: 1250, type: 'expense' },
            { id: '2', date: '2026-04-20', category: 'Salary', account: 'Wallet', amount: 45000, type: 'income' },
            { id: '3', date: '2026-04-19', category: 'Food', account: 'ICICI Credit', amount: 840, type: 'expense' },
            { id: '4', date: '2026-04-18', category: 'Rent', account: 'HDFC Bank', amount: 15000, type: 'expense' },
            { id: '5', date: '2026-04-17', category: 'Freelance', account: 'Paypal', amount: 12000, type: 'income' },
            { id: '6', date: '2026-04-16', category: 'Utilities', account: 'HDFC Bank', amount: 3200, type: 'expense' },
          ]
        });
      })
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, []);

  if (err) return <div className="glass-card p-8 text-mf-error font-bold rounded-3xl">{err}</div>;
  
  if (!data) return (
    <div className="grid gap-6 grid-cols-1 md:grid-cols-3">
      {[1, 2, 3].map(i => (
        <div key={i} className="h-44 glass-card rounded-3xl animate-pulse bg-white/5" />
      ))}
    </div>
  );

  const { cards, charts, recentTransactions } = data;

  return (
    <div className="space-y-8 pb-12">
      {/* Top Banner / Welcome */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-3xl font-extrabold text-white tracking-tight">Financial Overview</h1>
          <p className="text-mf-muted font-medium mt-1">Real-time monitoring of your income, expenses and liquidity.</p>
        </div>
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-mf-accent text-white font-bold text-sm shadow-neon-purple hover:scale-105 transition-all">
            <Plus className="h-4 w-4" />
            Add Transaction
          </button>
          <button className="flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-white/5 border border-white/10 text-white font-bold text-sm hover:bg-white/10 transition-all">
            <Download className="h-4 w-4" />
            Report
          </button>
        </div>
      </div>

      {/* GRID: 3 cards (Income, Expense, Balance) */}
      <div className="grid gap-6 sm:grid-cols-3">
        <StatCard 
          label="Total Income" 
          value={cards.totalIncome} 
          icon={ArrowUpRight} 
          trend="+12.3%" 
          type="income"
        />
        <StatCard 
          label="Total Expenses" 
          value={cards.totalExpense} 
          icon={ArrowDownRight} 
          trend="-2.1%" 
          type="expense"
        />
        <StatCard 
          label="Total Balance" 
          value={cards.balance} 
          icon={Wallet} 
          trend="+5.4%" 
          type="balance"
        />
      </div>

      {/* CHARTS: Line + Bar */}
      <div className="grid gap-8 lg:grid-cols-2">
        {/* Line Chart (Area) */}
        <div className="glass-card rounded-3xl p-8">
          <div className="mb-8">
            <h3 className="text-lg font-extrabold text-white">Cash Flow Trend</h3>
            <p className="text-xs font-bold text-mf-muted uppercase tracking-widest mt-1">Historical Transaction Volume</p>
          </div>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={charts.dailyTransactions}>
                <defs>
                  <linearGradient id="colorLine" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#8B7DFF" stopOpacity={0.25}/>
                    <stop offset="95%" stopColor="#8B7DFF" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#ffffff08" vertical={false} />
                <XAxis dataKey="day" stroke="#8D93A1" fontSize={10} axisLine={false} tickLine={false} />
                <YAxis stroke="#8D93A1" fontSize={10} axisLine={false} tickLine={false} tickFormatter={(v: number) => `₹${v/1000}k`} />
                <Tooltip
                  contentStyle={{ background: '#0D0F1A', border: '1px solid #ffffff14', borderRadius: '16px', padding: '12px' }}
                />
                <Area type="monotone" dataKey="incomes" stroke="#8B7DFF" strokeWidth={3} fillOpacity={1} fill="url(#colorLine)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Bar Chart */}
        <div className="glass-card rounded-3xl p-8">
          <div className="mb-8">
            <h3 className="text-lg font-extrabold text-white">Daily Summary</h3>
            <p className="text-xs font-bold text-mf-muted uppercase tracking-widest mt-1">Revenue vs Burn Analysis</p>
          </div>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={charts.dailyTransactions}>
                <CartesianGrid strokeDasharray="3 3" stroke="#ffffff08" vertical={false} />
                <XAxis dataKey="day" stroke="#8D93A1" fontSize={10} axisLine={false} tickLine={false} />
                <YAxis stroke="#8D93A1" fontSize={10} axisLine={false} tickLine={false} />
                <Tooltip
                  cursor={{fill: 'rgba(255,255,255,0.03)'}}
                  contentStyle={{ background: '#0D0F1A', border: '1px solid #ffffff14', borderRadius: '16px' }}
                />
                <Bar dataKey="incomes" fill="#22C697" radius={[4, 4, 0, 0]} />
                <Bar dataKey="expenses" fill="#F07070" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* BOTTOM: Transactions table */}
      <div className="glass-card rounded-3xl overflow-hidden">
        <div className="px-8 py-8 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-extrabold text-white">Transactions</h3>
            <p className="text-xs font-bold text-mf-muted uppercase tracking-widest mt-1">Latest financial activity across all accounts</p>
          </div>
          <button className="px-6 py-2 rounded-xl bg-white/5 border border-white/10 text-xs font-bold text-white hover:bg-white/10 transition-all uppercase tracking-[0.2em]">
            View All
          </button>
        </div>
        
        <div className="overflow-x-auto">
          <table className="premium-table">
            <thead>
              <tr className="bg-white/[0.01]">
                <th>Date</th>
                <th>Source</th>
                <th>Category</th>
                <th>Method</th>
                <th>Status</th>
                <th>Amount</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {recentTransactions.map((tx) => (
                <tr key={tx.id} className="group transition-all">
                  <td className="text-mf-muted text-xs font-bold">{tx.date}</td>
                  <td>
                    <div className="flex items-center gap-3">
                      <div className={`h-9 w-9 rounded-xl flex items-center justify-center bg-white/5 border border-white/5 group-hover:bg-white/10 transition-all ${tx.type === 'income' ? 'text-mf-success' : 'text-mf-error'}`}>
                        <Activity className="h-4 w-4" />
                      </div>
                      <span className="font-extrabold text-white text-sm">{tx.category}</span>
                    </div>
                  </td>
                  <td>
                    <span className="text-mf-muted text-xs font-bold uppercase tracking-tighter">Regular</span>
                  </td>
                  <td>
                    <div className="flex items-center gap-2 text-mf-muted">
                      <CreditCard className="h-4 w-4" />
                      <span className="text-xs font-bold">{tx.account}</span>
                    </div>
                  </td>
                  <td>
                    <span className={`px-2 py-1 rounded-md text-[9px] font-black tracking-widest uppercase border ${tx.type === 'income' ? 'bg-mf-success/10 text-mf-success border-mf-success/20' : 'bg-mf-error/10 text-mf-error border-mf-error/20'}`}>
                      {tx.type === 'income' ? 'Success' : 'Pending'}
                    </span>
                  </td>
                  <td className={`font-black text-sm ${tx.type === 'income' ? 'text-mf-success' : 'text-white'}`}>
                    {tx.type === 'income' ? '+' : '-'} ₹{tx.amount.toLocaleString('en-IN')}
                  </td>
                  <td>
                    <button className="p-2 rounded-lg hover:bg-white/10 text-mf-muted transition-all">
                      <MoreVertical className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function StatCard({ 
  label, 
  value, 
  icon: Icon, 
  trend, 
  type 
}: { 
  label: string; 
  value: number; 
  icon: any; 
  trend: string;
  type: 'income' | 'expense' | 'balance';
}) {
  const isError = type === 'expense';
  const isSuccess = type === 'income';

  return (
    <div className={`glass-card rounded-3xl p-8 group transition-all duration-500 ${isError ? 'stat-card-error' : isSuccess ? 'stat-card-success' : ''}`}>
      <div className="flex justify-between items-start mb-6">
        <div className={`p-4 rounded-2xl border border-white/5 ${
          isError ? 'bg-mf-error/10 text-mf-error' : 
          isSuccess ? 'bg-mf-success/10 text-mf-success' : 
          'bg-mf-accent/10 text-mf-accent'
        }`}>
          <Icon className="h-5 w-5" />
        </div>
        <div className={`flex items-center gap-1 text-[10px] font-black px-2 py-1 rounded-lg border ${
          trend.startsWith('+') ? 'bg-mf-success/10 text-mf-success border-mf-success/20' : 'bg-mf-error/10 text-mf-error border-mf-error/20'
        }`}>
          {trend}
        </div>
      </div>
      <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.2em] mb-1.5">{label}</p>
      <h4 className="text-2xl font-black text-white tracking-widest">
        ₹{value.toLocaleString('en-IN')}
      </h4>
    </div>
  );
}
