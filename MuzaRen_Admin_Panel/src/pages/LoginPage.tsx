import { useState } from 'react'
import type { FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { loginAdmin } from '../services/adminApi'
import { setAdminRole, setAdminToken } from '../services/authStorage'
import { Mail, Lock, Eye, EyeOff, AlertCircle, Loader2 } from 'lucide-react'

export function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setIsSubmitting(true)
    setError('')

    try {
      const login = await loginAdmin(email, password)
      if (!login.token) {
        throw new Error('No token returned from server')
      }
      setAdminToken(login.token)
      setAdminRole(login.role)
      navigate('/dashboard')
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Login failed'
      if (msg.includes('admin privileges')) {
        setError('Access denied — you do not have admin permissions.')
      } else if (msg.includes('Invalid email') || msg.includes('password')) {
        setError('Invalid email or password. Please try again.')
      } else if (msg.includes('blocked')) {
        setError('This account has been blocked. Contact support.')
      } else {
        setError('Login failed. Check your connection and try again.')
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <section className="auth-page">
      <div className="auth-card">
        <div className="auth-header">
          <div className="auth-brand">M</div>
          <h2>Welcome Back</h2>
          <p>Please enter your admin credentials</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <div className="auth-label">
            Email address
            <div className="input-icon-wrap">
              <Mail size={18} />
              <input
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                type="email"
                required
                placeholder="admin@renthubindia.com"
                autoComplete="email"
              />
            </div>
          </div>

          <div className="auth-label">
            Password
            <div className="input-icon-wrap">
              <Lock size={18} />
              <input
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                type={showPassword ? 'text' : 'password'}
                required
                placeholder="••••••••••••"
                autoComplete="current-password"
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                tabIndex={-1}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          {error && (
            <div className="auth-error">
              <AlertCircle size={16} />
              {error}
            </div>
          )}

          <button 
            className="btn btn-primary auth-submit-btn" 
            type="submit" 
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <>
                <Loader2 size={18} className="animate-spin mr-2" />
                Signing in...
              </>
            ) : (
              'Sign in to Dashboard'
            )}
          </button>
        </form>

        <div className="auth-footer">
          <p>© 2026 RentHubIndia Admin Panel</p>
        </div>
      </div>
    </section>
  )
}
