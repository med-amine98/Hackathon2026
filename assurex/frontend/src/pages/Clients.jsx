import React, { useEffect, useState } from 'react';
import axios from 'axios';

const API_BASE = 'http://localhost:8000/api';

const ClientsPage = () => {
  const [clients, setClients] = useState([]);
  const [selectedClientId, setSelectedClientId] = useState('c-1');
  const [searchQuery, setSearchQuery] = useState('');
  const [newNoteText, setNewNoteText] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchClients = async () => {
    try {
      setLoading(true);
      const res = await axios.get(`${API_BASE}/clients`);
      setClients(res.data);
      setLoading(false);
    } catch (err) {
      console.error('Error fetching clients:', err);
      setError('Could not fetch clients list.');
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchClients();
  }, []);

  const handleAddNote = async (e) => {
    e.preventDefault();
    if (!newNoteText.trim()) return;

    try {
      await axios.post(`${API_BASE}/clients/${selectedClientId}/notes`, {
        text: newNoteText,
        author: 'Alex (Agent)',
      });
      setNewNoteText('');
      // Refresh clients data to see new note
      const res = await axios.get(`${API_BASE}/clients`);
      setClients(res.data);
    } catch (err) {
      console.error('Error adding note:', err);
      alert('Failed to add note.');
    }
  };

  if (loading && clients.length === 0) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[60vh]">
        <div className="h-12 w-12 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  const activeClient = clients.find((c) => c.id === selectedClientId) || clients[0];

  const filteredClients = clients.filter((c) =>
    c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.type.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <main className="flex-1 overflow-y-auto bg-background p-8 custom-scrollbar">
      <div className="max-w-[1440px] mx-auto">
        <header className="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <h2 className="font-headline-xl text-headline-xl text-on-surface">Client Relationship Center</h2>
            <p className="text-body-lg text-on-surface-variant mt-1 font-medium">
              Manage fidelity and track customer satisfaction across the AssureX portfolio.
            </p>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Master List (Left) */}
          <div className="lg:col-span-4 bg-white rounded-[24px] border border-outline-variant/30 card-shadow p-6 space-y-6">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant">search</span>
              <input
                type="text"
                placeholder="Search clients..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-surface-container-low border border-outline-variant/10 rounded-xl py-2.5 pl-10 pr-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
              />
            </div>

            <div className="space-y-3 max-h-[500px] overflow-y-auto pr-1">
              {filteredClients.map((client) => (
                <div
                  key={client.id}
                  onClick={() => setSelectedClientId(client.id)}
                  className={`p-4 rounded-2xl cursor-pointer border transition-all flex items-center justify-between ${
                    selectedClientId === client.id
                      ? 'bg-primary-container/20 border-primary ring-1 ring-primary'
                      : 'bg-surface-container-low border-outline-variant/10 hover:border-primary/20'
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-sm">
                      {client.initials}
                    </div>
                    <div>
                      <h4 className="font-label-md font-bold text-on-surface">{client.name}</h4>
                      <p className="text-[11px] text-on-surface-variant font-medium">{client.type}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`text-[10px] font-bold ${client.risk_color}`}>{client.risk_text} Risk</span>
                    <p className="text-[10px] text-on-surface-variant mt-1 font-semibold">{client.last_contact}</p>
                  </div>
                </div>
              ))}

              {filteredClients.length === 0 && (
                <div className="text-center p-6 text-on-surface-variant font-body-sm">
                  No clients match search query.
                </div>
              )}
            </div>
          </div>

          {/* Details Panel (Right) */}
          {activeClient && (
            <div className="lg:col-span-8 space-y-8 animate-in fade-in zoom-in-95 duration-150">
              {/* Profile Card */}
              <div className="bg-white rounded-[24px] border border-outline-variant/30 card-shadow p-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
                <div className="flex items-center gap-6">
                  <div className="w-16 h-16 rounded-2xl bg-primary text-white flex items-center justify-center font-headline-md text-headline-md font-bold">
                    {activeClient.initials}
                  </div>
                  <div>
                    <h3 className="font-headline-md text-headline-md text-on-surface font-bold">{activeClient.name}</h3>
                    <p className="text-body-md text-on-surface-variant font-medium">{activeClient.type} • Partner since {activeClient.joined}</p>
                    <div className="flex flex-wrap gap-4 mt-3 text-xs text-on-surface-variant font-bold">
                      <span className="flex items-center gap-1"><span className="material-symbols-outlined text-sm">mail</span> {activeClient.email}</span>
                      <span className="flex items-center gap-1"><span className="material-symbols-outlined text-sm">phone</span> {activeClient.phone}</span>
                      <span className="flex items-center gap-1"><span className="material-symbols-outlined text-sm">location_on</span> {activeClient.address}</span>
                    </div>
                  </div>
                </div>
                
                {/* Loyalty Score widget */}
                <div className="flex flex-col items-center bg-surface-container-low p-4 rounded-2xl border border-outline-variant/10 min-w-[120px]">
                  <span className="text-[10px] text-on-surface-variant font-extrabold uppercase tracking-wider mb-1">Fidelity Score</span>
                  <span className={`text-headline-lg font-extrabold ${activeClient.score >= 80 ? 'text-green-500' : activeClient.score >= 50 ? 'text-primary' : 'text-error'}`}>
                    {activeClient.score}%
                  </span>
                  <div className="w-16 bg-outline-variant/30 h-1 rounded-full mt-2 overflow-hidden">
                    <div className={`h-full ${activeClient.score >= 80 ? 'bg-green-500' : activeClient.score >= 50 ? 'bg-primary' : 'bg-error'}`} style={{ width: `${activeClient.score}%` }}></div>
                  </div>
                </div>
              </div>

              {/* Policies & History grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Active Policies */}
                <div className="bg-white rounded-[24px] border border-outline-variant/30 card-shadow p-6 flex flex-col">
                  <h4 className="font-label-md font-bold text-on-surface mb-4">Active Policies</h4>
                  <div className="space-y-4 flex-1">
                    {activeClient.policies.map((p, idx) => (
                      <div key={idx} className="p-4 bg-surface-container-low rounded-xl border border-outline-variant/10 flex justify-between items-center">
                        <div>
                          <p className="font-label-md font-bold text-on-surface">{p.name}</p>
                          <p className="text-[11px] text-on-surface-variant font-mono mt-0.5">{p.number}</p>
                        </div>
                        <div className="text-right">
                          <span className="px-2 py-0.5 bg-green-100 text-green-700 text-[10px] font-bold rounded-full">{p.status}</span>
                          <p className="text-[12px] font-bold text-on-surface mt-1">{p.premium}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Claim Timeline */}
                <div className="bg-white rounded-[24px] border border-outline-variant/30 card-shadow p-6 flex flex-col">
                  <h4 className="font-label-md font-bold text-on-surface mb-4">Claims History</h4>
                  <div className="space-y-4 flex-1">
                    {activeClient.claims_history.map((c, idx) => (
                      <div key={idx} className="flex gap-4 items-start border-b border-outline-variant/10 pb-3 last:border-0 last:pb-0">
                        <div className="p-2 bg-primary/10 text-primary rounded-lg flex items-center justify-center">
                          <span className="material-symbols-outlined text-sm">description</span>
                        </div>
                        <div className="flex-1">
                          <div className="flex justify-between items-center">
                            <span className="font-label-sm font-bold text-on-surface">{c.id}</span>
                            <span className="text-[10px] text-on-surface-variant font-semibold">{c.date}</span>
                          </div>
                          <p className="text-xs text-on-surface-variant font-semibold mt-0.5">{c.type} • {c.amount}</p>
                          <span className={`inline-block mt-1 text-[9px] px-2 py-0.5 rounded font-extrabold uppercase ${
                            c.status === 'Pending' ? 'bg-primary-container text-on-primary-container' : 'bg-green-100 text-green-700'
                          }`}>
                            {c.status}
                          </span>
                        </div>
                      </div>
                    ))}
                    {activeClient.claims_history.length === 0 && (
                      <div className="text-center p-8 text-on-surface-variant font-body-sm flex flex-col items-center justify-center flex-1">
                        No claims history records.
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Agent Notes / Timeline */}
              <div className="bg-white rounded-[24px] border border-outline-variant/30 card-shadow p-8 space-y-6">
                <h4 className="font-label-md font-bold text-on-surface">Activity Log & Agent Notes</h4>
                
                {/* Note create form */}
                <form onSubmit={handleAddNote} className="flex gap-3">
                  <input
                    type="text"
                    placeholder="Add a private agent note..."
                    value={newNoteText}
                    onChange={(e) => setNewNoteText(e.target.value)}
                    className="flex-1 bg-surface-container-low border border-outline-variant/30 rounded-xl py-3 px-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                  />
                  <button
                    type="submit"
                    className="bg-primary text-white px-6 rounded-xl font-label-md font-bold hover:brightness-110 active:scale-98 transition-all flex items-center justify-center gap-1 shadow-sm flex-shrink-0"
                  >
                    <span className="material-symbols-outlined text-md">add</span> Add Note
                  </button>
                </form>

                {/* Timeline */}
                <div className="relative border-l border-outline-variant/20 ml-4 pl-6 space-y-6 pt-2">
                  {activeClient.notes.map((note) => (
                    <div key={note.id} className="relative">
                      {/* Timeline dot */}
                      <span className="absolute -left-[31px] top-1 w-2.5 h-2.5 rounded-full bg-primary border-2 border-white ring-4 ring-primary/10"></span>
                      
                      <div className="flex justify-between items-center mb-1">
                        <span className="font-label-sm font-bold text-on-surface">{note.author}</span>
                        <span className="text-[11px] text-on-surface-variant font-semibold">{note.date}</span>
                      </div>
                      <p className="text-body-sm text-on-surface-variant leading-relaxed font-semibold">{note.text}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </main>
  );
};

export default ClientsPage;
