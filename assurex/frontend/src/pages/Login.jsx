import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const LoginPage = () => {
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const result = await login(formData.email, formData.password);
    
    if (result.success) {
      navigate('/');
    } else {
      setError(result.error);
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-2 mb-2">
            <img
              alt="AssureX Logo"
              className="w-10 h-10 object-contain"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuCiUp7ImcYEpJt6Mh-jM9PH3kCafzUjEVRHYxenWYUeQEQFAu5FElmBGTi2jzXA-wNJYxjXd6sPpLZ5oxs0-JELVJyHynTb1nkfXI4wZlD32l1XNyHRpjo2PJHIs5YntqPXcef0WLhJ9NZcrcYIuoJR-fPrvlj7Pqne6Wvji2FWMWThN9dH0H8w4Pu_i1AdBJhItosUytnNQBQR8nOSZs5sm65ocSfKiL4uHYtaUHq1e_btMf6ADU4o-w-xJGHVRwgxOdmg0aIkQLKp"
            />
            <h1 className="font-headline-lg text-headline-lg font-bold text-primary">AssureX</h1>
          </div>
          <p className="text-on-surface-variant">Sign in to your account</p>
        </div>

        {/* Login Form */}
        <div className="bg-white p-8 rounded-[28px] card-shadow border border-outline-variant/30">
          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <div className="bg-error-container text-on-error-container p-4 rounded-xl text-sm font-medium">
                {error}
              </div>
            )}

            <div className="space-y-2">
              <label className="block text-label-md font-bold text-on-surface-variant">
                Email Address
              </label>
              <input
                type="email"
                name="email"
                required
                value={formData.email}
                onChange={handleChange}
                placeholder="alex@assurex.com"
                className="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl py-3 px-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
              />
            </div>

            <div className="space-y-2">
              <label className="block text-label-md font-bold text-on-surface-variant">
                Password
              </label>
              <input
                type="password"
                name="password"
                required
                value={formData.password}
                onChange={handleChange}
                placeholder="Enter your password"
                className="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl py-3 px-4 text-body-md focus:ring-2 focus:ring-primary/20 outline-none transition-all"
              />
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 text-body-sm text-on-surface-variant">
                <input type="checkbox" className="rounded border-outline-variant/30" />
                Remember me
              </label>
              <a href="#" className="text-body-sm text-primary font-medium hover:underline">
                Forgot password?
              </a>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-primary text-white py-3 rounded-xl font-label-md shadow-sm hover:brightness-110 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <div className="h-5 w-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Signing in...
                </>
              ) : (
                'Sign In'
              )}
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-on-surface-variant text-body-sm">
              Don't have an account?{' '}
              <Link to="/signup" className="text-primary font-medium hover:underline">
                Sign up
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;