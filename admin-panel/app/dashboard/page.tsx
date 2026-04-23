'use client';

import { apiFetch, getToken } from '@/lib/api';
import { useEffect, useState } from 'react';
import {
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  Area,
  AreaChart,
  CartesianGrid
} from 'recharts';
import { 
  ArrowDownRight, 
  ArrowUpRight, 
  Download,
  Activity,
  TrendingUp,
} from 'lucide-react';

type Transaction = {
  id: string;
  date: string;
  category: string;
  amount: number;
  type: 'income' | 'expense';
  note?: string;
};

type Overview = {
  totalIncome: number;
  totalExpense: number;
  profit: number;
  recentTransactions: Transaction[];
  monthlyComparison: { month: string; income: number; expense: number }[];
};

export default function DashboardPage() {
  const [data, setData] = useState<Overview | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    apiFetch<Overview>('/dashboard/overview', { token: getToken() })
      .then((res) => {
        setData(res);
      })
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed to load dashboard'));
  }, []);

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

  if (err) return (
    <div className="p-8 text-error font-bold bg-error/5 border border-error/10 rounded-2xl flex items-center gap-3">
      <Activity className="h-5 w-5" />
      {err}
    </div>
  );
  
  if (!data) return (
    <div className="space-y-8 animate-pulse">
      <div className="h-10 w-48 bg-gray-100 rounded-lg" />
      <div className="grid gap-6 grid-cols-1 md:grid-cols-3">
        {[1, 2, 3].map(i => (
          <div key={i} className="h-36 bg-white rounded-2xl border border-mf-border shadow-sm" />
        ))}
      </div>
      <div className="h-80 bg-white rounded-2xl border border-mf-border shadow-sm" />
    </div>
  );

  return (
    <div className="space-y-8 pb-8">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Dashboard Overview</h1>
          <p className="text-mf-muted text-sm mt-1">Track your income, expenses and profit instantly.</p>
        </div>
        <button className="btn-secondary h-11 text-sm shadow-sm">
          <Download className="h-4 w-4" /> Export Data
        </button>
      </div>

      <div className="grid gap-6 sm:grid-cols-3">
        <StatCard label="Total Income" value={data.totalIncome} icon={ArrowUpRight} type="income" />
        <StatCard label="Total Expenses" value={data.totalExpense} icon={ArrowDownRight} type="expense" />
        <StatCard label="Net Profit" value={data.profit} icon={TrendingUp} type="profit" />
      </div>

      <div className="grid gap-8 lg:grid-cols-2">
        <div className="bg-white rounded-2xl border border-mf-border shadow-sm p-6">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h3 className="text-lg font-bold text-mf-dark">Cash Flow Velocity</h3>
              <p className="text-xs font-semibold text-mf-muted uppercase tracking-wider">Historical Comparison</p>
            </div>
            <div className="flex gap-4">
              <div className="flex items-center gap-1.5">
                <div className="h-2.5 w-2.5 rounded-full bg-success" />
                <span className="text-[10px] font-bold text-mf-muted uppercase tracking-widest">Income</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="h-2.5 w-2.5 rounded-full bg-primary" />
                <span className="text-[10px] font-bold text-mf-muted uppercase tracking-widest">Expenses</span>
              </div>
            </div>
          </div>
          <div className="h-[280px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data.monthlyComparison}>
                <defs>
                  <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10B981" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#10B981" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorExpense" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#4F46E5" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#4F46E5" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" vertical={false} />
                <XAxis dataKey="month" stroke="#9CA3AF" fontSize={11} axisLine={false} tickLine={false} />
                <YAxis stroke="#9CA3AF" fontSize={11} axisLine={false} tickLine={false} tickFormatter={(v) => `₹${v/1000}k`} />
                <Tooltip
                  contentStyle={{ background: '#fff', border: '1px solid #E5E7EB', borderRadius: '12px', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                  formatter={(value: number) => [formatCurrency(value), '']}
                />
                <Area type="monotone" dataKey="income" stroke="#10B981" strokeWidth={2.5} fillOpacity={1} fill="url(#colorIncome)" />
                <Area type="monotone" dataKey="expense" stroke="#4F46E5" strokeWidth={2.5} fillOpacity={1} fill="url(#colorExpense)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-mf-border shadow-sm p-6">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h3 className="text-lg font-bold text-mf-dark">Recent Transactions</h3>
              <p className="text-xs font-semibold text-mf-muted uppercase tracking-wider">Latest 5 items</p>
            </div>
            <button className="text-primary text-xs font-bold hover:underline py-1 px-3 rounded-lg hover:bg-primary/5">View All</button>
          </div>
          <div className="space-y-3">
            {data.recentTransactions.map((tx) => (
              <div key={tx.id} className="flex items-center justify-between p-3.5 rounded-xl hover:bg-gray-50 transition-all group border border-transparent hover:border-mf-border">
                <div className="flex items-center gap-4">
                  <div className={`h-11 w-11 rounded-xl flex items-center justify-center transition-transform group-hover:scale-110 ${tx.type === 'income' ? 'bg-success/10 text-success' : 'bg-gray-100 text-mf-muted'}`}>
                    {tx.type === 'income' ? <ArrowUpRight className="h-5 w-5" /> : <Activity className="h-5 w-5" />}
                  </div>
                  <div>
                    <p className="text-sm font-bold text-mf-dark leading-tight">{tx.category}</p>
                    <p className="text-[10px] text-mf-muted font-bold uppercase tracking-wider mt-1">{new Date(tx.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}</p>
                  </div>
                </div>
                <p className={`text-sm font-bold ${tx.type === 'income' ? 'text-success' : 'text-mf-dark'}`}>
                  {tx.type === 'income' ? '+' : '-'}{formatCurrency(tx.amount).replace(/^-/, '')}
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  function StatCard({ label, value, icon: Icon, type }: { label: string; value: number; icon: any; type: 'income' | 'expense' | 'profit' }) {
    const isError = type === 'expense';
    const isSuccess = type === 'income';
    return (
      <div className="bg-white rounded-2xl border border-mf-border shadow-sm p-6 hover:shadow-md transition-shadow">
        <div className="flex items-center gap-4 mb-4">
          <div className={`p-3 rounded-xl ${isError ? 'bg-error/10 text-error' : isSuccess ? 'bg-success/10 text-success' : 'bg-primary/10 text-primary'}`}>
            <Icon className="h-5 w-5" />
          </div>
          <p className="text-[11px] font-black text-mf-muted uppercase tracking-wider leading-none">{label}</p>
        </div>
        <h4 className="text-2xl font-bold text-mf-dark tracking-tight">{formatCurrency(value)}</h4>
        <div className="mt-4 h-1.5 w-full bg-gray-50 rounded-full overflow-hidden border border-mf-border/30">
          <div className={`h-full rounded-full ${isError ? 'bg-error' : isSuccess ? 'bg-success' : 'bg-primary'}`} style={{ width: '70%', opacity: 0.8 }} />
        </div>
      </div>
    );
  }
}
