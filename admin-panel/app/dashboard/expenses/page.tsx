'use client';

import { apiFetch, getToken } from '@/lib/api';
import { useState, useEffect, useMemo } from 'react';
import { 
  Plus, 
  Search, 
  Filter, 
  Download, 
  Trash2, 
  AlertCircle, 
  ArrowDownRight, 
  Calendar, 
  Tag, 
  Wallet,
  CheckCircle2,
  Loader2
} from 'lucide-react';

type Expense = {
  id: string;
  amount: number;
  date: string;
  note?: string;
  category: { id: string; name: string };
  account: { id: string; name: string };
};

type Category = { id: string; name: string };
type Account = { id: string; name: string };

export default function ExpensePage() {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Form State
  const [formData, setFormData] = useState({
    amount: '',
    categoryId: '',
    accountId: '',
    date: new Date().toISOString().split('T')[0],
    note: ''
  });

  // Filter State
  const [search, setSearch] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [expRes, catRes, accRes] = await Promise.all([
          apiFetch<Expense[]>('/expenses', { token: getToken() }),
          apiFetch<Category[]>('/categories', { token: getToken() }),
          apiFetch<Account[]>('/accounts', { token: getToken() }),
        ]);
        setExpenses(expRes);
        setCategories(catRes);
        setAccounts(accRes);
        
        if (catRes.length > 0) setFormData(p => ({ ...p, categoryId: catRes[0].id }));
        if (accRes.length > 0) setFormData(p => ({ ...p, accountId: accRes[0].id }));
      } catch (err) {
        console.error('Failed to fetch expense data', err);
        setError('Could not load data. Please refresh.');
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const totalExpense = useMemo(() => 
    expenses.reduce((sum, e) => sum + Number(e.amount), 0)
  , [expenses]);

  const filteredExpenses = useMemo(() => {
    return expenses.filter(e => 
      e.category.name.toLowerCase().includes(search.toLowerCase()) ||
      (e.note || '').toLowerCase().includes(search.toLowerCase()) ||
      e.account.name.toLowerCase().includes(search.toLowerCase())
    );
  }, [expenses, search]);

  const handleAddExpense = async (e: React.FormEvent) => {
    e.preventDefault();
    const amt = parseFloat(formData.amount);
    
    if (isNaN(amt) || amt <= 0) {
      setError('Amount must be greater than 0');
      return;
    }

    setSubmitting(true);
    setError('');
    setSuccess('');

    try {
      const newExpense = await apiFetch<Expense>('/expenses', {
        method: 'POST',
        token: getToken(),
        body: {
          amount: amt,
          categoryId: formData.categoryId,
          accountId: formData.accountId,
          date: new Date(formData.date).toISOString(),
          note: formData.note
        }
      });

      // Add to list and sort
      setExpenses(prev => [newExpense, ...prev].sort((a, b) => 
        new Date(b.date).getTime() - new Date(a.date).getTime()
      ));

      // Reset Form
      setFormData({
        amount: '',
        categoryId: categories[0]?.id || '',
        accountId: accounts[0]?.id || '',
        date: new Date().toISOString().split('T')[0],
        note: ''
      });
      
      setSuccess('Expense added successfully!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to save expense');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return (
    <div className="flex flex-col items-center justify-center py-20 gap-4">
      <Loader2 className="h-8 w-8 text-indigo-600 animate-spin" />
      <p className="text-sm font-bold text-gray-400 uppercase tracking-widest">Loading Expenses...</p>
    </div>
  );

  return (
    <div className="space-y-8 pb-12 max-w-5xl mx-auto px-4">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Expense Management</h1>
          <p className="text-sm text-gray-400 mt-1">Track and control your business spending.</p>
        </div>
        <div className="bg-indigo-50 border border-indigo-100 rounded-2xl px-6 py-3">
          <p className="text-[10px] font-bold text-indigo-600 uppercase tracking-widest mb-1">Total Period Spend</p>
          <h2 className="text-2xl font-black text-indigo-700">₹{totalExpense.toLocaleString('en-IN')}</h2>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Column: Form */}
        <div className="lg:col-span-1">
          <div className="bg-white border border-gray-100 rounded-3xl p-6 shadow-sm sticky top-8">
            <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
              <Plus className="h-5 w-5 text-indigo-600" />
              Quick Add
            </h3>

            {error && (
              <div className="mb-6 bg-amber-50 border border-amber-100 p-3 rounded-xl flex items-center gap-2 text-amber-600 text-xs font-bold animate-in fade-in">
                <AlertCircle className="h-4 w-4 shrink-0" />
                {error}
              </div>
            )}

            {success && (
              <div className="mb-6 bg-green-50 border border-green-100 p-3 rounded-xl flex items-center gap-2 text-green-600 text-xs font-bold animate-in fade-in">
                <CheckCircle2 className="h-4 w-4 shrink-0" />
                {success}
              </div>
            )}

            <form onSubmit={handleAddExpense} className="space-y-4">
              <div className="space-y-1">
                <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Amount (₹)</label>
                <input 
                  type="number"
                  required
                  placeholder="0.00"
                  value={formData.amount}
                  onChange={e => setFormData(p => ({ ...p, amount: e.target.value }))}
                  className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-lg font-bold focus:ring-2 focus:ring-indigo-100 focus:border-indigo-600 outline-none transition-all placeholder:text-gray-200"
                />
              </div>

              <div className="space-y-1">
                <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Category</label>
                <div className="relative">
                  <Tag className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-300" />
                  <select 
                    required
                    value={formData.categoryId}
                    onChange={e => setFormData(p => ({ ...p, categoryId: e.target.value }))}
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl pl-10 pr-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none appearance-none cursor-pointer"
                  >
                    {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </div>
              </div>

              <div className="space-y-1">
                <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Account</label>
                <div className="relative">
                  <Wallet className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-300" />
                  <select 
                    required
                    value={formData.accountId}
                    onChange={e => setFormData(p => ({ ...p, accountId: e.target.value }))}
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl pl-10 pr-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none appearance-none cursor-pointer"
                  >
                    {accounts.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
                  </select>
                </div>
              </div>

              <div className="space-y-1">
                <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Date</label>
                <div className="relative">
                  <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-300" />
                  <input 
                    type="date"
                    required
                    value={formData.date}
                    onChange={e => setFormData(p => ({ ...p, date: e.target.value }))}
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl pl-10 pr-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none"
                  />
                </div>
              </div>

              <div className="space-y-1">
                <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Note (Optional)</label>
                <textarea 
                  placeholder="e.g. Server hosting"
                  rows={2}
                  value={formData.note}
                  onChange={e => setFormData(p => ({ ...p, note: e.target.value }))}
                  className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-sm font-semibold focus:border-indigo-600 outline-none transition-all resize-none"
                />
              </div>

              <button 
                type="submit"
                disabled={submitting}
                className="w-full h-12 bg-indigo-600 text-white rounded-xl font-bold hover:bg-indigo-700 active:scale-95 transition-all shadow-lg shadow-indigo-100 disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {submitting ? <Loader2 className="h-5 w-5 animate-spin" /> : 'Save Expense'}
              </button>
            </form>
          </div>
        </div>

        {/* Right Column: List */}
        <div className="lg:col-span-2 space-y-6">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input 
              type="text"
              placeholder="Search by category, account or note..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full bg-white border border-gray-100 rounded-2xl pl-12 pr-4 py-3.5 text-sm outline-none focus:border-indigo-600 shadow-sm transition-all"
            />
          </div>

          <div className="space-y-3">
            {filteredExpenses.length === 0 ? (
              <div className="bg-white border border-dashed border-gray-200 rounded-3xl py-20 flex flex-col items-center justify-center">
                <div className="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center mb-4">
                  <ArrowDownRight className="h-8 w-8 text-gray-200" />
                </div>
                <p className="text-sm font-bold text-gray-400 uppercase tracking-widest">No matching expenses</p>
              </div>
            ) : (
              filteredExpenses.map((expense) => (
                <div key={expense.id} className="group bg-white border border-gray-100 rounded-2xl p-5 hover:shadow-md hover:border-indigo-100 transition-all flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="h-11 w-11 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
                      <ArrowDownRight className="h-5 w-5" />
                    </div>
                    <div>
                      <h4 className="text-sm font-bold text-gray-900 leading-tight">{expense.note || expense.category.name}</h4>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">{new Date(expense.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}</span>
                        <span className="h-1 w-1 rounded-full bg-gray-200" />
                        <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-wider">{expense.account.name}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-black text-gray-900">₹{Number(expense.amount).toLocaleString('en-IN')}</p>
                    <p className="text-[9px] font-bold text-amber-500 uppercase tracking-widest mt-0.5">{expense.category.name}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
