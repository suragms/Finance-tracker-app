'use client';

import { 
  PieChart as PieChartIcon, 
  TrendingUp, 
  TrendingDown, 
  Calendar,
  ArrowRight,
  BarChart as BarChartIcon,
  ChevronDown
} from 'lucide-react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  Pie,
  PieChart,
  Cell,
  Legend
} from 'recharts';
import { useState } from 'react';

const categoryData = [
  { name: 'Household', value: 45000, color: '#8B7DFF' },
  { name: 'Food', value: 12000, color: '#22C697' },
  { name: 'Transport', value: 8000, color: '#FFD166' },
  { name: 'Shopping', value: 15000, color: '#F07070' },
  { name: 'Others', value: 5000, color: '#667EEA' },
];

const monthlyData = [
  { month: 'Jan', income: 85000, expense: 62000 },
  { month: 'Feb', income: 72000, expense: 58000 },
  { month: 'Mar', income: 90000, expense: 45000 },
  { month: 'Apr', income: 110000, expense: 70000 },
];

export default function ReportsPage() {
  const [dateRange, setDateRange] = useState('Last 90 Days');

  return (
    <div className="space-y-12 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h3 className="text-3xl font-black text-white tracking-widest uppercase mb-1">Analytics</h3>
          <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.3em]">Quantitative Intelligence Hub</p>
        </div>
        
        {/* Date Range Filter */}
        <div className="relative group">
           <button className="flex items-center gap-4 px-6 py-4 rounded-2xl bg-white/[0.03] border border-white/10 text-white hover:bg-white/[0.06] transition-all">
              <Calendar className="h-4 w-4 text-mf-accent" />
              <span className="text-[10px] font-black uppercase tracking-[0.2em]">{dateRange}</span>
              <ChevronDown className="h-4 w-4 text-mf-muted group-hover:text-white transition-all" />
           </button>
           <div className="absolute top-full right-0 mt-2 w-56 glass-card rounded-2xl p-2 opacity-0 group-hover:opacity-100 pointer-events-none group-hover:pointer-events-auto transition-all z-20">
              {['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'This Year', 'All Time'].map(range => (
                <button 
                  key={range}
                  onClick={() => setDateRange(range)}
                  className="w-full text-left px-4 py-3 rounded-xl hover:bg-white/5 text-[10px] font-black text-mf-muted hover:text-white uppercase tracking-widest transition-all"
                >
                  {range}
                </button>
              ))}
           </div>
        </div>
      </div>

      <div className="grid gap-6 grid-cols-1 lg:grid-cols-3">
        <SummaryCard 
          label="Savings Rate" 
          value="34.2%" 
          note="+2.1% Alpha" 
          icon={TrendingUp} 
          color="#22C697" 
        />
        <SummaryCard 
          label="Burn Velocity" 
          value="₹58.7k" 
          note="-7.4% Momentum" 
          icon={TrendingDown} 
          color="#8B7DFF" 
        />
        <SummaryCard 
          label="Dominant Vector" 
          value="Shelter" 
          note="₹45k Magnitude" 
          icon={PieChartIcon} 
          color="#FFD166" 
        />
      </div>

      <div className="grid gap-8 lg:grid-cols-2">
        {/* Spending by Category (Pie) */}
        <div className="glass-card rounded-[40px] p-10 relative overflow-hidden group">
           <div className="absolute -right-20 -top-20 h-64 w-64 rounded-full bg-mf-accent/5 blur-[80px] group-hover:scale-125 transition-all duration-1000" />
           
           <div className="relative z-10 mb-10">
              <h3 className="text-xl font-black text-white uppercase tracking-[0.15em] flex items-center gap-3">
                <PieChartIcon className="h-5 w-5 text-mf-accent animate-pulse" />
                Distribution
              </h3>
              <p className="text-[9px] font-black text-mf-muted uppercase tracking-[0.3em] mt-2">Spending Density Analysis</p>
           </div>
           
           <div className="h-[380px] relative z-10">
             <ResponsiveContainer width="100%" height="100%">
               <PieChart>
                 <Pie
                   data={categoryData}
                   innerRadius={90}
                   outerRadius={135}
                   paddingAngle={8}
                   dataKey="value"
                   className="focus:outline-none"
                 >
                   {categoryData.map((entry, index) => (
                     <Cell key={`cell-${index}`} fill={entry.color} stroke="none" className="hover:opacity-80 transition-all cursor-pointer" />
                   ))}
                 </Pie>
                 <Tooltip 
                   contentStyle={{ background: '#0D0F1A', border: '1px solid #ffffff14', borderRadius: '16px', padding: '16px' }}
                   itemStyle={{ color: '#fff', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.1em' }}
                 />
                 <Legend 
                   verticalAlign="bottom" 
                   align="center"
                   iconType="circle"
                   iconSize={8}
                   formatter={(v: any) => <span className="text-[9px] font-black text-mf-muted uppercase tracking-widest pl-2 hover:text-white transition-all">{v}</span>} 
                 />
               </PieChart>
             </ResponsiveContainer>
           </div>
        </div>

        {/* Cash Flow Performance (Bar) */}
        <div className="glass-card rounded-[40px] p-10 relative overflow-hidden group">
           <div className="absolute -left-20 -bottom-20 h-64 w-64 rounded-full bg-mf-success/5 blur-[80px] group-hover:scale-125 transition-all duration-1000" />

           <div className="relative z-10 mb-10">
              <h3 className="text-xl font-black text-white uppercase tracking-[0.15em] flex items-center gap-3">
                <BarChartIcon className="h-5 w-5 text-mf-success" />
                Velocity
              </h3>
              <p className="text-[9px] font-black text-mf-muted uppercase tracking-[0.3em] mt-2">Revenue vs Burn Trajectory</p>
           </div>

           <div className="h-[380px] relative z-10">
             <ResponsiveContainer width="100%" height="100%">
               <BarChart data={monthlyData} barGap={16}>
                 <CartesianGrid strokeDasharray="6 6" stroke="#ffffff08" vertical={false} />
                 <XAxis dataKey="month" stroke="#8D93A1" fontSize={9} axisLine={false} tickLine={false} tick={{dy: 15, fontWeight: 900}} />
                 <YAxis stroke="#8D93A1" fontSize={9} axisLine={false} tickLine={false} tickFormatter={(v: any) => `₹${v/1000}k`} tick={{fontWeight: 900}} />
                 <Tooltip
                   cursor={{fill: 'rgba(255,255,255,0.03)'}}
                   contentStyle={{ background: '#0D0F1A', border: '1px solid #ffffff14', borderRadius: '20px', padding: '16px' }}
                 />
                 <Bar dataKey="income" fill="#22C697" radius={[6, 6, 0, 0]} barSize={24} />
                 <Bar dataKey="expense" fill="#8B7DFF" radius={[6, 6, 0, 0]} barSize={24} />
               </BarChart>
             </ResponsiveContainer>
           </div>
        </div>
      </div>

      {/* FOOTER: Insight Panel */}
      <div className="glass-card rounded-[32px] p-10 flex flex-col lg:flex-row items-center justify-between gap-8 border-l-4 border-l-mf-accent">
        <div className="flex items-center gap-8 text-center lg:text-left">
           <div className="h-16 w-16 rounded-[24px] bg-mf-accent/10 flex items-center justify-center text-mf-accent shadow-neon-purple shadow-mf-accent/20">
             <TrendingUp className="h-8 w-8" />
           </div>
           <div>
             <h4 className="text-2xl font-black text-white tracking-widest uppercase mb-1">Financial Alpha</h4>
             <p className="text-[11px] font-bold text-mf-muted uppercase tracking-widest leading-relaxed max-w-xl">
                Current data patterns indicate a <span className="text-white underline">15% increase</span> in discretionary liquidity. 
                Consider tactical allocation to recurring yield instruments.
             </p>
           </div>
        </div>
        <button className="flex items-center gap-3 px-8 py-4 rounded-2xl bg-white/5 border border-white/10 text-white font-black text-[10px] uppercase tracking-[0.2em] group hover:bg-mf-accent hover:text-white hover:border-mf-accent transition-all">
          Execute Detailed Audit
          <ArrowRight className="h-4 w-4 group-hover:translate-x-2 transition-all" />
        </button>
      </div>
    </div>
  );
}

function SummaryCard({ label, value, note, icon: Icon, color }: any) {
  return (
    <div className="glass-card rounded-[32px] p-10 relative overflow-hidden group">
      <div className="absolute -right-4 -top-4 p-8 opacity-10 transition-all group-hover:scale-125 duration-500">
        <Icon className="h-20 w-20" style={{ color }} />
      </div>
      <p className="text-[10px] font-black text-mf-muted uppercase tracking-[0.3em] mb-3">{label}</p>
      <h4 className="text-3xl font-black text-white tracking-[0.1em] mb-3">{value}</h4>
      <div className="flex items-center gap-2">
         <div className="h-1.5 w-1.5 rounded-full animate-pulse" style={{ backgroundColor: color }} />
         <p className="text-[10px] font-black uppercase tracking-widest" style={{ color }}>{note}</p>
      </div>
    </div>
  );
}


