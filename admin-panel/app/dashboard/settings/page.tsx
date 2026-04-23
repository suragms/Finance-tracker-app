'use client';

import { User, Bell, Shield, Wallet, Globe, Moon, Save, Camera, Check } from 'lucide-react';
import { useState } from 'react';

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState('profile');
  const [success, setSuccess] = useState(false);

  const handleSave = () => {
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
  };

  return (
    <div className="space-y-8 pb-12 max-w-5xl">
      <div>
        <h3 className="text-xl font-extrabold text-white">Application Settings</h3>
        <p className="text-xs font-bold text-mf-muted uppercase tracking-wider">Configure your profile and preferences</p>
      </div>

      <div className="grid gap-8 lg:grid-cols-[1fr,2fr]">
        {/* Left Column: Navigation Section */}
        <div className="space-y-6">
          <div className="glass-card rounded-[32px] overflow-hidden p-4">
            <div className="space-y-2">
              <SettingsNav 
                label="Profile" 
                icon={User} 
                active={activeTab === 'profile'} 
                onClick={() => setActiveTab('profile')} 
              />
              <SettingsNav 
                label="Preferences" 
                icon={Moon} 
                active={activeTab === 'preferences'} 
                onClick={() => setActiveTab('preferences')} 
              />
              <SettingsNav 
                label="Security" 
                icon={Shield} 
                active={activeTab === 'security'} 
                onClick={() => setActiveTab('security')} 
              />
              <SettingsNav 
                label="Notifications" 
                icon={Bell} 
                active={activeTab === 'notifications'} 
                onClick={() => setActiveTab('notifications')} 
              />
            </div>
          </div>

          <div className="glass-card rounded-[32px] p-6 text-center">
             <div className="h-16 w-16 mx-auto mb-4 bg-mf-accent/10 rounded-2xl flex items-center justify-center text-mf-accent">
               <Wallet className="h-8 w-8" />
             </div>
             <p className="text-xs font-extrabold text-white uppercase tracking-widest mb-1">Backup Data</p>
             <p className="text-[10px] text-mf-muted font-bold uppercase mb-4 opacity-60">Last sync: 2 hours ago</p>
             <button className="w-full py-3 rounded-xl border border-white/10 text-[10px] font-extrabold uppercase tracking-widest text-white hover:bg-white/5 transition-all">
               Run Manual Sync
             </button>
          </div>
        </div>

        {/* Right Column: Dynamic Form Section */}
        <div className="glass-card rounded-[32px] p-10 space-y-10">
          {activeTab === 'profile' && (
            <div className="space-y-10 animate-in fade-in slide-in-from-right-4 duration-500">
               <div>
                  <h4 className="text-lg font-extrabold text-white mb-6">Personal Profile</h4>
                  <div className="flex items-center gap-8 mb-10">
                    <div className="relative group">
                      <div className="h-24 w-24 rounded-[32px] bg-gradient-to-br from-mf-accent to-mf-purple flex items-center justify-center text-3xl font-bold shadow-neon-purple border-2 border-white/10">
                        S
                      </div>
                      <button className="absolute -bottom-2 -right-2 h-10 w-10 rounded-2xl bg-mf-bg border border-white/10 flex items-center justify-center text-mf-muted hover:text-white transition-all shadow-xl opacity-0 group-hover:opacity-100 scale-90 group-hover:scale-100">
                        <Camera className="h-5 w-5" />
                      </button>
                    </div>
                    <div>
                       <p className="text-sm font-bold text-white uppercase tracking-widest mb-1">Surag Ms</p>
                       <p className="text-xs font-bold text-mf-muted">suragms@example.com</p>
                       <div className="mt-4 flex gap-2">
                         <span className="px-3 py-1 rounded-full bg-mf-accent/10 border border-mf-accent/20 text-[10px] font-extrabold text-mf-accent tracking-widest uppercase">Admin</span>
                         <span className="px-3 py-1 rounded-full bg-white/5 border border-white/10 text-[10px] font-extrabold text-mf-muted tracking-widest uppercase">Wealth Pro</span>
                       </div>
                    </div>
                  </div>

                  <div className="grid gap-6 sm:grid-cols-2">
                    <SettingsInput label="Full Name" value="Surag Ms" />
                    <SettingsInput label="Email Address" value="suragms@example.com" />
                    <SettingsInput label="Display Name" value="Surag" />
                    <SettingsInput label="Location" value="Kerala, India" />
                  </div>
               </div>
            </div>
          )}

          {activeTab === 'preferences' && (
            <div className="space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
               <h4 className="text-lg font-extrabold text-white">App Preferences</h4>
               <div className="space-y-4">
                  <SettingsToggle label="Dark Theme" description="Enable night mode for better visibility" active={true} />
                  <SettingsToggle label="Auto Sync" description="Keep your data synchronized in background" active={true} />
                  <SettingsToggle label="Wealth Insights" description="Receive AI-powered financial recommendations" active={false} />
                  <SettingsToggle label="Compact View" description="Show more data in tables with less padding" active={false} />
               </div>
               
               <div className="pt-6 border-t border-white/5">
                  <div className="grid gap-6 sm:grid-cols-2">
                     <div className="space-y-2">
                        <label className="text-[10px] font-extrabold uppercase tracking-widest text-mf-muted pl-1">Primary Currency</label>
                        <select className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-sm font-bold text-white appearance-none focus:outline-none focus:border-mf-accent">
                           <option>INR (₹)</option>
                           <option>USD ($)</option>
                           <option>EUR (€)</option>
                        </select>
                     </div>
                     <div className="space-y-2">
                        <label className="text-[10px] font-extrabold uppercase tracking-widest text-mf-muted pl-1">Regional Language</label>
                        <select className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-sm font-bold text-white appearance-none focus:outline-none focus:border-mf-accent">
                           <option>English (US)</option>
                           <option>English (UK)</option>
                           <option>Hindi</option>
                        </select>
                     </div>
                  </div>
               </div>
            </div>
          )}

          <div className="pt-10 border-t border-white/5 flex items-center justify-between">
             <div className={`flex items-center gap-2 text-mf-success text-xs font-extrabold uppercase tracking-widest transition-all ${success ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'}`}>
                <Check className="h-4 w-4" />
                Changes saved successfully
             </div>
             <button 
                onClick={handleSave}
                className="flex items-center gap-2 px-8 py-4 rounded-2xl bg-mf-accent text-white font-extrabold text-xs uppercase tracking-widest shadow-neon-purple hover:bg-mf-accent/90 transition-all active:scale-95"
              >
                <Save className="h-4 w-4" />
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
      className={`flex w-full items-center gap-4 px-6 py-4 rounded-2xl transition-all duration-300 ${active ? 'bg-mf-accent/10 border border-mf-accent/20 text-white shadow-neon-purple' : 'text-mf-muted hover:bg-white/5 hover:text-white'}`}
    >
      <Icon className={`h-5 w-5 ${active ? 'text-mf-accent' : ''}`} />
      <span className="text-xs font-extrabold uppercase tracking-widest">{label}</span>
    </button>
  );
}

