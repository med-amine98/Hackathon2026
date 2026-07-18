import React, { useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import axios from 'axios';

// Backend runs via the root docker-compose (assurex-api service, host port
// 8002) — override with VITE_API_BASE in .env for a different setup.
const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8002/api';

const ClaimsPage = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();
  const [claims, setClaims] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedClaim, setSelectedClaim] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);

  // Form State
  const [showModal, setShowModal] = useState(searchParams.get('new') === 'true');
  const [newClaim, setNewClaim] = useState({
    vehicle: '',
    vehicle_type: '',
    gravity: 'Moderate',
    risk: 50,
  });

  const fetchClaims = async () => {
    try {
      setLoading(true);
      const res = await axios.get(`${API_BASE}/claims`);
      setClaims(res.data);
      setLoading(false);
    } catch (err) {
      console.error('Error fetching claims:', err);
      setError('Could not fetch claims from server.');
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchClaims();
  }, []);

  // Monitor URL search param for showing/hiding new claim modal
  useEffect(() => {
    if (searchParams.get('new') === 'true') {
      setShowModal(true);
    } else {
      setShowModal(false);
    }
  }, [searchParams]);

  const handleCloseModal = () => {
    setShowModal(false);
    // Remove "new" parameter from URL
    const params = new URLSearchParams(searchParams);
    params.delete('new');
    setSearchParams(params);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewClaim((prev) => ({
      ...prev,
      [name]: name === 'risk' ? parseInt(value, 10) : value,
    }));
  };

  const handleCreateClaim = async (e) => {
    e.preventDefault();
    try {
      await axios.post(`${API_BASE}/claims`, {
        ...newClaim,
        agent_initials: 'AX',
        time_left: '3h left',
      });
      handleCloseModal();
      setNewClaim({
        vehicle: '',
        vehicle_type: '',
        gravity: 'Moderate',
        risk: 50,
      });
      fetchClaims();
    } catch (err) {
      console.error('Error creating claim:', err);
      alert('Failed to create new claim.');
    }
  };

  const handleMoveStatus = async (claimId, newStatus) => {
    try {
      await axios.post(`${API_BASE}/claims/${claimId}/move`, {
        status: newStatus,
      });
      fetchClaims();
    } catch (err) {
      console.error('Error updating status:', err);
    }
  };

  const handleClaimClick = (claim) => {
    setSelectedClaim(claim);
    setShowDetailsModal(true);
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'new': return 'bg-blue-100 text-blue-800 border-blue-300';
      case 'estimation': return 'bg-purple-100 text-purple-800 border-purple-300';
      case 'review': return 'bg-orange-100 text-orange-800 border-orange-300';
      case 'completed': return 'bg-green-100 text-green-800 border-green-300';
      default: return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const getStatusLabel = (status) => {
    switch(status) {
      case 'new': return 'New';
      case 'estimation': return 'Damage Estimation';
      case 'review': return 'Under AI Review';
      case 'completed': return 'Completed';
      default: return status;
    }
  };

  const getGravityColor = (gravity) => {
    switch(gravity) {
      case 'Critical':
      case 'High': return 'bg-red-100 text-red-800 border-red-300';
      case 'Moderate': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'Minor':
      case 'Low': return 'bg-green-100 text-green-800 border-green-300';
      default: return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  if (loading && claims.length === 0) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[60vh]">
        <div className="h-12 w-12 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <section className="p-8 flex-1 flex flex-col gap-8 h-full min-h-[85vh]">
      <div className="flex flex-wrap items-end justify-between gap-4 flex-shrink-0">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-surface">Gestion des sinistres</h2>
          <p className="text-on-surface-variant font-body-md">Manage and process active claims across the pipeline.</p>
        </div>
      </div>

      {/* Claims List */}
      <div className="flex-1 overflow-y-auto">
        <div className="bg-white rounded-2xl border border-outline-variant/20 overflow-hidden shadow-sm">
          {/* Table Header */}
          <div className="grid grid-cols-12 gap-4 px-6 py-4 bg-surface-container-low border-b border-outline-variant/20 text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
            <div className="col-span-3">Claim</div>
            <div className="col-span-2">Vehicle</div>
            <div className="col-span-2">Status</div>
            <div className="col-span-2">Gravity</div>
            <div className="col-span-1">Risk</div>
            <div className="col-span-1">Agent</div>
            <div className="col-span-1">Time Left</div>
          </div>

          {/* Table Body */}
          <div className="divide-y divide-outline-variant/10">
            {claims.map((claim) => (
              <div
                key={claim.id}
                className="grid grid-cols-12 gap-4 px-6 py-4 items-center hover:bg-surface-container-low/50 transition-colors cursor-pointer group"
                onClick={() => handleClaimClick(claim)}
              >
                <div className="col-span-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-sm">
                      {claim.id}
                    </div>
                    <div>
                      <div className="font-label-md font-semibold text-on-surface line-clamp-1">
                        {claim.vehicle}
                      </div>
                      <div className="text-on-surface-variant text-xs font-mono">
                        #{claim.id}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="col-span-2">
                  <span className="text-on-surface font-body-sm flex items-center gap-1.5">
                    <span className="material-symbols-outlined text-sm text-on-surface-variant">directions_car</span>
                    {claim.vehicle_type}
                  </span>
                </div>

                <div className="col-span-2">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold border ${getStatusColor(claim.status)}`}>
                    {getStatusLabel(claim.status)}
                  </span>
                </div>

                <div className="col-span-2">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold border ${getGravityColor(claim.gravity)}`}>
                    {claim.gravity}
                  </span>
                </div>

                <div className="col-span-1">
                  <div className="flex items-center gap-2">
                    <div className="flex-1 max-w-12 h-1.5 bg-outline-variant/30 rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full ${
                          claim.risk > 70 ? 'bg-red-500' : 
                          claim.risk > 40 ? 'bg-yellow-500' : 
                          'bg-green-500'
                        }`}
                        style={{ width: `${claim.risk}%` }}
                      />
                    </div>
                    <span className="text-xs font-bold text-on-surface-variant">{claim.risk}%</span>
                  </div>
                </div>

                <div className="col-span-1">
                  <div className="w-8 h-8 rounded-full border-2 border-white bg-blue-100 flex items-center justify-center text-xs font-bold">
                    {claim.agent_initials}
                  </div>
                </div>

                <div className="col-span-1">
                  <div className="flex items-center gap-1.5 text-on-surface-variant text-xs font-medium">
                    <span className="material-symbols-outlined text-sm">alarm</span>
                    <span>{claim.time_left}</span>
                  </div>
                </div>

                {/* Quick action buttons */}
                <div className="absolute right-4 hidden group-hover:flex gap-1 bg-white shadow-lg rounded-lg p-1 border border-outline-variant/20">
                  {claim.status !== 'new' && (
                    <button
                      title="Move Back"
                      onClick={(e) => {
                        e.stopPropagation();
                        const prevStatus = claim.status === 'estimation' ? 'new' : 
                                         claim.status === 'review' ? 'estimation' : 
                                         claim.status === 'completed' ? 'review' : 'new';
                        handleMoveStatus(claim.id, prevStatus);
                      }}
                      className="p-1.5 hover:bg-surface-container rounded-lg transition-colors"
                    >
                      <span className="material-symbols-outlined text-sm">arrow_back</span>
                    </button>
                  )}
                  {claim.status !== 'completed' && (
                    <button
                      title="Move Forward"
                      onClick={(e) => {
                        e.stopPropagation();
                        const nextStatus = claim.status === 'new' ? 'estimation' : 
                                         claim.status === 'estimation' ? 'review' : 
                                         claim.status === 'review' ? 'completed' : 'completed';
                        handleMoveStatus(claim.id, nextStatus);
                      }}
                      className="p-1.5 hover:bg-surface-container rounded-lg transition-colors"
                    >
                      <span className="material-symbols-outlined text-sm">arrow_forward</span>
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>

          {claims.length === 0 && (
            <div className="p-12 text-center text-on-surface-variant">
              <span className="material-symbols-outlined text-4xl mb-3 block opacity-50">inbox</span>
              <p className="font-body-lg">No claims found</p>
              <p className="text-sm">Start by creating a new claim</p>
            </div>
          )}
        </div>
      </div>

      {/* Claim Details Modal */}
      {showDetailsModal && selectedClaim && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white w-full max-w-2xl rounded-[28px] card-shadow border border-outline-variant/30 overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-200">
            <div className="p-8 border-b border-outline-variant/20 flex justify-between items-center bg-surface-container-low">
              <div>
                <h3 className="font-headline-md text-headline-md text-on-surface">Claim Details</h3>
                <p className="text-body-sm text-on-surface-variant mt-1">#{selectedClaim.id} - {selectedClaim.vehicle}</p>
              </div>
              <button 
                onClick={() => setShowDetailsModal(false)}
                className="hover:bg-surface-container p-2 rounded-full transition-colors flex items-center justify-center"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            
            <div className="p-8 space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label className="block text-label-sm font-bold text-on-surface-variant mb-1">Vehicle</label>
                  <p className="text-body-lg text-on-surface">{selectedClaim.vehicle}</p>
                </div>
                <div>
                  <label className="block text-label-sm font-bold text-on-surface-variant mb-1">Vehicle Type</label>
                  <p className="text-body-lg text-on-surface">{selectedClaim.vehicle_type}</p>
                </div>
                <div>
                  <label className="block text-label-sm font-bold text-on-surface-variant mb-1">Status</label>
                  <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold border ${getStatusColor(selectedClaim.status)}`}>
                    {getStatusLabel(selectedClaim.status)}
                  </span>
                </div>
                <div>
                  <label className="block text-label-sm font-bold text-on-surface-variant mb-1">Gravity</label>
                  <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold border ${getGravityColor(selectedClaim.gravity)}`}>
                    {selectedClaim.gravity}
                  </span>
                </div>
                <div>
                  <label className="block text-label-sm font-bold text-on-surface-variant mb-1">Risk Factor</label>
                  <div className="flex items-center gap-3">
                    <div className="flex-1 max-w-32 h-2 bg-outline-variant/30 rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full ${
                          selectedClaim.risk > 70 ? 'bg-red-500' : 
                          selectedClaim.risk > 40 ? 'bg-yellow-500' : 
                          'bg-green-500'
                        }`}
                        style={{ width: `${selectedClaim.risk}%` }}
                      />
                    </div>
                    <span className="text-body-lg font-bold text-on-surface">{selectedClaim.risk}%</span>
                  </div>
                </div>
                <div>
                  <label className="block text-label-sm font-bold text-on-surface-variant mb-1">Agent</label>
                  <p className="text-body-lg text-on-surface">{selectedClaim.agent_initials}</p>
                </div>
              </div>

              {selectedClaim.ai_estimate && (
                <div className="bg-primary/5 p-4 rounded-xl border border-primary/20">
                  <label className="block text-label-sm font-bold text-primary mb-1">AI Estimate</label>
                  <p className="text-headline-sm text-primary">€{selectedClaim.ai_estimate.toLocaleString()}</p>
                  <div className="mt-2 flex items-center gap-3">
                    <div className="flex-1 h-1.5 bg-outline-variant/30 rounded-full overflow-hidden">
                      <div className="bg-primary h-full" style={{ width: `${selectedClaim.ai_progress}%` }}></div>
                    </div>
                    <span className="text-xs font-bold text-primary">{selectedClaim.ai_progress}%</span>
                  </div>
                </div>
              )}

              <div className="flex justify-end gap-3 pt-4 border-t border-outline-variant/20">
                <button
                  onClick={() => {
                    navigate(`/ai-estimation/${selectedClaim.id}`);
                    setShowDetailsModal(false);
                  }}
                  className="bg-primary text-white px-6 py-2.5 rounded-xl font-label-md shadow-sm hover:brightness-110 transition-all"
                >
                  View Full Details
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* New Claim Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white w-full max-w-lg rounded-[28px] card-shadow border border-outline-variant/30 overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-200">
            <div className="p-8 border-b border-outline-variant/20 flex justify-between items-center bg-surface-container-low">
              <div>
                <h3 className="font-headline-md text-headline-md text-on-surface">New Claim Onboarding</h3>
                <p className="text-body-sm text-on-surface-variant mt-1">Register a vehicle case onto the pipeline</p>
              </div>
              <button 
                onClick={handleCloseModal}
                className="hover:bg-surface-container p-2 rounded-full transition-colors flex items-center justify-center"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            
            <form onSubmit={handleCreateClaim} className="p-8 space-y-6 flex-1">
              <div className="space-y-2">
                <label className="block text-label-md font-bold text-on-surface-variant">Vehicle Name & Damage Description</label>
                <input
                  type="text"
                  name="vehicle"
                  required
                  placeholder="e.g. Tesla Model 3 - Rear Collision"
                  value={newClaim.vehicle}
                  onChange={handleInputChange}
                  className="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl py-3 px-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                />
              </div>

              <div className="space-y-2">
                <label className="block text-label-md font-bold text-on-surface-variant">Vehicle Type / Segment</label>
                <input
                  type="text"
                  name="vehicle_type"
                  required
                  placeholder="e.g. Sedan, SUV, EV"
                  value={newClaim.vehicle_type}
                  onChange={handleInputChange}
                  className="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl py-3 px-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="block text-label-md font-bold text-on-surface-variant">Gravity Level</label>
                  <select
                    name="gravity"
                    value={newClaim.gravity}
                    onChange={handleInputChange}
                    className="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl py-3 px-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                  >
                    <option value="Critical">Critical</option>
                    <option value="High">High</option>
                    <option value="Moderate">Moderate</option>
                    <option value="Minor">Minor</option>
                    <option value="Low">Low</option>
                  </select>
                </div>
                
                <div className="space-y-2">
                  <label className="block text-label-md font-bold text-on-surface-variant">Risk Factor (0-100%)</label>
                  <input
                    type="number"
                    name="risk"
                    min="0"
                    max="100"
                    required
                    value={newClaim.risk}
                    onChange={handleInputChange}
                    className="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl py-3 px-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                  />
                </div>
              </div>

              <div className="pt-4 flex justify-end gap-3 border-t border-outline-variant/20">
                <button
                  type="button"
                  onClick={handleCloseModal}
                  className="bg-surface-container-high text-on-surface px-6 py-3 rounded-xl font-label-md hover:bg-surface-container-highest transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="bg-primary text-white px-8 py-3 rounded-xl font-label-md shadow-sm hover:brightness-110 transition-all"
                >
                  Create Dossier
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </section>
  );
};

export default ClaimsPage;