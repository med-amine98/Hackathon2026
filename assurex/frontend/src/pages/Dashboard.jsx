import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';

const API_BASE = 'http://localhost:8000/api';

const DashboardPage = () => {
  const [stats, setStats] = useState(null);
  const [priorityCases, setPriorityCases] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const [statsRes, claimsRes] = await Promise.all([
          axios.get(`${API_BASE}/dashboard/stats`),
          axios.get(`${API_BASE}/claims`),
        ]);
        setStats(statsRes.data);
        
        // Filter claims to represent "Priority Cases" requiring validation
        const cases = claimsRes.data
          .filter(c => c.status !== 'completed')
          .slice(0, 3);
        setPriorityCases(cases);
        setLoading(false);
      } catch (err) {
        console.error('Error fetching dashboard data:', err);
        setError('Failed to connect to backend server. Make sure the FastAPI app is running on port 8000.');
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <main className="p-10 space-y-10 max-w-[1440px] mx-auto w-full">
        <div className="h-12 w-64 bg-surface-container-high animate-pulse rounded-lg"></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="h-40 bg-surface-container-low animate-pulse rounded-[24px] border border-outline-variant/30"></div>
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
          <div className="lg:col-span-2 h-96 bg-surface-container-low animate-pulse rounded-[24px]"></div>
          <div className="h-96 bg-surface-container-low animate-pulse rounded-[24px]"></div>
        </div>
      </main>
    );
  }

  if (error) {
    return (
      <main className="p-10 max-w-[1440px] mx-auto w-full flex flex-col items-center justify-center min-h-[60vh] gap-4">
        <span className="material-symbols-outlined text-[64px] text-error">cloud_off</span>
        <h2 className="font-headline-md text-headline-md text-on-surface">Connection Error</h2>
        <p className="font-body-md text-on-surface-variant max-w-md text-center">{error}</p>
        <button 
          onClick={() => window.location.reload()}
          className="bg-primary text-white px-6 py-2.5 rounded-xl font-label-md shadow-sm hover:brightness-110 transition-all flex items-center gap-2"
        >
          <span className="material-symbols-outlined text-[20px]">refresh</span> Retry Connection
        </button>
      </main>
    );
  }

  return (
    <main className="p-10 space-y-10 max-w-[1440px] mx-auto w-full">
      <section className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h2 className="font-headline-xl text-headline-xl text-on-surface">Good morning, Alex</h2>
          <p className="font-body-lg text-on-surface-variant mt-1">Here's an overview of your agency's performance today.</p>
        </div>
        <div className="flex gap-3">
          <button className="bg-surface-container-high text-on-surface px-6 py-3 rounded-xl font-label-md flex items-center gap-2 hover:bg-surface-container-highest transition-colors">
            <span className="material-symbols-outlined text-[20px]">file_download</span>
            Export Report
          </button>
        </div>
      </section>

      {/* Stats Cards */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Active Claims */}
        <div className="bg-white p-6 rounded-[24px] card-shadow border border-outline-variant/30 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-primary/10 text-primary rounded-lg material-symbols-outlined">description</span>
            <span className="text-green-600 font-label-sm flex items-center">
              {stats.active_claims.change}{' '}
              <span className="material-symbols-outlined text-[14px]">trending_up</span>
            </span>
          </div>
          <div>
            <p className="font-label-md text-on-surface-variant">Active Claims</p>
            <h3 className="font-headline-lg text-headline-lg mt-1">{stats.active_claims.value}</h3>
          </div>
        </div>

        {/* Processing Time */}
        <div className="bg-white p-6 rounded-[24px] card-shadow border border-outline-variant/30 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-secondary/10 text-secondary rounded-lg material-symbols-outlined">schedule</span>
            <span className="text-on-surface-variant font-label-sm">{stats.processing_time.change}</span>
          </div>
          <div>
            <p className="font-label-md text-on-surface-variant">Processing Time</p>
            <h3 className="font-headline-lg text-headline-lg mt-1">{stats.processing_time.value}</h3>
          </div>
        </div>

        {/* High Risk */}
        <div className="bg-error-container p-6 rounded-[24px] card-shadow border border-error/10 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-error text-white rounded-lg material-symbols-outlined">report_gmailerrorred</span>
            <span className="text-error font-label-sm font-bold">{stats.high_risk_alerts.change}</span>
          </div>
          <div>
            <p className="font-label-md text-on-error-container">High-Risk Alerts</p>
            <h3 className="font-headline-lg text-headline-lg text-on-error-container mt-1">{stats.high_risk_alerts.value}</h3>
          </div>
        </div>

        {/* Churn Risk */}
        <div className="bg-white p-6 rounded-[24px] card-shadow border border-outline-variant/30 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-tertiary-fixed text-tertiary rounded-lg material-symbols-outlined">monitoring</span>
            <span className="text-error font-label-sm flex items-center">
              {stats.churn_risk.change}{' '}
              <span className="material-symbols-outlined text-[14px]">trending_up</span>
            </span>
          </div>
          <div>
            <p className="font-label-md text-on-surface-variant">Churn Risk</p>
            <h3 className="font-headline-lg text-headline-lg mt-1">{stats.churn_risk.value}</h3>
          </div>
        </div>
      </section>

      {/* Graph and Details */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-10">
        {/* Table Column */}
        <div className="lg:col-span-2 bg-white rounded-[24px] border border-outline-variant/30 card-shadow overflow-hidden flex flex-col">
          <div className="p-8 border-b border-outline-variant/20 flex justify-between items-center">
            <div>
              <h3 className="font-headline-md text-headline-md">Priority Cases</h3>
              <p className="font-body-sm text-on-surface-variant">Require manual validation</p>
            </div>
            <button onClick={() => navigate('/claims')} className="text-primary font-label-md hover:underline">View All</button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-surface-container-low">
                <tr>
                  <th className="px-8 py-4 font-label-md text-on-surface-variant">Dossier ID</th>
                  <th className="px-8 py-4 font-label-md text-on-surface-variant">Gravity</th>
                  <th className="px-8 py-4 font-label-md text-on-surface-variant">Risk Level</th>
                  <th className="px-8 py-4 font-label-md text-on-surface-variant">Status</th>
                  <th className="px-8 py-4"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10">
                {priorityCases.map((row) => (
                  <tr 
                    key={row.id} 
                    className="hover:bg-surface-container-lowest transition-colors cursor-pointer"
                    onClick={() => navigate(`/ai-estimation/${row.id}`)}
                  >
                    <td className="px-8 py-6">
                      <div className="font-label-md text-on-surface font-bold">#{row.id}</div>
                      <div className="text-[12px] text-on-surface-variant">{row.vehicle}</div>
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-1">
                        <span className={`w-2 h-2 rounded-full ${row.gravity_color || 'bg-primary'}`}></span>
                        <span className="font-body-sm">{row.gravity}</span>
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      <div className="w-24 h-2 bg-surface-container-high rounded-full overflow-hidden mb-1">
                        <div 
                          className={`h-full ${row.gravity === 'Critical' ? 'bg-error' : row.gravity === 'Moderate' ? 'bg-orange-500' : 'bg-green-500'}`} 
                          style={{ width: `${row.risk}%` }}
                        ></div>
                      </div>
                      <span className={`text-[11px] font-bold ${row.risk_color || 'text-primary'}`}>{row.risk_text}</span>
                    </td>
                    <td className="px-8 py-6">
                      <span className="px-3 py-1 bg-primary-fixed/50 text-on-primary-fixed-variant rounded-full text-[12px] font-bold uppercase">
                        {row.status === 'new' ? 'New' : row.status === 'estimation' ? 'AI Estimate' : 'Under Review'}
                      </span>
                    </td>
                    <td className="px-8 py-6 text-right" onClick={(e) => e.stopPropagation()}>
                      <button className="p-2 hover:bg-surface-container rounded-full">
                        <span className="material-symbols-outlined text-[20px]">more_vert</span>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Right side Activity & Actions */}
        <div className="flex flex-col gap-6">
          <div className="bg-white p-8 rounded-[24px] border border-outline-variant/30 card-shadow flex-1">
            <h3 className="font-label-md text-on-surface mb-6 font-bold">Activity Overview</h3>
            <div className="relative h-48 w-full flex items-end justify-between gap-2 px-2">
              <svg className="absolute inset-0 w-full h-full" preserveAspectRatio="none" viewBox="0 0 400 150">
                <path d="M0,130 Q50,110 100,120 T200,60 T300,90 T400,30" fill="none" stroke="#3b82f6" strokeLinecap="round" strokeWidth="4"></path>
                <path d="M0,130 Q50,110 100,120 T200,60 T300,90 T400,30 L400,150 L0,150 Z" fill="url(#grad1)" opacity="0.1"></path>
                <defs>
                  <linearGradient id="grad1" x1="0%" x2="0%" y1="0%" y2="100%">
                    <stop offset="0%" style={{ stopColor: '#3b82f6', stopOpacity: 1 }}></stop>
                    <stop offset="100%" style={{ stopColor: '#3b82f6', stopOpacity: 0 }}></stop>
                  </linearGradient>
                </defs>
              </svg>
              <div className="w-full flex justify-between absolute bottom-[-24px] text-[10px] text-on-surface-variant font-bold uppercase">
                <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
              </div>
            </div>
            <div className="mt-12 flex justify-between items-center bg-surface-container-low p-4 rounded-xl cursor-pointer hover:bg-surface-container-high transition-colors">
              <div>
                <p className="text-[11px] text-on-surface-variant font-bold">WEEKLY PEAK</p>
                <p className="font-label-md text-on-surface">342 Claims / Thu</p>
              </div>
              <span className="material-symbols-outlined text-primary">arrow_forward_ios</span>
            </div>
          </div>

          <div className="bg-white p-8 rounded-[24px] border border-outline-variant/30 card-shadow">
            <h3 className="font-label-md text-on-surface mb-6 font-bold">Quick Actions</h3>
            <div className="space-y-4">
              <button 
                onClick={() => navigate('/claims')}
                className="w-full flex items-center justify-between p-4 bg-surface-container-low rounded-2xl hover:bg-error/5 group transition-all"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-xl bg-error text-white flex items-center justify-center">
                    <span className="material-symbols-outlined">gpp_maybe</span>
                  </div>
                  <div className="text-left">
                    <p className="font-label-md text-on-surface font-bold">High-Risk Files</p>
                    <p className="text-[12px] text-on-surface-variant">Review active items</p>
                  </div>
                </div>
                <span className="material-symbols-outlined text-outline-variant group-hover:text-error transition-colors">chevron_right</span>
              </button>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
};

export default DashboardPage;