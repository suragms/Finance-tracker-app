'use client';

import { apiFetch, getToken } from '@/lib/api';
import { X, Plus, Minus, Calendar, Tag, Wallet, FileText, Check, AlertCircle } from 'lucide-react';
import { useState, useEffect } from 'react';

type Props = {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

type Category = { id: string; name: string };
type Account = { id: string; name: string; balance: number };

export default function AddTransactionModal({ isOpen, onClose, onSuccess }: Props) {
  const [type, setType] = useState<'expense' | 'income'>('expense');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showCustomCategory, setShowCustomCategory] = useState(false);
  const [customCategory, setCustomCategory] = useState('');
  
  const [categories, setCategories] = useState<Category[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);

  const [formData, setFormData] = useState({
    amount: '',
    categoryId: '',
    accountId: '',
    date: new Date().toISOString().split('T')[0],
    note: '',
  });

  useEffect(() => {
    if (isOpen) {
      const fetchData = async () => {
        try {
          const [cats, accs] = await Promise.all([
            apiFetch<Category[]>('/categories', { token: getToken() }),
            apiFetch<Account[]>('/accounts', { token: getToken() }),
          ]);
          setCategories(cats);
          setAccounts(accs);
          if (accs.length > 0) setFormData(prev => ({ ...prev, accountId: accs[0].id }));
          if (cats.length > 0) setFormData(prev => ({ ...prev, categoryId: prev.categoryId || cats[0].id }));
        } catch (err) {
          console.error('Failed to fetch modal data', err);
        }
      };
      fetchData();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const amountNum = parseFloat(formData.amount);
    
    if (isNaN(amountNum) || amountNum <= 0) {
      setError('Please enter a valid amount greater than 0');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const endpoint = type === 'expense' ? '/expenses' : '/incomes';
      
      let finalCategoryId = formData.categoryId;
      
      // Handle custom category if needed
      if (type === 'expense' && showCustomCategory && customCategory.trim()) {
         const newCat = await apiFetch<Category>('/categories', {
           method: 'POST',
           body: { name: customCategory.trim(), type: 'EXPENSE' },
           token: getToken()
         });
         finalCategoryId = newCat.id;
      }

      const body = {
        amount: amountNum,
        date: new Date(formData.date).toISOString(),
        accountId: formData.accountId,
        note: formData.note,
        ...(type === 'expense' ? { categoryId: finalCategoryId } : { source: 'BUSINESS' })
      };

      await apiFetch(endpoint, {
        method: 'POST',
        body,
        token: getToken(),
      });

      // SUCCESS
      setFormData({
        amount: '',
        categoryId: '',
        accountId: '',
        date: new Date().toISOString().split('T')[0],
        note: '',
      });
      setShowCustomCategory(false);
      setCustomCategory('');
      
      onSuccess?.();
      onClose();
    } catch (err: any) {
      setError(err.message || 'Operation failed. Please check inputs.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm transition-all duration-300">
      <div className="bg-white w-full max-w-md rounded-3xl p-6 shadow-2xl border border-gray-100 flex flex-col gap-4 animate-in zoom-in-95 duration-200">
        <div className="flex justify-between items-center">
          <h2 className="text-xl font-bold text-gray-900 tracking-tight">New Transaction</h2>
          <button 
            onClick={onClose}
            className="p-2 rounded-full hover:bg-gray-100 text-gray-400 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Type Toggle */}
        <div className="flex bg-gray-50 p-1 rounded-2xl">
           <button 
             onClick={() => setType('expense')}
             className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-bold transition-all ${type === 'expense' ? 'bg-white text-amber-500 shadow-sm' : 'text-gray-400 hover:text-gray-600'}`}
           >
             <Minus className="h-4 w-4" /> Expense
           </button>
           <button 
             onClick={() => setType('income')}
             className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-bold transition-all ${type === 'income' ? 'bg-white text-green-500 shadow-sm' : 'text-gray-400 hover:text-gray-600'}`}
           >
             <Plus className="h-4 w-4" /> Income
           </button>
        </div>

        {error && (
          <div className="bg-amber-50 border border-amber-100 p-3 rounded-xl flex items-center gap-2 text-amber-600 text-xs font-bold animate-in fade-in duration-200">
            <AlertCircle className="h-4 w-4" />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1">
            <label className="text-[10px] font-bold uppercase tracking-wider text-gray-400 ml-1">Amount (₹)</label>
            <input 
              type="number" 
              required
              step="any"
              placeholder="0.00"
              autoFocus
              value={formData.amount}
              onChange={e => setFormData(p => ({ ...p, amount: e.target.value }))}
              className={`w-full text-4xl font-black bg-transparent border-none outline-none placeholder:text-gray-200 focus:ring-0 ${type === 'expense' ? 'text-amber-500' : 'text-green-500'}`}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
             <div className="space-y-1">
                <label className="text-[10px] font-bold uppercase tracking-wider text-gray-400 ml-1">Date</label>
                <div className="relative">
                  <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-300" />
                  <input 
                    type="date"
                    required
                    value={formData.date}
                    onChange={e => setFormData(p => ({ ...p, date: e.target.value }))}
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl pl-10 pr-4 py-3 text-sm font-medium focus:border-indigo-600 transition-all outline-none"
                  />
                </div>
             </div>
             <div className="space-y-1">
                <label className="text-[10px] font-bold uppercase tracking-wider text-gray-400 ml-1">Account</label>
                <div className="relative">
                  <Wallet className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-300" />
                  <select
                    required
                    value={formData.accountId}
                    onChange={e => setFormData(p => ({ ...p, accountId: e.target.value }))}
                    className="w-full bg-gray-50 border border-gray-100 rounded-xl pl-10 pr-4 py-3 text-sm font-medium focus:border-indigo-600 appearance-none outline-none transition-all"
                  >
                    {accounts.map(acc => (
                      <option key={acc.id} value={acc.id}>{acc.name}</option>
                    ))}
                  </select>
                </div>
             </div>
          </div>

          {type === 'expense' && (
            <div className="space-y-1">
               <div className="flex justify-between items-center px-1">
                  <label className="text-[10px] font-bold uppercase tracking-wider text-gray-400">Category</label>
                  <button 
                    type="button"
                    onClick={() => setShowCustomCategory(!showCustomCategory)}
                    className="text-[10px] font-bold text-indigo-600 uppercase hover:underline"
                  >
                    {showCustomCategory ? 'Use Existing' : 'Add New'}
                  </button>
               </div>
               
               {showCustomCategory ? (
                 <input 
                   placeholder="New Category Name..."
                   value={customCategory}
                   onChange={e => setCustomCategory(e.target.value)}
                   className="w-full bg-gray-50 border border-gray-100 rounded-xl px-4 py-3 text-sm font-medium focus:border-indigo-600 outline-none transition-all"
                 />
               ) : (
                 <div className="relative">
                   <Tag className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-300" />
                   <select
                     required={type === 'expense' && !showCustomCategory}
                     value={formData.categoryId}
                     onChange={e => setFormData(p => ({ ...p, categoryId: e.target.value }))}
                     className="w-full bg-gray-50 border border-gray-100 rounded-xl pl-10 pr-4 py-3 text-sm font-medium focus:border-indigo-600 appearance-none outline-none transition-all"
                   >
                     {categories.map(cat => (
                       <option key={cat.id} value={cat.id}>{cat.name}</option>
                     ))}
                   </select>
                 </div>
               )}
            </div>
          )}

          <div className="space-y-1">
            <label className="text-[10px] font-bold uppercase tracking-wider text-gray-400 ml-1">Note (Optional)</label>
            <div className="relative">
              <FileText className="absolute left-3 top-3.5 h-4 w-4 text-gray-300" />
              <textarea 
                placeholder="Brief description..."
                rows={2}
                value={formData.note}
                onChange={e => setFormData(p => ({ ...p, note: e.target.value }))}
                className="w-full bg-gray-50 border border-gray-100 rounded-xl pl-10 pr-4 py-3 text-sm font-medium focus:border-indigo-600 transition-all resize-none outline-none"
              />
            </div>
          </div>

          <button 
            type="submit"
            disabled={loading || !formData.amount}
            className={`w-full h-14 rounded-2xl text-base font-bold shadow-lg transition-all flex items-center justify-center gap-2 active:scale-95 ${loading ? 'opacity-50' : type === 'expense' ? 'bg-amber-500 hover:bg-amber-600 text-white shadow-amber-100' : 'bg-green-500 hover:bg-green-600 text-white shadow-green-100'}`}
          >
            {loading ? (
              <div className="h-5 w-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <>Save Transaction <Check className="h-5 w-5" /></>
            )}
          </button>
        </form>
      </div>
    </div>
  );
}

