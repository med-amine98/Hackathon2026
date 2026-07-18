import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';

// Backend runs via the root docker-compose (assurex-api service, host port
// 8002) — override with VITE_API_BASE in .env for a different setup.
const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8002/api';

const MONTH_LABELS = {
  '01': 'Jan', '02': 'Fév', '03': 'Mar', '04': 'Avr', '05': 'Mai', '06': 'Juin',
  '07': 'Juil', '08': 'Août', '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Déc',
};

const DashboardPage = () => {
  const [overview, setOverview] = useState(null);
  const [priorityCases, setPriorityCases] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const [overviewRes, claimsRes] = await Promise.all([
          axios.get(`${API_BASE}/analytics/overview`),
          axios.get(`${API_BASE}/claims`),
        ]);
        setOverview(overviewRes.data);

        // Filter claims to represent "Priority Cases" requiring validation
        const cases = claimsRes.data
          .filter((c) => c.status !== 'completed')
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

  if (error || !overview) {
    return (
      <main className="p-10 max-w-[1440px] mx-auto w-full flex flex-col items-center justify-center min-h-[60vh] gap-4">
        <span className="material-symbols-outlined text-[64px] text-error">cloud_off</span>
        <h2 className="font-headline-md text-headline-md text-on-surface">Connection Error</h2>
        <p className="font-body-md text-on-surface-variant max-w-md text-center">{error || 'Aucune donnée disponible.'}</p>
        <button
          onClick={() => window.location.reload()}
          className="bg-primary text-white px-6 py-2.5 rounded-xl font-label-md shadow-sm hover:brightness-110 transition-all flex items-center gap-2"
        >
          <span className="material-symbols-outlined text-[20px]">refresh</span> Retry Connection
        </button>
      </main>
    );
  }

  const statusCounts = Object.fromEntries(overview.claims_by_status.map((d) => [d.status, d.count]));
  const activeClaims = (statusCounts.new || 0) + (statusCounts.estimation || 0) + (statusCounts.review || 0);
  const completedClaims = statusCounts.completed || 0;

  const gravityCounts = Object.fromEntries(overview.claims_by_gravity.map((d) => [d.gravity, d.count]));
  const highRiskCount = (gravityCounts.Critical || 0) + (gravityCounts.High || 0);

  const chartData = overview.claims_over_time.map((d) => {
    const [, month] = d.month.split('-');
    return { label: MONTH_LABELS[month] || d.month, count: d.count };
  });
  const peak = chartData.reduce((best, cur) => (cur.count > (best?.count ?? -1) ? cur : best), null);

  return (
    <main className="p-10 space-y-10 max-w-[1440px] mx-auto w-full">
      <section className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h2 className="font-headline-xl text-headline-xl text-on-surface">Bonjour</h2>
          <p className="font-body-lg text-on-surface-variant mt-1">Voici un aperçu réel des performances de votre agence aujourd'hui.</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => navigate('/analytics')}
            className="bg-surface-container-high text-on-surface px-6 py-3 rounded-xl font-label-md flex items-center gap-2 hover:bg-surface-container-highest transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">query_stats</span>
            Voir l'analyse complète
          </button>
        </div>
      </section>

      {/* Stats Cards - all real, computed from /api/analytics/overview */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Active Claims */}
        <div className="bg-white p-6 rounded-[24px] card-shadow border border-outline-variant/30 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-primary/10 text-primary rounded-lg material-symbols-outlined">description</span>
            <span className="text-on-surface-variant font-label-sm">{overview.kpis.total_claims} au total</span>
          </div>
          <div>
            <p className="font-label-md text-on-surface-variant">Sinistres actifs</p>
            <h3 className="font-headline-lg text-headline-lg mt-1">{activeClaims}</h3>
          </div>
        </div>

        {/* Completed */}
        <div className="bg-white p-6 rounded-[24px] card-shadow border border-outline-variant/30 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-secondary/10 text-secondary rounded-lg material-symbols-outlined">task_alt</span>
            <span className="text-on-surface-variant font-label-sm">
              {overview.kpis.total_claims ? Math.round((completedClaims / overview.kpis.total_claims) * 100) : 0}%
            </span>
          </div>
          <div>
            <p className="font-label-md text-on-surface-variant">Dossiers terminés</p>
            <h3 className="font-headline-lg text-headline-lg mt-1">{completedClaims}</h3>
          </div>
        </div>

        {/* High Risk */}
        <div className="bg-error-container p-6 rounded-[24px] card-shadow border border-error/10 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-error text-white rounded-lg material-symbols-outlined">report_gmailerrorred</span>
            <span className="text-error font-label-sm font-bold">{overview.kpis.fault_needs_review_pct}% à revoir</span>
          </div>
          <div>
            <p className="font-label-md text-on-error-container">Alertes à haut risque</p>
            <h3 className="font-headline-lg text-headline-lg text-on-error-container mt-1">{highRiskCount}</h3>
          </div>
        </div>

        {/* Unpaid clients */}
        <div className="bg-white p-6 rounded-[24px] card-shadow border border-outline-variant/30 flex flex-col justify-between h-40 group hover:-translate-y-1 transition-transform">
          <div className="flex justify-between items-start">
            <span className="p-2 bg-tertiary-fixed text-tertiary rounded-lg material-symbols-outlined">payments</span>
            <span className="text-on-surface-variant font-label-sm">{overview.kpis.total_clients} clients</span>
          </div>
          <div>
            <p className="font-label-md text-on-surface-variant">Clients impayés</p>
            <h3 className="font-headline-lg text-headline-lg mt-1">{overview.kpis.unpaid_clients}</h3>
          </div>
        </div>
      </section>

      {/* Graph and Details */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-10">
        {/* Table Column */}
        <div className="lg:col-span-2 bg-white rounded-[24px] border border-outline-variant/30 card-shadow overflow-hidden flex flex-col">
          <div className="p-8 border-b border-outline-variant/20 flex justify-between items-center">
            <div>
              <h3 className="font-headline-md text-headline-md">Dossiers prioritaires</h3>
              <p className="font-body-sm text-on-surface-variant">Nécessitent une validation manuelle</p>
            </div>
            <button onClick={() => navigate('/claims')} className="text-primary font-label-md hover:underline">Voir tout</button>
          </div>
          <div className="overflow-x-auto">
            {priorityCases.length === 0 ? (
              <div className="p-10 text-center text-on-surface-variant text-sm">Aucun dossier prioritaire pour le moment.</div>
            ) : (
              <table className="w-full text-left">
                <thead className="bg-surface-container-low">
                  <tr>
                    <th className="px-8 py-4 font-label-md text-on-surface-variant">Dossier ID</th>
                    <th className="px-8 py-4 font-label-md text-on-surface-variant">Gravité</th>
                    <th className="px-8 py-4 font-label-md text-on-surface-variant">Niveau de risque</th>
                    <th className="px-8 py-4 font-label-md text-on-surface-variant">Statut</th>
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
                          {row.status === 'new' ? 'Nouveau' : row.status === 'estimation' ? 'Estimation IA' : 'En révision'}
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
            )}
          </div>
        </div>

        {/* Right side Activity & Actions */}
        <div className="flex flex-col gap-6">
          <div className="bg-white p-8 rounded-[24px] border border-outline-variant/30 card-shadow flex-1">
            <h3 className="font-label-md text-on-surface mb-6 font-bold">Sinistres déclarés (par mois)</h3>
            {chartData.length === 0 ? (
              <div className="h-48 flex items-center justify-center text-on-surface-variant text-sm">Aucune donnée</div>
            ) : (
              <ResponsiveContainer width="100%" height={190}>
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="grad1" x1="0" x2="0" y1="0" y2="1">
                      <stop offset="0%" stopColor="#3b82f6" stopOpacity={0.35} />
                      <stop offset="100%" stopColor="#3b82f6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                  <XAxis dataKey="label" tick={{ fontSize: 11 }} />
                  <YAxis allowDecimals={false} tick={{ fontSize: 11 }} width={24} />
                  <Tooltip />
                  <Area type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={3} fill="url(#grad1)" />
                </AreaChart>
              </ResponsiveContainer>
            )}
            {peak && (
              <div className="mt-6 flex justify-between items-center bg-surface-container-low p-4 rounded-xl cursor-pointer hover:bg-surface-container-high transition-colors" onClick={() => navigate('/analytics')}>
                <div>
                  <p className="text-[11px] text-on-surface-variant font-bold">PIC MENSUEL</p>
                  <p className="font-label-md text-on-surface">{peak.count} sinistres / {peak.label}</p>
                </div>
                <span className="material-symbols-outlined text-primary">arrow_forward_ios</span>
              </div>
            )}
          </div>

          <div className="bg-white p-8 rounded-[24px] border border-outline-variant/30 card-shadow">
            <h3 className="font-label-md text-on-surface mb-6 font-bold">Actions rapides</h3>
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
                    <p className="font-label-md text-on-surface font-bold">Dossiers à haut risque</p>
                    <p className="text-[12px] text-on-surface-variant">Examiner les éléments actifs</p>
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
