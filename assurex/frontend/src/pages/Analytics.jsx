import React, { useEffect, useState } from 'react';
import axios from 'axios';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from 'recharts';

// Backend runs via the root docker-compose (assurex-api service, host port
// 8002) — override with VITE_API_BASE in .env for a different setup.
const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8002/api';

const STATUS_LABELS = { new: 'Nouveau', estimation: 'Estimation', review: 'Révision', completed: 'Terminé' };
const STATUS_COLORS = { new: '#3b82f6', estimation: '#a855f7', review: '#f97316', completed: '#22c55e' };
const GRAVITY_COLORS = { Critical: '#ef4444', High: '#ef4444', Moderate: '#f97316', Minor: '#22c55e', Unrated: '#9ca3af' };
const PAYMENT_COLORS = { paid: '#22c55e', unpaid: '#ef4444' };
const CATEGORY_PALETTE = ['#0ea5e9', '#a855f7', '#f97316', '#22c55e', '#eab308', '#ec4899', '#6366f1'];
const MOOD_LABELS = { calm: 'Calme', concerned: 'Préoccupé', stressed: 'Stressé', distressed: 'En détresse' };
const MOOD_COLORS = { calm: '#22c55e', concerned: '#eab308', stressed: '#f97316', distressed: '#ef4444' };

const KpiCard = ({ icon, label, value, accent = 'text-primary' }) => (
  <div className="bg-white rounded-2xl border border-outline-variant/30 card-shadow p-6 flex items-center gap-4">
    <div className={`w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center ${accent}`}>
      <span className="material-symbols-outlined">{icon}</span>
    </div>
    <div>
      <p className={`font-headline-md text-headline-md font-extrabold ${accent}`}>{value}</p>
      <p className="text-xs text-on-surface-variant font-bold uppercase tracking-wide mt-0.5">{label}</p>
    </div>
  </div>
);

const ChartCard = ({ title, children, className = '' }) => (
  <div className={`bg-white rounded-[24px] border border-outline-variant/30 card-shadow p-6 flex flex-col ${className}`}>
    <h4 className="font-label-md font-bold text-on-surface mb-4">{title}</h4>
    <div className="flex-1 min-h-[260px]">{children}</div>
  </div>
);

