import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext.jsx';
import LoginPage from './pages/Login.jsx';
import SignupPage from './pages/Signup.jsx';
import DashboardPage from './pages/Dashboard';
import ClaimsPage from './pages/Claims';
import AIEstimationPage from './pages/AIEstimation';
import ClientsPage from './pages/Clients';
import AnalyticsPage from './pages/Analytics';

// Sidebar component with logout
const Sidebar = () => {
  const location = useLocation();
  const { user, logout } = useAuth();
  const isActive = (path) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <aside className="hidden md:flex flex-col h-screen w-64 border-r border-outline-variant/30 sticky top-0 left-0 bg-white/85 backdrop-blur-xl z-50 flex-shrink-0">
      <div className="px-6 py-8">
        <div className="flex items-center gap-2 mb-1">
          <img
            alt="AssureX Logo"
            className="w-8 h-8 object-contain"
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuCiUp7ImcYEpJt6Mh-jM9PH3kCafzUjEVRHYxenWYUeQEQFAu5FElmBGTi2jzXA-wNJYxjXd6sPpLZ5oxs0-JELVJyHynTb1nkfXI4wZlD32l1XNyHRpjo2PJHIs5YntqPXcef0WLhJ9NZcrcYIuoJR-fPrvlj7Pqne6Wvji2FWMWThN9dH0H8w4Pu_i1AdBJhItosUytnNQBQR8nOSZs5sm65ocSfKiL4uHYtaUHq1e_btMf6ADU4o-w-xJGHVRwgxOdmg0aIkQLKp"
          />
          <h1 className="font-headline-lg text-headline-lg font-bold text-primary">AssureX</h1>
        </div>
        <p className="font-label-md text-label-md text-on-surface-variant">Agency Portal</p>
      </div>
      <nav className="flex-1 px-4 space-y-1">
        <Link
          to="/"
          className={`flex items-center gap-3 px-4 py-3 rounded-lg group transition-all ${
            isActive('/')
              ? 'text-primary bg-primary-fixed/30 font-bold'
              : 'text-on-surface-variant hover:bg-surface-container-low'
          }`}
        >
          <span className="material-symbols-outlined">dashboard</span>
          <span className="font-label-md">Dashboard</span>
        </Link>
        <Link
          to="/claims"
          className={`flex items-center gap-3 px-4 py-3 rounded-lg group transition-all ${
            isActive('/claims')
              ? 'text-primary bg-primary-fixed/30 font-bold'
              : 'text-on-surface-variant hover:bg-surface-container-low'
          }`}
        >
          <span className="material-symbols-outlined">view_kanban</span>
          <span className="font-label-md">Claims</span>
        </Link>
        <Link
          to="/ai-estimation"
          className={`flex items-center gap-3 px-4 py-3 rounded-lg group transition-all ${
            isActive('/ai-estimation')
              ? 'text-primary bg-primary-fixed/30 font-bold'
              : 'text-on-surface-variant hover:bg-surface-container-low'
          }`}
        >
          <span className="material-symbols-outlined">auto_awesome</span>
          <span className="font-label-md">AI Estimation</span>
        </Link>
        <Link
          to="/clients"
          className={`flex items-center gap-3 px-4 py-3 rounded-lg group transition-all ${
            isActive('/clients')
              ? 'text-primary bg-primary-fixed/30 font-bold'
              : 'text-on-surface-variant hover:bg-surface-container-low'
          }`}
        >
          <span className="material-symbols-outlined">group</span>
          <span className="font-label-md">Clients</span>
        </Link>
        <Link
          to="/analytics"
          className={`flex items-center gap-3 px-4 py-3 rounded-lg group transition-all ${
            isActive('/analytics')
              ? 'text-primary bg-primary-fixed/30 font-bold'
              : 'text-on-surface-variant hover:bg-surface-container-low'
          }`}
        >
          <span className="material-symbols-outlined">query_stats</span>
          <span className="font-label-md">Analyse</span>
        </Link>
      </nav>
      <div className="px-4 py-6 border-t border-outline-variant/20">
        {user && (
          <div className="mb-4 px-4 py-3 bg-surface-container-low rounded-xl">
            <p className="text-sm font-medium text-on-surface">{user.full_name || user.username}</p>
            <p className="text-xs text-on-surface-variant">{user.email}</p>
          </div>
        )}
        <button
          onClick={logout}
          className="w-full flex items-center gap-3 px-4 py-3 text-on-surface-variant hover:text-error hover:bg-error-container/20 rounded-lg transition-colors"
        >
          <span className="material-symbols-outlined text-[20px]">logout</span>
          <span className="font-label-md">Logout</span>
        </button>
      </div>
    </aside>
  );
};

const Header = () => {
  const { user } = useAuth();
  
  return (
    <header className="sticky top-0 z-40 flex justify-between items-center px-8 h-16 w-full bg-white/80 backdrop-blur-md border-b border-outline-variant/20 shadow-sm flex-shrink-0">
      <div className="flex items-center gap-4 flex-1">
        <div className="relative w-full max-w-md">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant">search</span>
          <input
            className="w-full bg-surface-container-low border-none rounded-full py-2 pl-10 pr-4 text-body-md focus:ring-2 focus:ring-primary/20 transition-all outline-none"
            placeholder="Search claims or clients..."
            type="text"
          />
        </div>
      </div>
      <div className="flex items-center gap-2">
        <button className="hover:bg-surface-container-low rounded-full p-2 transition-all relative">
          <span className="material-symbols-outlined text-on-surface-variant">notifications</span>
          <span className="absolute top-2 right-2 w-2 h-2 bg-error rounded-full border-2 border-white"></span>
        </button>
        <button className="hover:bg-surface-container-low rounded-full p-2 transition-all">
          <span className="material-symbols-outlined text-on-surface-variant">history</span>
        </button>
        <button className="hover:bg-surface-container-low rounded-full p-2 transition-all">
          <span className="material-symbols-outlined text-on-surface-variant">help</span>
        </button>
        <div className="ml-4 h-8 w-8 rounded-full bg-surface-variant overflow-hidden border border-outline-variant/30 flex items-center justify-center">
          <span className="text-sm font-bold text-on-surface">
            {user?.full_name ? user.full_name.charAt(0).toUpperCase() : user?.username?.charAt(0).toUpperCase() || 'U'}
          </span>
        </div>
      </div>
    </header>
  );
};

const AppContent = () => {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return (
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/signup" element={<SignupPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-background text-on-surface">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Header />
        <div className="flex-1 overflow-y-auto">
          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/claims" element={<ClaimsPage />} />
            <Route path="/ai-estimation" element={<AIEstimationPage />} />
            <Route path="/ai-estimation/:claimId" element={<AIEstimationPage />} />
            <Route path="/clients" element={<ClientsPage />} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/login" element={<Navigate to="/" replace />} />
            <Route path="/signup" element={<Navigate to="/" replace />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </div>
      </div>
    </div>
  );
};

const App = () => {
  return (
    <Router>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </Router>
  );
};

export default App;