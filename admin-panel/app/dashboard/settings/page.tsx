'use client';

import { User, Bell, Shield, Wallet, Globe, Moon, Save, Camera, Check, Settings, LogOut, ChevronRight, Lock } from 'lucide-react';
import { useState } from 'react';

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState('profile');
  const [success, setSuccess] = useState(false);

  const handleSave = () => {
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
  };

  return (
    <div className="space-y-8 pb-12 max-w-6xl">
      <div>
        <h1 className="text-2xl font-bold text-mf-dark tracking-tight">Settings</h1>
        <p className="text-mf-muted text-sm mt-1">Manage your account preferences and application configuration.</p>
      </div>

      <div className="grid gap-8 lg:grid-cols-[280px,1fr]">
        {/* Navigation Sidebar */}
        <div className="space-y-6">
          <div className="bg-white border border-mf-border rounded-2xl overflow-hidden shadow-sm p-4">
            <div className="space-y-1">
              <SettingsNav 
                label="Profile" 
                icon={User} 
                active={activeTab === 'profile'} 
                onClick={() => setActiveTab('profile')} 
              />
              <SettingsNav 
                label="Security" 
                icon={Lock} 
                active={activeTab === 'security'} 
                onClick={() => setActiveTab('security')} 
              />
              <SettingsNav 
                label="Workspaces" 
                icon={Wallet} 
                active={activeTab === 'workspaces'} 
                onClick={() => setActiveTab('workspaces')} 
              />
              <SettingsNav 
                label="Notifications" 
                icon={Bell} 
                active={activeTab === 'notifications'} 
                onClick={() => setActiveTab('notifications')} 
              />
            </div>
          </div>

          <div className="bg-primary/5 border border-primary/10 rounded-2xl p-6">
             <div className="h-10 w-10 mb-4 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
               <Shield className="h-5 w-5" />
             </div>
             <p className="text-sm font-bold text-mf-dark">Pro Plan Active</p>
             <p className="text-xs text-mf-muted mt-1 leading-relaxed">Your account is safe and synchronized across devices.</p>
             <button className="w-full mt-4 py-2 bg-white border border-primary/20 rounded-xl text-xs font-bold text-primary hover:bg-primary hover:text-white transition-all">
               Billing Details
             </button>
          </div>
        </div>

        {/* Form Content */}
        <div className="bg-white border border-mf-border rounded-2xl p-8 shadow-sm">
          {activeTab === 'profile' && (
            <div className="space-y-8 animate-in fade-in slide-in-from-bottom-2 duration-300">
               <div>
                  <h3 className="text-lg font-bold text-mf-dark mb-6">Personal Profile</h3>
                  <div className="flex items-center gap-8 mb-8 pb-8 border-b border-mf-border">
                    <div className="relative group">
                      <div className="h-24 w-24 rounded-2xl bg-primary/10 flex items-center justify-center text-3xl font-bold text-primary border border-primary/20">
                        SM
                      </div>
                      <button className="absolute -bottom-2 -right-2 h-9 w-9 rounded-xl bg-white border border-mf-border flex items-center justify-center text-mf-muted hover:text-mf-dark transition-all shadow-md">
                        <Camera className="h-4 w-4" />
                      </button>
                    </div>
                    <div>
                       <p className="text-base font-bold text-mf-dark">Surag Ms</p>
                       <p className="text-sm font-medium text-mf-muted">suragms@example.com</p>
                       <div className="mt-3 flex gap-2">
                         <span className="px-2.5 py-1 rounded-md bg-primary/5 border border-primary/10 text-[10px] font-bold text-primary tracking-wider uppercase">Owner</span>
                         <span className="px-2.5 py-1 rounded-md bg-success/5 border border-success/10 text-[10px] font-bold text-success tracking-wider uppercase">Verified</span>
                       </div>
                    </div>
                  </div>

                  <div className="grid gap-6 sm:grid-cols-2">
                    <SettingsInput label="Full Name" value="Surag Ms" />
                    <SettingsInput label="Email Address" value="suragms@example.com" />
                    <SettingsInput label="Phone Number" value="+91 98765 43210" />
                    <div className="space-y-2">
                        <label className="text-[11px] font-bold uppercase tracking-wider text-mf-muted">Timezone</label>
                        <select className="w-full bg-gray-50 border border-mf-border rounded-xl px-4 py-2.5 text-sm font-medium text-mf-dark focus:border-primary transition-all">
                           <option>(GMT+05:30) Chennai, Kolkata, Mumbai</option>
                           <option>(GMT+00:00) UTC</option>
                        </select>
                     </div>
                  </div>
               </div>
            </div>
          )}

          {activeTab === 'security' && (
            <div className="space-y-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
               <h3 className="text-lg font-bold text-mf-dark">Security Settings</h3>
               <div className="space-y-4">
                  <SettingsToggle label="Two-Factor Authentication" description="Add an extra layer of security to your account" active={true} />
                  <SettingsToggle label="Login Notifications" description="Get notified on every new login attempt" active={true} />
                  <SettingsToggle label="API Access" description="Enable access to public API for third-party integrations" active={false} />
               </div>
            </div>
          )}

          <div className="mt-10 pt-8 border-t border-mf-border flex items-center justify-between">
             <div className={`flex items-center gap-2 text-success text-xs font-bold uppercase tracking-wider transition-all ${success ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'}`}>
                <Check className="h-4 w-4" />
                Settings updated
             </div>
             <button 
                onClick={handleSave}
                className="btn-primary h-12 px-8 shadow-md"
              >
                <Save className="h-5 w-5" />
                Save Changes
              </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function SettingsNav({ label, icon: Icon, active, onClick }: any) {
  return (
    <button 
      onClick={onClick}
      className={`flex w-full items-center gap-3 px-4 py-2.5 rounded-xl transition-all ${active ? 'bg-primary text-white shadow-sm' : 'text-mf-muted hover:bg-gray-50 hover:text-mf-dark'}`}
    >
      <Icon className="h-4 w-4" />
      <span className="text-sm font-semibold">{label}</span>
      {active && <ChevronRight className="ml-auto h-3 w-3 opacity-60" />}
    </button>
  );
}

function SettingsInput({ label, value }: { label: string, value: string }) {
  return (
    <div className="space-y-2">
      <label className="text-[11px] font-bold uppercase tracking-wider text-mf-muted">{label}</label>
      <input 
        type="text" 
        defaultValue={value} 
        className="w-full rounded-xl bg-gray-50 border border-mf-border px-4 py-2.5 text-sm font-medium text-mf-dark focus:border-primary focus:bg-white transition-all"
      />
    </div>
  );
}

function SettingsToggle({ label, description, active }: { label: string, description: string, active: boolean }) {
  return (
    <div className="flex items-center justify-between py-4 group cursor-pointer border-b border-mf-border last:border-0">
      <div>
        <p className="text-sm font-bold text-mf-dark mb-0.5">{label}</p>
        <p className="text-xs text-mf-muted leading-tight">{description}</p>
      </div>
      <div className={`w-11 h-6 rounded-full relative transition-all duration-300 ${active ? 'bg-primary' : 'bg-gray-200'}`}>
         <div className={`absolute top-1 h-4 w-4 rounded-full bg-white transition-all duration-300 ${active ? 'left-6' : 'left-1'}`} />
      </div>
    </div>
  );
}

