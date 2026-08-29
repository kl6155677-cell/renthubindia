import { useEffect, useState } from 'react'
import { fetchAnalytics } from '../services/adminApi'
import type { AnalyticsData } from '../types/admin'
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer } from 'recharts'
import { AlertCircle, BarChart3, LineChart as LineChartIcon, Map, Boxes } from 'lucide-react'

type Range = '7d' | '30d' | '90d'

const rangeLabels: Record<Range, string> = {
  '7d': 'Last 7 days',
  '30d': 'Last 30 days',
  '90d': 'Last 90 days',
}

function EmptyState({ icon, title, description }: { icon: React.ReactNode, title: string, description: string }) {
  return (
    <div className="empty-state">
      {icon}
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  )
}

function PlaceholderLineChart() {
  const dummy = [{name:'A',val:0},{name:'B',val:0},{name:'C',val:0},{name:'D',val:0}]
  return (
    <div style={{ width: '100%', height: '200px' }}>
      <ResponsiveContainer>
        <LineChart data={dummy}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
          <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill:'#9ca3af', fontSize:12}} />
          <YAxis axisLine={false} tickLine={false} tick={{fill:'#9ca3af', fontSize:12}} />
          <Line type="monotone" dataKey="val" stroke="#e5e7eb" strokeWidth={2} dot={false} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}

