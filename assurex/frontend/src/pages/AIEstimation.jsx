import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';

const API_BASE = 'http://localhost:8000/api';

const AIEstimationPage = () => {
  const { claimId } = useParams();
  const navigate = useNavigate();
  const currentClaimId = claimId || 'CLM-8291'; // Fallback to default
  
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedHotspot, setSelectedHotspot] = useState(null);

  useEffect(() => {
    const fetchEstimation = async () => {
      try {
        setLoading(true);
        const res = await axios.get(`${API_BASE}/claims/${currentClaimId}`);
        setData(res.data);
        if (res.data.hotspots && res.data.hotspots.length > 0) {
          setSelectedHotspot(res.data.hotspots[0].id); // default selection
        } else {
          setSelectedHotspot(null);
        }
        setLoading(false);
      } catch (err) {
        console.error('Error fetching AI estimation:', err);
        setError('Estimation data not available for this claim.');
        setLoading(false);
      }
    };

    fetchEstimation();
  }, [currentClaimId]);

  const handleValidate = async () => {
    try {
      // Validate the estimate moves it to "review" status on the backend
      await axios.post(`${API_BASE}/claims/${currentClaimId}/move`, {
        status: 'review',
      });
      alert('Estimation validated successfully! Moved to Under Review.');
      navigate('/claims');
    } catch (err) {
      console.error('Error validating estimate:', err);
      alert('Validation failed.');
    }
  };

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[60vh]">
        <div className="h-12 w-12 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <main className="p-10 max-w-[1440px] mx-auto w-full flex flex-col items-center justify-center min-h-[60vh] gap-4">
        <span className="material-symbols-outlined text-[64px] text-on-surface-variant">report_problem</span>
        <h2 className="font-headline-md text-headline-md text-on-surface">Data Unresolved</h2>
        <p className="font-body-md text-on-surface-variant text-center max-w-sm">
          {error || 'No estimation records found for this case. Try selecting another claim.'}
        </p>
        <button 
          onClick={() => navigate('/claims')}
          className="bg-primary text-white px-6 py-2.5 rounded-xl font-label-md shadow-sm hover:brightness-110 transition-all"
        >
          Return to Claims Pipeline
        </button>
      </main>
    );
  }

  return (
    <main className="flex-1 flex flex-col min-h-[85vh] relative pb-28">
      {/* Page Header banner */}
      <div className="px-10 py-6 bg-white border-b border-outline-variant/15 flex-shrink-0">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h2 className="font-headline-md text-headline-md text-on-surface font-bold">AI Damage Estimation</h2>
            <nav className="flex items-center gap-2 text-label-md text-on-surface-variant mt-1 font-semibold">
              <span className="hover:underline cursor-pointer" onClick={() => navigate('/claims')}>Claims</span>
              <span>•</span>
              <span className="text-primary font-bold">#{data.claim_id}</span>
              <span>•</span>
              <span>{data.vehicle}</span>
            </nav>
          </div>
          <div className="bg-primary/10 text-primary px-5 py-2.5 rounded-full flex items-center gap-2 max-w-max">
            <span className="material-symbols-outlined text-[20px] font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
            <span className="font-label-md font-bold">{data.status}</span>
          </div>
        </div>
      </div>
      
      {/* Main content split panel */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-8 p-10 overflow-y-auto max-w-[1440px] mx-auto w-full">
        {/* Left column: image & hotspots */}
        <div className="lg:col-span-8 flex flex-col gap-6">
          <div className="relative bg-white border border-outline-variant/30 rounded-3xl overflow-hidden shadow-sm aspect-[16/10] max-h-[500px]">
            {/* Hotspots container */}
            <div className="absolute inset-0 z-10 pointer-events-none">
              <div className="absolute top-0 left-0 w-full h-1 bg-primary/40 shimmer"></div>
              {data.hotspots.map((hs) => (
                <button
                  key={hs.id}
                  style={{ top: hs.top, left: hs.left }}
                  onClick={() => setSelectedHotspot(hs.id)}
                  className={`absolute w-8 h-8 -translate-x-1/2 -translate-y-1/2 hotspot-glow border-2 border-white rounded-full pointer-events-auto flex items-center justify-center font-bold text-xs shadow-md transition-all active:scale-95 ${
                    selectedHotspot === hs.id
                      ? 'bg-primary text-white scale-110 z-20 ring-4 ring-primary/20'
                      : 'bg-primary/50 text-white hover:bg-primary z-10'
                  }`}
                  title={hs.title}
                >
                  <span className="material-symbols-outlined text-[14px]">auto_awesome</span>
                </button>
              ))}
            </div>
            
            {/* Core damage image */}
            <img 
              className="w-full h-full object-cover select-none" 
              src={data.image_url} 
              alt="Vehicle damage analysis" 
            />

            {/* Image control tray */}
            <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex items-center gap-2 bg-black/60 backdrop-blur-md px-4 py-2 rounded-full text-white z-20 shadow-md">
              <button className="p-2 hover:bg-white/20 rounded-full transition-colors flex items-center"><span className="material-symbols-outlined">zoom_in</span></button>
              <button className="p-2 hover:bg-white/20 rounded-full transition-colors flex items-center"><span className="material-symbols-outlined">rotate_right</span></button>
              <button className="p-2 hover:bg-white/20 rounded-full transition-colors flex items-center"><span className="material-symbols-outlined">layers</span></button>
            </div>
          </div>
          
          {/* Thumbnails list */}
          {data.thumbnails && data.thumbnails.length > 0 && (
            <div className="flex gap-4 h-24 overflow-x-auto pb-2 scrollbar-hide flex-shrink-0">
              <div className="min-w-[96px] h-full rounded-xl border-2 border-primary overflow-hidden cursor-pointer shadow-sm">
                <img className="w-full h-full object-cover" src={data.image_url} alt="Main thumb" />
              </div>
              {data.thumbnails.map((thumb, idx) => (
                <div key={idx} className="min-w-[96px] h-full rounded-xl border border-outline-variant/30 overflow-hidden opacity-60 hover:opacity-100 transition-all cursor-pointer shadow-sm">
                  <img className="w-full h-full object-cover" src={thumb} alt={`Thumb ${idx}`} />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Right column: detection card list */}
        <div className="lg:col-span-4 flex flex-col gap-6">
          <div className="bg-white border border-outline-variant/30 rounded-3xl p-6 shadow-sm flex flex-col flex-1">
            <h3 className="font-headline-md text-headline-md mb-6 font-bold">Detection Report</h3>
            
            <div className="space-y-4 flex-1 overflow-y-auto max-h-[350px] pr-1">
              {data.hotspots.map((hs) => (
                <div
                  key={hs.id}
                  onClick={() => setSelectedHotspot(hs.id)}
                  className={`p-4 rounded-2xl border transition-all cursor-pointer ${
                    selectedHotspot === hs.id
                      ? 'bg-primary-container/20 border-primary ring-1 ring-primary'
                      : 'bg-surface-container-low border-outline-variant/15 hover:border-primary/30'
                  }`}
                >
                  <div className="flex justify-between items-start mb-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                        <span className="material-symbols-outlined text-[20px]">
                          {hs.title.toLowerCase().includes('bumper') ? 'car_repair' : 'light_mode'}
                        </span>
                      </div>
                      <div>
                        <p className="font-label-md font-bold text-on-surface">{hs.title}</p>
                        <p className="text-[12px] text-on-surface-variant font-medium">{hs.severity} Gravity</p>
                      </div>
                    </div>
                    <p className="font-headline-md text-on-surface font-extrabold">${hs.cost.toFixed(2)}</p>
                  </div>
                  <p className="text-body-sm text-on-surface-variant line-clamp-2 mt-2">{hs.description}</p>
                  <div className="w-full bg-outline-variant/20 h-1.5 rounded-full mt-3 overflow-hidden">
                    <div className="bg-primary h-full transition-all duration-500" style={{ width: `${hs.confidence}%` }}></div>
                  </div>
                  <div className="flex justify-between items-center mt-2 text-[10px] text-on-surface-variant font-bold">
                    <span>Confidence</span>
                    <span>{hs.confidence}%</span>
                  </div>
                </div>
              ))}

              {data.hotspots.length === 0 && (
                <div className="text-center p-8 border-2 border-dashed border-outline-variant/20 rounded-2xl text-on-surface-variant">
                  No automatic damage detections found. Add items manually or upload photos.
                </div>
              )}
            </div>

            {/* Cost Summary block */}
            <div className="mt-8 pt-6 border-t border-outline-variant/20 flex-shrink-0">
              <div className="flex justify-between items-center mb-2">
                <span className="font-label-md text-on-surface-variant font-medium">Subtotal Estimate</span>
                <span className="font-label-md text-on-surface font-bold">${data.subtotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between items-center py-4 border-t border-outline-variant/20">
                <span className="font-headline-md text-headline-md font-extrabold">Total Estimate</span>
                <span className="font-headline-md text-headline-md text-primary font-extrabold">${data.total.toFixed(2)}</span>
              </div>
            </div>
          </div>
          
          {/* AI Insights panel */}
          <div className="bg-primary-container p-6 rounded-3xl shadow-sm text-on-primary-container flex-shrink-0">
            <div className="flex items-center gap-3 mb-2 font-bold">
              <span className="material-symbols-outlined">psychology</span>
              <h4 className="font-label-md">AI Insights</h4>
            </div>
            <p className="text-body-sm opacity-90 font-medium leading-relaxed">{data.insights}</p>
          </div>
        </div>
      </div>
      
      {/* Floating Action Footer */}
      <footer className="fixed bottom-0 right-0 left-0 md:left-64 bg-white/90 backdrop-blur-xl border-t border-outline-variant/20 px-10 py-5 z-30 shadow-lg">
        <div className="max-w-[1440px] mx-auto flex items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <button className="bg-surface-container-high text-on-surface px-6 py-3 rounded-xl font-label-md font-bold flex items-center gap-2 hover:bg-surface-container-highest transition-colors active:scale-98">
              <span className="material-symbols-outlined text-[20px]">add_a_photo</span>
              Request More Photos
            </button>
          </div>
          <div className="flex items-center gap-4">
            <button 
              onClick={handleValidate}
              className="bg-primary text-on-primary px-10 py-3 rounded-xl font-headline-md font-bold flex items-center gap-2 shadow-lg shadow-primary/20 hover:bg-primary/95 transition-all active:scale-98"
            >
              <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>check_circle</span>
              Validate Estimate
            </button>
          </div>
        </div>
      </footer>
    </main>
  );
};

export default AIEstimationPage;
