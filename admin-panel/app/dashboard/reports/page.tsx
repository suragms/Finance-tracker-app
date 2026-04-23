'use client';

import { 
  PieChart as PieChartIcon, 
  TrendingUp, 
  TrendingDown, 
  Calendar,
  ArrowRight,
  BarChart as BarChartIcon,
  ChevronDown,
  Download,
  Filter
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
  { name: 'Household', value: 45000, color: '#4F46E5' },
  { name: 'Food', value: 12000, color: '#10B981' },
  { name: 'Transport', value: 8000, color: '#F59E0B' },
  { name: 'Shopping', value: 15000, color: '#6366F1' },
  { name: 'Others', value: 5000, color: '#D1D5DB' },
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
    <div className="space-y-8 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Financial Intelligence</h1>
          <p className="text-mf-muted text-sm mt-1">Deep dive into your business spending patterns and revenue flows.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-mf-border bg-white text-mf-dark hover:bg-gray-50 transition-all font-semibold text-sm">
            <Calendar className="h-4 w-4 text-primary" />
            {dateRange}
            <ChevronDown className="h-4 w-4 text-mf-muted" />
          </button>
          <button className="p-2.5 rounded-xl bg-primary text-white hover:bg-primary/90 transition-all">
            <Download className="h-5 w-5" />
          </button>
        </div>
      </div>

      <div className="grid gap-6 grid-cols-1 md:grid-cols-3">
        <SummaryCard 
          label="Avg. Savings Rate" 
          value="34.2%" 
          note="+2.1% from last month" 
          icon={TrendingUp} 
          trend="up"
        />
        <SummaryCard 
          label="Monthly Burn" 
          value="₹58,700" 
          note="-7.4% decrease" 
          icon={TrendingDown} 
          trend="down"
        />
        <SummaryCard 
          label="Top Category" 
          value="Household" 
          note="₹45,000 magnitude" 
          icon={PieChartIcon} 
          trend="neutral"
        />
      </div>

      <div className="grid gap-8 lg:grid-cols-2">
        {/* Spending Distribution */}
        <div className="bg-white border border-mf-border rounded-2xl p-8 shadow-sm">
           <div className="mb-8">
              <h3 className="text-lg font-bold text-mf-dark flex items-center gap-2">
                <PieChartIcon className="h-5 w-5 text-primary" />
                Spending Distribution
              </h3>
              <p className="text-sm text-mf-muted mt-1">Allocation across primary categories</p>
           </div>
           
           <div className="h-[350px]">
             <ResponsiveContainer width="100%" height="100%">
               <PieChart>
                 <Pie
                   data={categoryData}
                   innerRadius={80}
                   outerRadius={120}
                   paddingAngle={5}
                   dataKey="value"
                   className="focus:outline-none"
                 >
                   {categoryData.map((entry, index) => (
                     <Cell key={`cell-${index}`} fill={entry.color} stroke="#fff" strokeWidth={2} />
                   ))}
                 </Pie>
                 <Tooltip 
                   contentStyle={{ background: '#fff', border: '1px solid #E5E7EB', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                   itemStyle={{ fontSize: '12px', fontWeight: 'bold' }}
                 />
                 <Legend 
                   verticalAlign="bottom" 
                   align="center"
                   iconType="circle"
                   iconSize={10}
                   formatter={(v: any) => <span className="text-xs font-bold text-mf-muted px-2">{v}</span>} 
                 />
               </PieChart>
             </ResponsiveContainer>
           </div>
        </div>

        {/* Cash Flow Performance */}
        <div className="bg-white border border-mf-border rounded-2xl p-8 shadow-sm">
           <div className="mb-8">
              <h3 className="text-lg font-bold text-mf-dark flex items-center gap-2">
                <BarChartIcon className="h-5 w-5 text-success" />
                Cash Flow Velocity
              </h3>
              <p className="text-sm text-mf-muted mt-1">Income vs Expense trends</p>
           </div>

           <div className="h-[350px]">
             <ResponsiveContainer width="100%" height="100%">
               <BarChart data={monthlyData} barGap={8}>
                 <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" vertical={false} />
                 <XAxis dataKey="month" stroke="#9CA3AF" fontSize={11} axisLine={false} tickLine={false} tick={{dy: 10, fontWeight: 600}} />
                 <YAxis stroke="#9CA3AF" fontSize={11} axisLine={false} tickLine={false} tickFormatter={(v: any) => `₹${v/1000}k`} tick={{fontWeight: 600}} />
                 <Tooltip
                   cursor={{fill: '#F9FAFB'}}
                   contentStyle={{ background: '#fff', border: '1px solid #E5E7EB', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                 />
                 <Bar dataKey="income" fill="#10B981" radius={[4, 4, 0, 0]} barSize={20} />
                 <Bar dataKey="expense" fill="#4F46E5" radius={[4, 4, 0, 0]} barSize={20} />
               </BarChart>
             </ResponsiveContainer>
           </div>
        </div>
      </div>

      {/* AI Insights Card */}
      <div className="bg-primary/5 border border-primary/10 rounded-2xl p-8 flex flex-col lg:flex-row items-center justify-between gap-8 border-l-4 border-l-primary">
        <div className="flex items-center gap-6">
           <div className="h-14 w-14 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
             <TrendingUp className="h-7 w-7" />
           </div>
           <div>
             <h4 className="text-lg font-bold text-mf-dark tracking-tight">AI Financial Recommendation</h4>
             <p className="text-sm font-medium text-mf-muted mt-1 max-w-2xl leading-relaxed">
                Your savings rate has improved by <span className="text-success font-bold">15%</span> this quarter. 
                Based on your current cash flow, you can safely allocate ₹15,000 more towards long-term investments.
             </p>
           </div>
        </div>
        <button className="flex items-center gap-2 px-6 py-3 rounded-xl bg-white border border-primary/20 text-primary font-bold text-xs uppercase tracking-wider hover:bg-primary hover:text-white transition-all whitespace-nowrap shadow-sm">
          Detailed Analysis
          <ArrowRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}

function SummaryCard({ label, value, note, icon: Icon, trend }: any) {
  return (
    <div className="bg-white border border-mf-border rounded-2xl p-8 shadow-sm">
      <div className="flex justify-between items-start mb-4">
        <p className="text-[11px] font-bold text-mf-muted uppercase tracking-wider">{label}</p>
        <div className={`p-2 rounded-lg ${trend === 'up' ? 'bg-success/10 text-success' : trend === 'down' ? 'bg-error/10 text-error' : 'bg-gray-100 text-mf-muted'}`}>
          <Icon className="h-4 w-4" />
        </div>
      </div>
      <h4 className="text-2xl font-bold text-mf-dark tracking-tight mb-2">{value}</h4>
      <p className={`text-xs font-semibold ${trend === 'up' ? 'text-success' : trend === 'down' ? 'text-error' : 'text-mf-muted'}`}>
        {note}
      </p>
    </div>
  );
}



