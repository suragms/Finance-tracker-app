'use client';

import { apiFetch, getToken } from '@/lib/api';
import { inr } from '@/lib/format';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis, Cell } from 'recharts';
import { Target, AlertTriangle, CheckCircle2, TrendingUp, Search } from 'lucide-react';

type BudgetRow = {
  id: string;
  userId: string;
  user: { id: string; name: string | null; email: string | null };
  category: { id: string; name: string };
  limit: number;
  spent: number;
  exceeded: boolean;
  percent: number;
  yearMonth: number;
};

type ListRes = { rows: BudgetRow[]; overspending: BudgetRow[] };

export default function BudgetsPage() {
  const [data, setData] = useState<ListRes | null>(null);
  const [err, setErr] = useState('');
  const [userId, setUserId] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(() => {
    setLoading(true);
    setErr('');
    const q = userId.trim() ? `?userId=${encodeURIComponent(userId.trim())}` : '';
    apiFetch<ListRes>(`/admin/budgets${q}`, { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'))
      .finally(() => setLoading(false));
  }, [userId]);

  useEffect(() => {
    load();
  }, [load]);

  const categoryAgg = useMemo(() => {
    if (!data) return [];
    const m = new Map<string, { name: string; spent: number; limit: number }>();
    for (const r of data.rows) {
      const cur = m.get(r.category.id) ?? { name: r.category.name, spent: 0, limit: 0 };
      cur.spent += r.spent;
      cur.limit += r.limit;
      m.set(r.category.id, cur);
    }
    return [...m.values()]
      .sort((a, b) => b.spent - a.spent)
      .slice(0, 10);
  }, [data]);

  if (err) return (
    <div className="bg-error/5 border border-error/20 p-6 rounded-2xl flex items-center gap-4 text-error">
      <AlertTriangle className="h-6 w-6" />
      <p className="font-bold">{err}</p>
    </div>
  );

  return (
    <div className="space-y-8 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Budget Control</h1>
          <p className="text-mf-muted text-sm mt-1">Monitor spending thresholds across all business categories.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-mf-muted" />
            <input
              placeholder="Filter by user ID..."
              value={userId}
              onChange={(e) => setUserId(e.target.value)}
              className="pl-10 pr-4 py-2.5 rounded-xl border border-mf-border bg-white text-sm font-medium focus:border-primary focus:bg-white outline-none transition-all w-64"
            />
          </div>
          <button
            onClick={load}
            className="btn-primary h-11 px-6 shadow-sm"
          >
            Apply
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex flex-col items-center justify-center py-24 gap-4">
           <div className="h-10 w-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
           <p className="text-sm font-medium text-mf-muted tracking-wide">Syncing budget data...</p>
        </div>
      ) : (
        <>
          {/* Overspending Alert Section */}
          {data && data.overspending.length > 0 && (
            <div className="bg-orange-50 border border-orange-200 rounded-2xl p-6 shadow-sm">
              <div className="flex items-center gap-3 mb-6">
                <div className="h-10 w-10 rounded-xl bg-orange-100 flex items-center justify-center text-orange-600">
                  <AlertTriangle className="h-6 w-6" />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-orange-800">Budget Alerts</h2>
                  <p className="text-sm text-orange-600 font-medium">{data.overspending.length} categories have exceeded their limit.</p>
                </div>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="text-orange-800/60 uppercase text-[10px] font-bold tracking-widest border-b border-orange-200">
                      <th className="pb-3 px-2">Category</th>
                      <th className="pb-3 px-2">Limit</th>
                      <th className="pb-3 px-2">Spent</th>
                      <th className="pb-3 px-2">Overflow</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.overspending.map((r) => (
                      <tr key={r.id} className="border-b border-orange-100 last:border-0">
                        <td className="py-4 px-2 font-bold text-orange-900">{r.category.name}</td>
                        <td className="py-4 px-2 text-orange-700 font-medium">₹{r.limit.toLocaleString()}</td>
                        <td className="py-4 px-2 text-error font-bold">₹{r.spent.toLocaleString()}</td>
                        <td className="py-4 px-2">
                           <span className="px-2 py-1 rounded bg-error/10 text-error text-[10px] font-black uppercase">
                             +{Math.round(r.percent - 100)}%
                           </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          <div className="grid gap-8 lg:grid-cols-3">
             {/* Main Budget Table */}
             <div className="lg:col-span-2 bg-white border border-mf-border rounded-2xl shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-mf-border bg-gray-50/50">
                   <h3 className="text-sm font-bold text-mf-dark uppercase tracking-wider">All active limits</h3>
                </div>
                <div className="overflow-x-auto">
                  <table className="premium-table">
                    <thead>
                      <tr>
                        <th className="pl-6">Category</th>
                        <th>Limit</th>
                        <th>Spent</th>
                        <th className="pr-6 text-right">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data?.rows.map((r) => (
                        <tr key={r.id} className="hover:bg-gray-50/50 transition-colors">
                          <td className="pl-6 py-4">
                            <p className="text-sm font-bold text-mf-dark">{r.category.name}</p>
                            <p className="text-[10px] font-medium text-mf-muted uppercase tracking-wider mt-0.5">{r.user.name || 'Personal'}</p>
                          </td>
                          <td className="py-4 font-medium text-mf-muted">₹{r.limit.toLocaleString()}</td>
                          <td className="py-4 font-bold text-mf-dark">₹{r.spent.toLocaleString()}</td>
                          <td className="pr-6 py-4 text-right">
                            {r.exceeded ? (
                              <span className="px-2.5 py-1 rounded-lg bg-error/10 text-error text-[10px] font-black uppercase tracking-widest">Exceeded</span>
                            ) : (
                              <span className="px-2.5 py-1 rounded-lg bg-success/10 text-success text-[10px] font-black uppercase tracking-widest">Healthy</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
             </div>

             {/* Chart Sidebar */}
             <div className="bg-white border border-mf-border rounded-2xl p-6 shadow-sm">
                <div className="flex items-center gap-2 mb-8">
                  <TrendingUp className="h-5 w-5 text-primary" />
                  <h3 className="text-sm font-bold text-mf-dark uppercase tracking-wider">Spend vs Limit</h3>
                </div>
                <div className="h-[400px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={categoryAgg} layout="vertical" margin={{ left: 20 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" horizontal={false} />
                      <XAxis type="number" hide />
                      <YAxis dataKey="name" type="category" stroke="#9CA3AF" fontSize={10} axisLine={false} tickLine={false} width={80} />
                      <Tooltip
                        cursor={{fill: '#F9FAFB'}}
                        contentStyle={{ background: '#fff', border: '1px solid #E5E7EB', borderRadius: '12px' }}
                        formatter={(v: number) => `₹${v.toLocaleString()}`}
                      />
                      <Bar dataKey="spent" fill="#4F46E5" radius={[0, 4, 4, 0]} barSize={16}>
                         {categoryAgg.map((entry, index) => (
                           <Cell key={`cell-${index}`} fill={entry.spent > entry.limit ? '#F59E0B' : '#4F46E5'} />
                         ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
                <p className="text-[10px] text-mf-muted font-medium mt-6 text-center italic uppercase tracking-widest">
                  * Yellow bars indicate potential budget risks
                </p>
             </div>
          </div>
        </>
      )}
    </div>
  );
}

