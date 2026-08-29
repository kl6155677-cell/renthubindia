import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { StatCard } from '../components/ui/StatCard'
import { fetchDashboardStats } from '../services/adminApi'
import type { DashboardStats } from '../types/admin'
import { Users, Tags, CalendarDays, Flag, ShieldCheck, Ticket, AlertTriangle } from 'lucide-react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

const initialStats: DashboardStats = {
  totalUsers: 0,
  totalListings: 0,
  totalBookings: 0,
  openReports: 0,
  pendingVerifications: 0,
  openSupportTickets: 0,
}


export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>(initialStats)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const load = async () => {
      try {
        const result = await fetchDashboardStats()
        setStats(result)
      } catch {
        setError('Failed to load dashboard data.')
      } finally {
        setIsLoading(false)
      }
    }
    load()
  }, [])

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      {error ? <p className="error-text">{error}</p> : null}
      
      {isLoading ? (
        <div className="loading-state">
          <div className="spinner" /> Loading dashboard...
        </div>
      ) : (
        <>
          <div className="stats-grid">
            <StatCard 
              label="Total users" 
              value={stats.totalUsers} 
              icon={<Users size={20} />} 
              color="blue" 
              trend={{ value: stats.userGrowth || 0, label: 'vs last month' }}
            />
            <StatCard 
              label="Total listings" 
              value={stats.totalListings} 
              icon={<Tags size={20} />} 
              color="green" 
              trend={{ value: stats.listingGrowth || 0, label: 'vs last month' }}
            />
            <StatCard 
              label="Total bookings" 
              value={stats.totalBookings} 
              icon={<CalendarDays size={20} />} 
              color="purple" 
              trend={{ value: stats.bookingGrowth || 0, label: 'vs last month' }}
            />
            <StatCard 
              label="Open reports" 
              value={stats.openReports} 
              icon={<Flag size={20} />} 
              color="red" 
            />
            <StatCard 
              label="Pending verifications" 
              value={stats.pendingVerifications} 
              icon={<ShieldCheck size={20} />} 
              color="amber" 
            />
            <StatCard 
              label="Support tickets" 
              value={stats.openSupportTickets} 
              icon={<Ticket size={20} />} 
              color="gray" 
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem', alignItems: 'start' }}>
            <section className="card" style={{ minHeight: '400px' }}>
              <h3>Recent Activity</h3>
              <div style={{ height: '320px', width: '100%', marginTop: '1rem' }}>
                <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={stats.recentActivity?.map(point => ({
                      name: new Date(point.date).toLocaleDateString('en-US', { weekday: 'short' }),
                      activity: point.count
                    })) || []}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                      <XAxis 
                        dataKey="name" 
                        axisLine={false} 
                        tickLine={false} 
                        tick={{ fill: '#6b7280', fontSize: 12 }} 
                        dy={10} 
                      />
                      <YAxis 
                        axisLine={false} 
                        tickLine={false} 
                        tick={{ fill: '#6b7280', fontSize: 12 }} 
                        dx={-10} 
                      />
                      <Tooltip 
                        contentStyle={{ borderRadius: '8px', border: '1px solid #e5e7eb', boxShadow: '0 4px 6px rgba(0,0,0,0.05)' }} 
                      />
                      <Line 
                        type="monotone" 
                        dataKey="activity" 
                        stroke="var(--primary)" 
                        strokeWidth={3} 
                        dot={{ r: 4, fill: '#fff', strokeWidth: 2 }} 
                        activeDot={{ r: 6, strokeWidth: 0 }} 
                      />
                    </LineChart>
                </ResponsiveContainer>
              </div>
            </section>

            <section className="card" style={{ borderLeft: '4px solid var(--warning)', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <div style={{ padding: '0.5rem', background: 'var(--warning-subtle)', color: 'var(--warning)', borderRadius: '8px' }}>
                  <AlertTriangle size={20} />
                </div>
                <div>
                  <h3 style={{ margin: 0 }}>Needs Action</h3>
                  <p className="muted" style={{ fontSize: '0.8rem', marginTop: '2px' }}>Items requiring moderation</p>
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '1rem', borderBottom: '1px solid var(--gray-100)' }}>
                  <div>
                    <p style={{ fontWeight: 500, fontSize: '0.875rem' }}>Open reports</p>
                    <p className="muted" style={{ fontSize: '0.75rem' }}>{stats.openReports} items</p>
                  </div>
                  <Link to="/reports" className="btn-outline-amber" style={{ textDecoration: 'none', padding: '4px 8px', fontSize: '0.75rem', borderRadius: '6px' }}>Review</Link>
                </div>
                
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '1rem', borderBottom: '1px solid var(--gray-100)' }}>
                  <div>
                    <p style={{ fontWeight: 500, fontSize: '0.875rem' }}>KYC verifications</p>
                    <p className="muted" style={{ fontSize: '0.75rem' }}>{stats.pendingVerifications} items</p>
                  </div>
                  <Link to="/users" className="btn-outline-amber" style={{ textDecoration: 'none', padding: '4px 8px', fontSize: '0.75rem', borderRadius: '6px' }}>Review</Link>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <p style={{ fontWeight: 500, fontSize: '0.875rem' }}>Support tickets</p>
                    <p className="muted" style={{ fontSize: '0.75rem' }}>{stats.openSupportTickets} items</p>
                  </div>
                  <Link to="/support" className="btn-outline-amber" style={{ textDecoration: 'none', padding: '4px 8px', fontSize: '0.75rem', borderRadius: '6px' }}>Review</Link>
                </div>
              </div>
            </section>
          </div>
        </>
      )}
    </section>
  )
}
