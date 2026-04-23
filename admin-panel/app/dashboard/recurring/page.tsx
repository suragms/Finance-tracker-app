'use client';

import { apiFetch, getToken } from '@/lib/api';
import { 
  Plus, 
  Calendar, 
  Clock, 
  ArrowRight, 
  MoreHorizontal, 
  RefreshCw, 
  Zap, 
  Bell, 
  AlertTriangle,
  X,
  Tag,
  Wallet,
  Check,
  CheckCircle2
} from 'lucide-react';
import { useState, useEffect } from 'react';

type RecurringTransaction = {
  id: string;
  title: string;
  amount: number;
  frequency: string;
  nextDate: string;
  category: { id: string; name: string };
  active: boolean;
};

export default function RecurringPage() {
  const [data, setData] = useState<RecurringTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    title: '',
    amount: '',
    frequency: 'MONTHLY',
    categoryId: '',
    nextDate: new Date().toISOString().split('T')[0],
  });

  const [categories, setCategories] = useState<{id: string, name: string}[]>([]);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [res, cats] = await Promise.all([
        apiFetch<RecurringTransaction[]>('/recurring', { token: getToken() }),
        apiFetch<{id: string, name: string}[]>('/categories', { token: getToken() })
      ]);
      setData(res);
      setCategories(cats);
      if (cats.length > 0) setFormData(p => ({ ...p, categoryId: cats[0].id }));
    } catch (err) {
      setErr('Failed to load recurring data');
    } finally {
      setLoading(false);
    }
  };

  const toggleActive = async (id: string, current: boolean) => {
    try {
      await apiFetch(`/recurring/${id}/active`, {
        method: 'PATCH',
        token: getToken(),
        body: { active: !current }
      });
      setData(prev => prev.map(item => item.id === id ? { ...item, active: !current } : item));
    } catch (err) {
      setErr('Failed to update status');
    }
  };

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (submitting) return;

    setSubmitting(true);
    try {
      const newItem = await apiFetch<RecurringTransaction>('/recurring', {
        method: 'POST',
        token: getToken(),
        body: {
          ...formData,
          amount: parseFloat(formData.amount),
          nextDate: new Date(formData.nextDate).toISOString()
        }
      });
      setData(prev => [newItem, ...prev]);
      setIsModalOpen(false);
      setFormData({
        title: '',
        amount: '',
        frequency: 'MONTHLY',
        categoryId: categories[0]?.id || '',
        nextDate: new Date().toISOString().split('T')[0],
      });
    } catch (err) {
      setErr('Failed to create obligation');
    } finally {
      setSubmitting(false);
    }
  };

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 0,
    }).format(val);
  };

  if (loading) return (
    <div className="py-20 flex flex-col items-center justify-center gap-4">
       <div className="h-10 w-10 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin" />
       <p className="text-sm font-medium text-gray-400">Syncing obligations...</p>
    </div>
  );

  return (
    <div className="space-y-8 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Recurring Obligations</h1>
          <p className="text-sm text-gray-400 mt-1">Manage Automated bills, subscriptions, and transfers.</p>
        </div>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="btn-primary h-12 shadow-indigo-100"
        >
          <Plus className="h-5 w-5" />
          Add Obligation
        </button>
      </div>

      {err && (
        <div className="bg-amber-50 border border-amber-100 p-4 rounded-2xl flex items-center gap-3 text-amber-600 text-sm font-bold animate-in fade-in">
           <AlertTriangle className="h-5 w-5" />
           {err}
           <button onClick={() => setErr('')} className="ml-auto text-amber-400 hover:text-amber-600">
             <X className="h-4 w-4" />
           </button>
        </div>
      )}

      {/* QUICK SUMMARY CARDS */}
      <div className="grid gap-6 grid-cols-1 md:grid-cols-3">
         <SummaryTile label="Fixed Monthly Cost" value={formatCurrency(data.reduce((acc, curr) => acc + (curr.active ? curr.amount : 0), 0))} icon={RefreshCw} trend="Calculated" color="indigo" />
         <SummaryTile label="Active Obligations" value={data.filter(d => d.active).length.toString()} icon={Zap} trend="Live Cycles" color="green" />
         <SummaryTile label="Total Items" value={data.length.toString()} icon={Bell} trend="Tracked" color="amber" />
      </div>

      {/* LIST: Recurring Items */}
      <div className="space-y-4">
        {data.length === 0 ? (
           <div className="flex flex-col items-center justify-center py-24 bg-white border border-gray-100 rounded-3xl group">
              <div className="h-20 w-20 rounded-full bg-gray-50 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <RefreshCw className="h-10 w-10 text-gray-200" />
              </div>
              <h3 className="text-lg font-bold text-gray-900">Zero Obligations</h3>
              <p className="text-sm text-gray-400 mt-1 text-center max-w-xs">Your financial automation is waiting for your first subscription or bill.</p>
           </div>
        ) : (
          data.map((item) => (
            <div key={item.id} className="group bg-white border border-gray-100 rounded-3xl p-6 hover:shadow-lg hover:shadow-indigo-100/10 transition-all cursor-pointer">
              <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
                 {/* NAME & IDENTITY */}
                 <div className="flex items-center gap-4 lg:w-1/3">
                    <button 
                      onClick={(e) => { e.stopPropagation(); toggleActive(item.id, item.active); }}
                      className={`h-12 w-12 rounded-2xl border transition-all flex items-center justify-center ${item.active ? 'bg-indigo-600 border-indigo-600 text-white' : 'bg-gray-50 border-gray-100 text-gray-300'}`}
                    >
                       <Check className="h-6 w-6" />
                    </button>
                    <div>
                      <h4 className="text-base font-bold text-gray-900 leading-tight">{item.title}</h4>
                      <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-1">{item.category?.name || 'Uncategorized'}</p>
                    </div>
                 </div>

                 {/* FREQUENCY & DATA */}
                 <div className="grid grid-cols-2 lg:flex lg:items-center gap-8 lg:w-1/3">
                    <div className="space-y-1">
                      <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Interval</p>
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-gray-50 border border-gray-100 text-[10px] font-black text-indigo-600 uppercase tracking-widest">
                         <Clock className="h-3 w-3" />
                         {item.frequency}
                      </span>
                    </div>

                    <div className="space-y-1">
                      <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Next Date</p>
                      <p className="text-sm font-bold text-gray-900">{new Date(item.nextDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}</p>
                    </div>
                 </div>

                 {/* AMOUNT & ACTIONS */}
                 <div className="flex items-center justify-between lg:justify-end gap-10 lg:w-1/3 border-t lg:border-t-0 border-gray-50 pt-4 lg:pt-0">
                    <div className="text-left lg:text-right">
                      <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Maturity Amount</p>
                      <p className="text-xl font-black text-gray-900">{formatCurrency(item.amount)}</p>
                    </div>
                    <div className="flex items-center gap-2">
                       <button className="h-10 w-10 rounded-xl bg-gray-50 flex items-center justify-center text-gray-400 hover:text-gray-900 hover:bg-gray-100 transition-all">
                          <MoreHorizontal className="h-5 w-5" />
                       </button>
                    </div>
                 </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* ADD MODAL */}
      {isModalOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-in fade-in duration-200">
           <div className="bg-white w-full max-w-md rounded-[32px] p-8 shadow-2xl animate-in zoom-in-95 duration-200">
              <div className="flex justify-between items-center mb-8">
                 <h2 className="text-xl font-bold text-gray-900 tracking-tight">Add Obligation</h2>
                 <button onClick={() => setIsModalOpen(false)} className="p-2 rounded-full hover:bg-gray-100 text-gray-400 transition-colors">
                    <X className="h-5 w-5" />
                 </button>
              </div>

              <form onSubmit={handleAdd} className="space-y-5">
                 <div className="space-y-1">
                    <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Title</label>
                    <input 
                      required
                      placeholder="e.g. Netflix, Rent"
                      value={formData.title}
                      onChange={e => setFormData(p => ({ ...p, title: e.target.value }))}
                      className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none"
                    />
                 </div>

                 <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1">
                       <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Amount</label>
                       <input 
                         required
                         type="number"
                         placeholder="0.00"
                         value={formData.amount}
                         onChange={e => setFormData(p => ({ ...p, amount: e.target.value }))}
                         className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-sm font-bold focus:border-indigo-600 outline-none"
                       />
                    </div>
                    <div className="space-y-1">
                       <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Frequency</label>
                       <select 
                         value={formData.frequency}
                         onChange={e => setFormData(p => ({ ...p, frequency: e.target.value }))}
                         className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none appearance-none"
                       >
                          <option value="DAILY">Daily</option>
                          <option value="WEEKLY">Weekly</option>
                          <option value="MONTHLY">Monthly</option>
                          <option value="YEARLY">Yearly</option>
                       </select>
                    </div>
                 </div>

                 <div className="space-y-1">
                    <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Category</label>
                    <select 
                      required
                      value={formData.categoryId}
                      onChange={e => setFormData(p => ({ ...p, categoryId: e.target.value }))}
                      className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none appearance-none"
                    >
                       {categories.map(cat => <option key={cat.id} value={cat.id}>{cat.name}</option>)}
                    </select>
                 </div>

                 <div className="space-y-1">
                    <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Starting Date</label>
                    <input 
                      type="date"
                      required
                      value={formData.nextDate}
                      onChange={e => setFormData(p => ({ ...p, nextDate: e.target.value }))}
                      className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none"
                    />
                 </div>

                 <button 
                    disabled={submitting}
                    className="w-full h-14 bg-indigo-600 text-white rounded-2xl font-bold hover:bg-indigo-700 active:scale-95 transition-all shadow-lg shadow-indigo-100 disabled:opacity-50"
                 >
                    {submitting ? 'Creating...' : 'Create Obligation'}
                 </button>
              </form>
           </div>
        </div>
      )}
    </div>
  );
}

function SummaryTile({ label, value, icon: Icon, trend, color }: { label: string, value: string, icon: any, trend: string, color: 'indigo' | 'green' | 'amber' }) {
  const colorClasses = {
    indigo: 'text-indigo-600 bg-indigo-50 border-indigo-100',
    green: 'text-green-600 bg-green-50 border-green-100',
    amber: 'text-amber-600 bg-amber-50 border-amber-100',
  };

  return (
    <div className="bg-white border border-gray-100 rounded-3xl p-6 group transition-all hover:shadow-md">
      <div className="flex items-center justify-between mb-6">
         <div className={`p-3 rounded-xl border ${colorClasses[color]}`}>
            <Icon className="h-5 w-5" />
         </div>
         <span className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">{trend}</span>
      </div>
      <p className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-1">{label}</p>
      <h4 className="text-2xl font-black text-gray-900 tracking-tight">{value}</h4>
    </div>
  );
}


