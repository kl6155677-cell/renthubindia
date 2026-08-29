import React from 'react'

type StatCardProps = {
  label: string
  value: number | string
  icon: React.ReactNode
  color: 'blue' | 'green' | 'purple' | 'red' | 'amber' | 'gray'
  trend?: { value: number; label: string }
}

const colorMap = {
  blue: { bg: 'var(--info-subtle)', text: 'var(--info)', border: 'var(--info)' },
  green: { bg: 'var(--success-subtle)', text: 'var(--success)', border: 'var(--success)' },
  purple: { bg: 'var(--primary-subtle)', text: 'var(--primary)', border: 'var(--primary)' },
  red: { bg: 'var(--danger-subtle)', text: 'var(--danger)', border: 'var(--danger)' },
  amber: { bg: 'var(--warning-subtle)', text: 'var(--warning)', border: 'var(--warning)' },
  gray: { bg: 'var(--gray-100)', text: 'var(--gray-600)', border: 'var(--gray-400)' },
}

export function StatCard({ label, value, icon, color, trend }: StatCardProps) {
  const theme = colorMap[color]

  return (
    <article className="stat-card">
      <div className="stat-card-top" style={{ background: theme.border }} />
      <div className="stat-header">
        <p className="stat-label">{label}</p>
        <div className="stat-icon-wrap" style={{ background: theme.bg, color: theme.text }}>
          {icon}
        </div>
      </div>
      <h3 className="stat-value">{value}</h3>
      {trend && (
        <div className={`stat-trend ${trend.value > 0 ? 'trend-up' : trend.value < 0 ? 'trend-down' : 'trend-neutral'}`}>
          {trend.value > 0 ? '↑' : trend.value < 0 ? '↓' : '→'} {Math.abs(trend.value)}%
          <span style={{ color: 'var(--gray-500)', marginLeft: '4px' }}>{trend.label}</span>
        </div>
      )}
    </article>
  )
}