function SettingsInput({ label, value }: { label: string, value: string }) {
  return (
    <div className="space-y-2">
      <label className="text-[10px] font-extrabold uppercase tracking-widest text-mf-muted pl-1">{label}</label>
      <input 
        type="text" 
        defaultValue={value} 
        className="w-full rounded-2xl bg-white/5 border border-white/10 px-6 py-4 text-sm font-bold text-white focus:outline-none focus:border-mf-accent transition-all"
      />
    </div>
  );
}

function SettingsToggle({ label, description, active }: { label: string, description: string, active: boolean }) {
  return (
    <div className="flex items-center justify-between py-4 group cursor-pointer">
      <div>
        <p className="text-sm font-bold text-white mb-1 group-hover:text-mf-accent transition-all">{label}</p>
        <p className="text-[10px] font-bold text-mf-muted uppercase tracking-widest opacity-60 leading-tight">{description}</p>
      </div>
      <div className={`w-12 h-6 rounded-full relative transition-all duration-300 ${active ? 'bg-mf-accent shadow-neon-purple' : 'bg-white/10'}`}>
         <div className={`absolute top-1 h-4 w-4 rounded-full bg-white transition-all duration-300 ${active ? 'left-7' : 'left-1'}`} />
      </div>
    </div>
  );
}
