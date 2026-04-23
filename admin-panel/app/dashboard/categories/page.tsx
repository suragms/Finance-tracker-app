'use client';

import { Plus, Edit2, Trash2, Utensils, ShoppingBag, Home, Car, Shield, Activity, Film, PlusCircle, Laptop, Heart } from 'lucide-react';
import { useState } from 'react';

const mockCategories = [
  { id: '1', name: 'Food & Dining', icon: Utensils, color: '#22C697' },
  { id: '2', name: 'Shopping', icon: ShoppingBag, color: '#8B7DFF' },
  { id: '3', name: 'Household', icon: Home, color: '#FFD166' },
  { id: '4', name: 'Transport', icon: Car, color: '#667EEA' },
  { id: '5', name: 'Health', icon: Activity, color: '#F07070' },
  { id: '6', name: 'Entertainment', icon: Film, color: '#8B7DFF' },
  { id: '7', name: 'Software', icon: Laptop, color: '#4FC3F7' },
  { id: '8', name: 'Personal Care', icon: Heart, color: '#F48FB1' },
];

export default function CategoriesPage() {
  const [showAddModal, setShowAddModal] = useState(false);

  return (
    <div className="space-y-12 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h3 className="text-3xl font-black text-white tracking-widest uppercase mb-1">Taxonomy</h3>
          <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.3em]">Spending Classification Protocol</p>
        </div>
        <button 
          onClick={() => setShowAddModal(true)}
          className="flex items-center gap-3 px-8 py-4 rounded-2xl bg-mf-accent text-white hover:scale-[1.02] shadow-neon-purple shadow-mf-accent/30 transition-all text-[10px] font-black uppercase tracking-[0.2em]"
        >
          <Plus className="h-4 w-4" />
          Assign New
        </button>
      </div>

      {/* GRID: High-Density Category Shell */}
      <div className="grid gap-8 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {mockCategories.map((cat) => (
          <div key={cat.id} className="relative group overflow-hidden glass-card rounded-[32px] p-8 transition-all duration-500 hover:bg-white/[0.06] hover:scale-[1.02] cursor-pointer">
            {/* AMBIENT GLOW */}
            <div 
              className="absolute -right-8 -top-8 h-24 w-24 rounded-full blur-[40px] opacity-20 transition-all group-hover:scale-150 duration-700" 
              style={{ backgroundColor: cat.color }}
            />

            <div className="relative z-10 flex flex-col items-center text-center">
              <div 
                className="h-20 w-20 rounded-[24px] flex items-center justify-center border transition-all duration-500 group-hover:shadow-[0_0_30px_rgba(255,255,255,0.05)] mb-6 shadow-xl"
                style={{ 
                  backgroundColor: `${cat.color}11`, 
                  borderColor: `${cat.color}33`,
                  color: cat.color 
                }}
              >
                <cat.icon className="h-10 w-10" />
              </div>
              <h4 className="text-sm font-black text-white uppercase tracking-[0.15em]">{cat.name}</h4>
              <p className="text-[9px] font-black text-mf-muted uppercase tracking-widest mt-2 opacity-50">Active Classification</p>
            </div>

            {/* FEATURE: Edit on Hover Overlay */}
            <div className="absolute inset-0 bg-mf-bg/80 backdrop-blur-md flex items-center justify-center gap-4 opacity-0 group-hover:opacity-100 transition-all duration-300 translate-y-full group-hover:translate-y-0">
               <button className="h-12 w-12 rounded-2xl bg-mf-accent text-white flex items-center justify-center hover:scale-110 shadow-neon-purple transition-all">
                  <Edit2 className="h-5 w-5" />
               </button>
               <button className="h-12 w-12 rounded-2xl bg-mf-error/20 border border-mf-error/30 text-mf-error flex items-center justify-center hover:scale-110 transition-all">
                  <Trash2 className="h-5 w-5" />
               </button>
            </div>
          </div>
        ))}
        
        {/* NEW CATEGORY TRIGGER */}
        <div 
          onClick={() => setShowAddModal(true)}
          className="rounded-[32px] border-2 border-dashed border-white/10 flex flex-col items-center justify-center gap-4 p-8 text-mf-muted hover:border-mf-accent/50 hover:text-white hover:bg-white/[0.02] transition-all duration-500 cursor-pointer group"
        >
          <div className="h-16 w-16 rounded-full border-2 border-dashed border-white/20 flex items-center justify-center group-hover:border-mf-accent group-hover:bg-mf-accent/10 transition-all duration-500 rotate-0 group-hover:rotate-90">
            <PlusCircle className="h-8 w-8" />
          </div>
          <span className="font-black text-[10px] uppercase tracking-[0.3em]">Append Vector</span>
        </div>
      </div>

      {/* MODAL: Creation Shell */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-mf-bg/90 backdrop-blur-xl animate-in fade-in duration-500">
          <div className="glass-card w-full max-w-lg rounded-[40px] p-10 shadow-2xl animate-in scale-in-90 duration-500 border border-white/5">
            <h3 className="text-3xl font-black text-white tracking-widest uppercase mb-10 text-center">New Taxonomy</h3>
            
            <div className="space-y-8">
              <div className="space-y-3">
                <label className="text-[10px] font-black uppercase tracking-[0.3em] text-mf-muted ml-2">Category Identity</label>
                <input 
                  type="text" 
                  autoFocus
                  placeholder="e.g. SUBSCRIPTIONS" 
                  className="w-full rounded-[24px] bg-white/[0.03] border border-white/10 px-8 py-5 text-sm font-black text-white placeholder:text-white/10 outline-none focus:border-mf-accent/50 focus:bg-white/[0.08] transition-all uppercase tracking-widest"
                />
              </div>

              <div className="space-y-3">
                <label className="text-[10px] font-black uppercase tracking-[0.3em] text-mf-muted ml-2">Visual Mapping</label>
                <div className="grid grid-cols-5 gap-4">
                   {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(i => (
                     <div key={i} className={`h-12 w-12 rounded-[18px] border-[1.5px] flex items-center justify-center cursor-pointer transition-all duration-300 ${i === 1 ? 'bg-mf-accent text-white border-mf-accent shadow-neon-purple shadow-mf-accent/30' : 'bg-white/5 border-white/10 text-mf-muted hover:bg-white/10 hover:text-white'}`}>
                       <Plus className="h-5 w-5" />
                     </div>
                   ))}
                </div>
              </div>

              <div className="flex gap-4 pt-6">
                <button 
                  onClick={() => setShowAddModal(false)}
                  className="flex-1 py-5 rounded-[24px] border border-white/10 text-[10px] font-black text-mf-muted hover:bg-white/5 transition-all uppercase tracking-[0.3em]"
                >
                  Terminate
                </button>
                <button 
                  className="flex-1 py-5 rounded-[24px] bg-mf-accent text-white font-black text-[10px] uppercase tracking-[0.3em] shadow-neon-purple shadow-mf-accent/40 hover:scale-[1.02] active:scale-[0.98] transition-all"
                >
                  Initialize
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