const AnalyticsPage = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchOverview = async () => {
      try {
        setLoading(true);
        const res = await axios.get(`${API_BASE}/analytics/overview`);
        setData(res.data);
        setLoading(false);
      } catch (err) {
        console.error('Error fetching analytics:', err);
        setError("Impossible de charger les statistiques.");
        setLoading(false);
      }
    };
    fetchOverview();
  }, []);

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[60vh]">
        <div className="h-12 w-12 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="p-10 flex flex-col items-center justify-center min-h-[60vh] gap-4 text-on-surface-variant">
        <span className="material-symbols-outlined text-[64px] opacity-50">query_stats</span>
        <p>{error || 'Aucune donnée disponible.'}</p>
      </div>
    );
  }

  const statusData = data.claims_by_status.map((d) => ({
    ...d,
    label: STATUS_LABELS[d.status] || d.status,
    fill: STATUS_COLORS[d.status] || '#9ca3af',
  }));
  const gravityData = data.claims_by_gravity.map((d) => ({
    ...d,
    fill: GRAVITY_COLORS[d.gravity] || '#9ca3af',
  }));
  const paymentData = data.clients_by_payment_status.map((d) => ({
    ...d,
    label: d.status === 'paid' ? 'Payé' : 'Impayé',
    fill: PAYMENT_COLORS[d.status] || '#9ca3af',
  }));
  const categoryData = data.clients_by_car_category;
  const moodData = (data.mood?.distribution || []).map((d) => ({
    ...d,
    label: MOOD_LABELS[d.mood] || d.mood,
    fill: MOOD_COLORS[d.mood] || '#9ca3af',
  }));
  const hasMoodData = (data.mood?.total_tracked || 0) > 0;

  return (
    <main className="flex-1 overflow-y-auto bg-background p-8 custom-scrollbar">
      <div className="max-w-[1440px] mx-auto space-y-8">
        <header>
          <h2 className="font-headline-xl text-headline-xl text-on-surface">Analyse</h2>
          <p className="text-body-lg text-on-surface-variant mt-1 font-medium">
            Vue d'ensemble statistique de toutes les données du portail — sinistres, clients, dossiers mobiles.
          </p>
        </header>

        {/* KPI row */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          <KpiCard icon="folder_open" label="Sinistres totaux" value={data.kpis.total_claims} />
          <KpiCard icon="group" label="Clients totaux" value={data.kpis.total_clients} />
          <KpiCard icon="payments" label="Clients impayés" value={data.kpis.unpaid_clients} accent="text-error" />
          <KpiCard icon="photo_camera" label="Photos envoyées" value={data.kpis.photos_uploaded} accent="text-orange-500" />
          <KpiCard
            icon="balance"
            label="Nécessite révision"
            value={`${data.kpis.fault_needs_review_pct}%`}
            accent="text-purple-500"
          />
        </div>

        {/* Charts grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <ChartCard title="Sinistres par statut">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={statusData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
                <Tooltip />
                <Bar dataKey="count" radius={[8, 8, 0, 0]}>
                  {statusData.map((entry, idx) => (
                    <Cell key={idx} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Sinistres par gravité">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={gravityData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                <XAxis dataKey="gravity" tick={{ fontSize: 12 }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
                <Tooltip />
                <Bar dataKey="count" radius={[8, 8, 0, 0]}>
                  {gravityData.map((entry, idx) => (
                    <Cell key={idx} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Statut de paiement des clients">
            {paymentData.length === 0 ? (
              <div className="h-full flex items-center justify-center text-on-surface-variant text-sm">Aucune donnée</div>
            ) : (
              <ResponsiveContainer width="100%" height={260}>
                <PieChart>
                  <Pie data={paymentData} dataKey="count" nameKey="label" innerRadius={60} outerRadius={95} paddingAngle={2}>
                    {paymentData.map((entry, idx) => (
                      <Cell key={idx} fill={entry.fill} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            )}
          </ChartCard>

          <ChartCard title="Répartition par catégorie de véhicule">
            {categoryData.length === 0 ? (
              <div className="h-full flex items-center justify-center text-on-surface-variant text-sm">Aucune donnée</div>
            ) : (
              <ResponsiveContainer width="100%" height={260}>
                <PieChart>
                  <Pie data={categoryData} dataKey="count" nameKey="category" innerRadius={60} outerRadius={95} paddingAngle={2}>
                    {categoryData.map((entry, idx) => (
                      <Cell key={idx} fill={CATEGORY_PALETTE[idx % CATEGORY_PALETTE.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            )}
          </ChartCard>

          <ChartCard title="Sinistres déclarés dans le temps" className={hasMoodData ? '' : 'lg:col-span-2'}>
            {data.claims_over_time.length === 0 ? (
              <div className="h-full flex items-center justify-center text-on-surface-variant text-sm">Aucune donnée</div>
            ) : (
              <ResponsiveContainer width="100%" height={260}>
                <LineChart data={data.claims_over_time}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                  <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                  <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
                  <Tooltip />
                  <Line type="monotone" dataKey="count" stroke="#6366f1" strokeWidth={3} dot={{ r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            )}
          </ChartCard>

          {/* Only shown once real conversations have actually triggered the
              assistant's note_mood tool - see analytics.py's build_overview
              mood block. Empty/no-op otherwise, not a fake placeholder. */}
          {hasMoodData && (
            <ChartCard title="État émotionnel des clients (constat chat)">
              <ResponsiveContainer width="100%" height={260}>
                <PieChart>
                  <Pie data={moodData} dataKey="count" nameKey="label" innerRadius={60} outerRadius={95} paddingAngle={2}>
                    {moodData.map((entry, idx) => (
                      <Cell key={idx} fill={entry.fill} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex justify-around mt-4 pt-4 border-t border-outline-variant/20 text-center">
                <div>
                  <p className="font-headline-md text-headline-md font-extrabold text-error">{data.mood.injury_mentioned_count}</p>
                  <p className="text-[11px] text-on-surface-variant font-bold uppercase tracking-wide">Blessure mentionnée</p>
                </div>
                <div>
                  <p className="font-headline-md text-headline-md font-extrabold text-orange-500">{data.mood.dispute_mentioned_count}</p>
                  <p className="text-[11px] text-on-surface-variant font-bold uppercase tracking-wide">Litige mentionné</p>
                </div>
              </div>
            </ChartCard>
          )}
        </div>
      </div>
    </main>
  );
};

export default AnalyticsPage;
