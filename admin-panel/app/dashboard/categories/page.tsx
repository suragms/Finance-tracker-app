'use client';

import { apiFetch, getToken } from '@/lib/api';
import { Plus, Edit2, Trash2, Utensils, ShoppingBag, Home, Car, Shield, Activity, Film, PlusCircle, Laptop, Heart, Package, Tag } from 'lucide-react';
import { useState, useEffect } from 'react';

type Category = {
  id: string;
  name: string;
  type: string;
  icon?: string;
  color?: string;
  _count?: {
    expenses: number;
    subCategories: number;
  }
};

export default function CategoriesPage() {
  const [showAddModal, setShowAddModal] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchCats = async () => {
      try {
        const data = await apiFetch<Category[]>('/categories', { token: getToken() });
        setCategories(data);
      } catch (err) {
        console.error('Failed to fetch categories', err);
      } finally {
        setLoading(false);
      }
    };
    fetchCats();
  }, []);

  return (
    <div className="space-y-8 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Categories</h1>
          <p className="text-mf-muted text-sm mt-1">Organize your transactions with logical classifications.</p>
        </div>
        <button 
          onClick={() => setShowAddModal(true)}
          className="btn-primary h-12 px-6"
        >
          <Plus className="h-5 w-5" />
          Add Category
        </button>
      </div>

      {loading ? (
        <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="h-48 bg-gray-100 animate-pulse rounded-2xl border border-mf-border" />
          ))}
        </div>
      ) : (
        <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
          {categories.map((cat) => (
            <div key={cat.id} className="group relative bg-white border border-mf-border rounded-2xl p-6 shadow-sm hover:shadow-md transition-all cursor-pointer overflow-hidden">
              <div className="flex flex-col items-center text-center">
                <div 
                  className="h-14 w-14 rounded-xl flex items-center justify-center mb-4 transition-transform group-hover:scale-110"
                  style={{ 
                    backgroundColor: `${cat.color || '#4F46E5'}15`, 
                    color: cat.color || '#4F46E5' 
                  }}
                >
                  <Tag className="h-7 w-7" />
                </div>
                <h4 className="text-sm font-bold text-mf-dark uppercase tracking-tight">{cat.name}</h4>
                <div className="mt-2 flex items-center gap-2">
                   <span className="text-[10px] font-bold text-mf-muted uppercase tracking-widest bg-gray-50 px-2 py-0.5 rounded border border-mf-border">
                     {cat.type}
                   </span>
                </div>
                <p className="text-[11px] font-medium text-mf-muted mt-3">
                  {cat._count?.expenses || 0} Transactions
                </p>
              </div>

              {/* Actions on Hover */}
              <div className="absolute inset-x-0 bottom-0 p-4 bg-white/95 backdrop-blur-sm border-t border-mf-border flex items-center justify-center gap-3 opacity-0 group-hover:opacity-100 transition-all translate-y-4 group-hover:translate-y-0">
                 <button className="p-2 rounded-lg hover:bg-gray-100 text-mf-dark transition-colors">
                    <Edit2 className="h-4 w-4" />
                 </button>
                 <button className="p-2 rounded-lg hover:bg-error/5 text-error transition-colors">
                    <Trash2 className="h-4 w-4" />
                 </button>
              </div>
            </div>
          ))}
          
          <button 
            onClick={() => setShowAddModal(true)}
            className="rounded-2xl border-2 border-dashed border-mf-border flex flex-col items-center justify-center gap-3 p-6 text-mf-muted hover:border-primary hover:text-primary hover:bg-primary/5 transition-all group"
          >
            <div className="h-12 w-12 rounded-full bg-gray-50 flex items-center justify-center group-hover:bg-primary/10 transition-all">
              <PlusCircle className="h-6 w-6 text-mf-muted group-hover:text-primary" />
            </div>
            <span className="font-bold text-xs uppercase tracking-wider">New Category</span>
          </button>
        </div>
      )}

      {/* Basic Modal Placeholder */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-mf-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-md rounded-2xl p-8 shadow-xl animate-in zoom-in-95 duration-200 border border-mf-border">
            <h3 className="text-xl font-bold text-mf-dark tracking-tight mb-6">Add New Category</h3>
            
            <div className="space-y-6">
              <div className="space-y-2">
                <label className="text-xs font-bold uppercase tracking-wider text-mf-muted">Category Name</label>
                <input 
                  type="text" 
                  placeholder="e.g. Subscriptions" 
                  className="w-full rounded-xl bg-gray-50 border border-mf-border px-4 py-3 text-sm font-medium text-mf-dark outline-none focus:border-primary focus:bg-white transition-all"
                />
              </div>

              <div className="flex gap-3">
                <button 
                  onClick={() => setShowAddModal(false)}
                  className="flex-1 btn-secondary h-11"
                >
                  Cancel
                </button>
                <button 
                  className="flex-1 btn-primary h-11"
                >
                  Create
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

