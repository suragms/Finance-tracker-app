'use client';

import { apiFetch, getToken } from '@/lib/api';
import { isoDate } from '@/lib/format';
import Link from 'next/link';
import { useCallback, useEffect, useState } from 'react';
import { Search, Filter, Mail, Calendar, User, MoreVertical, ChevronLeft, ChevronRight, ShieldCheck } from 'lucide-react';

type Row = {
  id: string;
  name: string | null;
  email: string | null;
  phone: string | null;
  appUserStatus: string;
  currency: string | null;
  createdAt: string;
};

type ListRes = { rows: Row[]; total: number };

export default function UsersPage() {
  const [data, setData] = useState<ListRes | null>(null);
  const [err, setErr] = useState('');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<'all' | 'active' | 'banned'>('all');
  const [skip, setSkip] = useState(0);
  const [loading, setLoading] = useState(true);
  const take = 15;

  const load = useCallback(() => {
    setLoading(true);
    setErr('');
    const q = new URLSearchParams();
    if (search.trim()) q.set('search', search.trim());
    if (status !== 'all') q.set('status', status);
    q.set('skip', String(skip));
    q.set('take', String(take));
    apiFetch<ListRes>(`/admin/users?${q}`, { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'))
      .finally(() => setLoading(false));
  }, [search, status, skip]);

  useEffect(() => {
    load();
  }, [load]);

  if (err) return (
    <div className="bg-error/5 border border-error/20 p-8 rounded-2xl text-error text-center">
      <p className="font-bold">Failed to load users: {err}</p>
    </div>
  );

  return (
    <div className="space-y-8 pb-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Access Management</h1>
          <p className="text-mf-muted text-sm mt-1">Review and manage workspace collaborators and app users.</p>
        </div>
        
        <div className="flex flex-wrap gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-mf-muted" />
            <input
              placeholder="Search by name or email..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setSkip(0);
              }}
              className="pl-10 pr-4 py-2.5 rounded-xl border border-mf-border bg-white text-sm font-medium focus:border-primary outline-none transition-all w-64 shadow-sm"
            />
          </div>
          <select
            value={status}
            onChange={(e) => {
              setSkip(0);
              setStatus(e.target.value as typeof status);
            }}
            className="px-4 py-2.5 rounded-xl border border-mf-border bg-white text-sm font-semibold text-mf-dark outline-none focus:border-primary shadow-sm"
          >
            <option value="all">All Status</option>
            <option value="active">Active Only</option>
            <option value="banned">Banned Only</option>
          </select>
        </div>
      </div>

      <div className="bg-white border border-mf-border rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
           <div className="p-20 flex flex-col items-center justify-center gap-4">
              <div className="h-8 w-8 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
              <p className="text-sm font-medium text-mf-muted">Fetching users...</p>
           </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="premium-table">
              <thead>
                <tr>
                  <th className="pl-6">Identity</th>
                  <th>Communication</th>
                  <th>Status</th>
                  <th>Joined Date</th>
                  <th className="pr-6 text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                {data?.rows.map((u) => (
                  <tr key={u.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="pl-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="h-10 w-10 rounded-full bg-primary/5 border border-primary/10 flex items-center justify-center font-bold text-primary">
                          {u.name ? u.name[0] : <User className="h-4 w-4" />}
                        </div>
                        <div>
                          <p className="text-sm font-bold text-mf-dark">{u.name ?? 'Unknown User'}</p>
                          <p className="text-[10px] text-mf-muted font-bold uppercase tracking-wider">UID: {u.id.slice(0, 8)}</p>
                        </div>
                      </div>
                    </td>
                    <td className="py-4">
                      <div className="flex flex-col gap-1">
                        <div className="flex items-center gap-2 text-xs font-medium text-mf-dark">
                          <Mail className="h-3 w-3 text-mf-muted" />
                          {u.email ?? 'no-email'}
                        </div>
                        {u.phone && (
                          <div className="text-[10px] text-mf-muted">{u.phone}</div>
                        )}
                      </div>
                    </td>
                    <td className="py-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest ${
                          u.appUserStatus === 'banned'
                            ? 'bg-error/10 text-error'
                            : 'bg-success/10 text-success'
                        }`}
                      >
                        <div className={`h-1.5 w-1.5 rounded-full ${u.appUserStatus === 'banned' ? 'bg-error' : 'bg-success'}`} />
                        {u.appUserStatus}
                      </span>
                    </td>
                    <td className="py-4">
                      <div className="flex items-center gap-2 text-xs font-semibold text-mf-muted">
                        <Calendar className="h-3 w-3" />
                        {isoDate(u.createdAt)}
                      </div>
                    </td>
                    <td className="pr-6 py-4 text-right">
                      <Link
                        href={`/dashboard/users/${u.id}`}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold text-primary hover:bg-primary/5 transition-all"
                      >
                        Manage
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="flex items-center justify-between text-xs font-semibold text-mf-muted">
        <span>
          Showing {data?.rows.length || 0} of {data?.total || 0} users
        </span>
        <div className="flex gap-2">
          <button
            onClick={() => setSkip((s) => Math.max(0, s - take))}
            disabled={skip === 0 || loading}
            className="flex items-center gap-1 px-4 py-2 rounded-xl border border-mf-border bg-white hover:bg-gray-50 disabled:opacity-40 transition-all shadow-sm"
          >
            <ChevronLeft className="h-4 w-4" />
            Prev
          </button>
          <button
            onClick={() => setSkip((s) => s + take)}
            disabled={!data || skip + take >= data.total || loading}
            className="flex items-center gap-1 px-4 py-2 rounded-xl border border-mf-border bg-white hover:bg-gray-50 disabled:opacity-40 transition-all shadow-sm"
          >
            Next
            <ChevronRight className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );
}