function PlaceholderBarChart() {
  const dummy = [{name:'A',val:0},{name:'B',val:0},{name:'C',val:0},{name:'D',val:0}]
  return (
    <div style={{ width: '100%', height: '200px' }}>
      <ResponsiveContainer>
        <BarChart data={dummy}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
          <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill:'#9ca3af', fontSize:12}} />
          <YAxis axisLine={false} tickLine={false} tick={{fill:'#9ca3af', fontSize:12}} />
          <Bar dataKey="val" fill="#e5e7eb" radius={[4,4,0,0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

function FunnelBar({ label, value, max, color }: { label: string; value: number; max: number; color: string }) {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0
  return (
    <div className="funnel-row">
      <span className="funnel-label">{label}</span>
      <div className="funnel-track">
        <div className="funnel-fill" style={{ width: `${pct}%`, background: color }} />
      </div>
      <span className="funnel-value">{value.toLocaleString()} <span className="muted">({pct}%)</span></span>
    </div>
  )
}

export function AnalyticsPage() {
  const [range, setRange] = useState<Range>('30d')
  const [data, setData] = useState<AnalyticsData>({})
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')

  const loadAnalytics = async (r: Range) => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchAnalytics(r)
      setData(result)
    } catch {
      setError('Failed to load analytics. Backend endpoint may not be active yet.')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadAnalytics(range)
  }, [range])

  const funnel = data.bookingFunnel
  const funnelMax = funnel?.created ?? 1

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      {/* Range selector */}
      <div className="filter-bar">
        <div>
          <h3 style={{ fontSize: '1rem', fontWeight: 600, color: 'var(--gray-900)' }}>Analytics Overview</h3>
          <p className="muted" style={{ fontSize: '0.875rem' }}>Cohort retention, conversion funnel, geographic demand</p>
        </div>
        <div className="segment-control">
          {(Object.keys(rangeLabels) as Range[]).map((r) => (
            <button
              key={r}
              type="button"
              className={`segment-btn ${range === r ? 'active' : ''}`}
              onClick={() => setRange(r)}
            >
              {rangeLabels[r]}
            </button>
          ))}
        </div>
      </div>

      {error ? (
        <div style={{ padding: '1rem', background: 'var(--danger-subtle)', color: 'var(--danger)', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <AlertCircle size={20} /> {error}
        </div>
      ) : null}

      {isLoading ? (
        <div className="loading-state"><span className="spinner" />Crunching numbers…</div>
      ) : (
        <>
          {/* Booking funnel */}
          <section className="card">
            <h3>Booking conversion funnel</h3>
            {funnel ? (
              <div className="funnel-chart" style={{ marginTop: '1.5rem' }}>
                <FunnelBar label="Created"   value={funnel.created}   max={funnelMax} color="var(--info)" />
                <FunnelBar label="Accepted"  value={funnel.accepted}  max={funnelMax} color="var(--success)" />
                <FunnelBar label="Completed" value={funnel.completed} max={funnelMax} color="var(--primary)" />
                <FunnelBar label="Cancelled" value={funnel.cancelled} max={funnelMax} color="var(--danger)" />
              </div>
            ) : (
              <EmptyState 
                icon={<BarChart3 size={48} />} 
                title="No funnel data" 
                description="There are no bookings in this period to aggregate." 
              />
            )}
          </section>

          {/* Growth metrics side by side */}
          <div className="analytics-grid">
            {/* User growth */}
            <section className="card" style={{ display: 'flex', flexDirection: 'column' }}>
              <h3>User growth</h3>
              {data.userGrowth && data.userGrowth.length > 0 ? (
                <div className="sparkline-list" style={{ marginTop: 'auto' }}>
                  {data.userGrowth.slice(-10).map((point) => (
                    <div key={point.date} className="sparkline-row">
                      <span className="spark-date muted">{new Date(point.date).toLocaleDateString(undefined, {month: 'short', day: 'numeric'})}</span>
                      <div className="spark-track">
                        <div
                          className="spark-fill"
                          style={{
                            width: `${Math.min(100, (point.count / Math.max(...(data.userGrowth ?? []).map(p => p.count), 1)) * 100)}%`,
                          }}
                        />
                      </div>
                      <span className="spark-val">{point.count}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                  <PlaceholderLineChart />
                  <EmptyState icon={<LineChartIcon size={32} />} title="No user growth data" description="Try selecting a different time range." />
                </div>
              )}
            </section>

            {/* Listing growth */}
            <section className="card" style={{ display: 'flex', flexDirection: 'column' }}>
              <h3>Listing growth</h3>
              {data.listingGrowth && data.listingGrowth.length > 0 ? (
                <div className="sparkline-list" style={{ marginTop: 'auto' }}>
                  {data.listingGrowth.slice(-10).map((point) => (
                    <div key={point.date} className="sparkline-row">
                      <span className="spark-date muted">{new Date(point.date).toLocaleDateString(undefined, {month: 'short', day: 'numeric'})}</span>
                      <div className="spark-track">
                        <div
                          className="spark-fill"
                          style={{
                            width: `${Math.min(100, (point.count / Math.max(...(data.listingGrowth ?? []).map(p => p.count), 1)) * 100)}%`,
                            background: 'var(--success)'
                          }}
                        />
                      </div>
                      <span className="spark-val">{point.count}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                  <PlaceholderLineChart />
                  <EmptyState icon={<LineChartIcon size={32} />} title="No listing data" description="Try selecting a different time range." />
                </div>
              )}
            </section>
          </div>

          {/* Top categories + Geo demand */}
          <div className="analytics-grid">
            <section className="card" style={{ display: 'flex', flexDirection: 'column' }}>
              <h3>Top categories</h3>
              {data.topCategories && data.topCategories.length > 0 ? (
                <div className="table-wrap" style={{ border: 'none', boxShadow: 'none' }}>
                  <table>
                    <thead>
                      <tr><th>#</th><th>Category</th><th>Listings</th></tr>
                    </thead>
                    <tbody>
                      {data.topCategories.map((cat, i) => (
                        <tr key={cat.categoryName}>
                          <td className="muted">{i + 1}</td>
                          <td><strong>{cat.categoryName}</strong></td>
                          <td>{cat.listingCount.toLocaleString()}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                  <PlaceholderBarChart />
                  <EmptyState icon={<Boxes size={32} />} title="No category data" description="Create listings to populate categories." />
                </div>
              )}
            </section>

            <section className="card" style={{ display: 'flex', flexDirection: 'column' }}>
              <h3>Geographic demand</h3>
              {data.geoDemand && data.geoDemand.length > 0 ? (
                <div className="table-wrap" style={{ border: 'none', boxShadow: 'none' }}>
                  <table>
                    <thead>
                      <tr><th>#</th><th>City</th><th>Country</th><th>Listings</th></tr>
                    </thead>
                    <tbody>
                      {data.geoDemand.map((geo, i) => (
                        <tr key={`${geo.city}-${geo.country}`}>
                          <td className="muted">{i + 1}</td>
                          <td><strong>{geo.city}</strong></td>
                          <td className="muted">{geo.country}</td>
                          <td>{geo.listingCount.toLocaleString()}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                  <PlaceholderBarChart />
                  <EmptyState icon={<Map size={32} />} title="No geo data" description="Locations will appear as listings are added." />
                </div>
              )}
            </section>
          </div>
        </>
      )}
    </section>
  )
}
