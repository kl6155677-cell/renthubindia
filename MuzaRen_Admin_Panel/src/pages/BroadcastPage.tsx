import { useEffect, useState, useCallback } from 'react'
import type { FormEvent } from 'react'
import { fetchBroadcasts, sendBroadcast } from '../services/adminApi'
import type { BroadcastAudience, BroadcastRecord, Pagination as PaginationType } from '../types/admin'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

const audienceOptions: { value: BroadcastAudience; label: string }[] = [
  { value: 'ALL', label: 'All users' },
  { value: 'VERIFIED', label: 'Verified users only' },
  { value: 'UNVERIFIED', label: 'Unverified users only' },
  { value: 'OWNERS', label: 'Listing owners' },
  { value: 'RENTERS', label: 'Renters only' },
]

const statusColors: Record<string, string> = {
  SENT: 'badge badge-green',
  SCHEDULED: 'badge badge-yellow',
  DRAFT: 'badge badge-gray',
}

export function BroadcastPage() {
  const { page, limit, setPage } = usePagination(50)
  const [broadcasts, setBroadcasts] = useState<BroadcastRecord[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [isLoading, setIsLoading] = useState(true)
  const [isSending, setIsSending] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [audience, setAudience] = useState<BroadcastAudience>('ALL')
  const [scheduledAt, setScheduledAt] = useState('')

  const loadBroadcasts = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchBroadcasts({ page, limit })
      setBroadcasts(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load broadcasts.')
    } finally {
      setIsLoading(false)
    }
  }, [page, limit])

  useEffect(() => {
    loadBroadcasts()
  }, [loadBroadcasts])

  const handleSend = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!window.confirm(`Send broadcast to "${audienceOptions.find(a => a.value === audience)?.label}"?`)) return
    setIsSending(true)
    setError('')
    setSuccess('')
    try {
      await sendBroadcast({
        title: title.trim(),
        body: body.trim(),
        targetAudience: audience,
        scheduledAt: scheduledAt || undefined,
      })
      setTitle('')
      setBody('')
      setScheduledAt('')
      setSuccess('Broadcast sent successfully.')
      await loadBroadcasts()
    } catch {
      setError('Failed to send broadcast. Backend endpoint may not be active yet.')
    } finally {
      setIsSending(false)
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <header className="page-header">
        <h2>Broadcast &amp; Campaigns</h2>
        <span className="phase-badge">Phase 2</span>
      </header>
      <p className="muted">
        Send push notification announcements to targeted user segments.
      </p>

      {/* Compose form */}
      <form className="card" onSubmit={handleSend} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <h3 style={{ margin: 0 }}>Compose broadcast</h3>
        <div className="form-group">
          <label htmlFor="broadcast-title">Title</label>
          <input
            id="broadcast-title"
            type="text"
            required
            placeholder="Announcement title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label htmlFor="broadcast-body">Message body</label>
          <textarea
            id="broadcast-body"
            required
            rows={3}
            placeholder="Your announcement message…"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            className="textarea"
          />
        </div>
        <div className="form-row">
          <div className="form-group">
            <label htmlFor="broadcast-audience">Target audience</label>
            <select
              id="broadcast-audience"
              value={audience}
              onChange={(e) => setAudience(e.target.value as BroadcastAudience)}
            >
              {audienceOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>{opt.label}</option>
              ))}
            </select>
          </div>
          <div className="form-group">
            <label htmlFor="broadcast-schedule">Schedule for (optional)</label>
            <input
              id="broadcast-schedule"
              type="datetime-local"
              value={scheduledAt}
              onChange={(e) => setScheduledAt(e.target.value)}
            />
          </div>
        </div>
        {error ? <p className="error-text">{error}</p> : null}
        {success ? <p className="success-text">{success}</p> : null}
        <div className="action-row" style={{ justifyContent: 'flex-end' }}>
          <button id="send-broadcast-btn" type="submit" className="btn btn-primary" disabled={isSending}>
            {isSending ? 'Sending…' : scheduledAt ? 'Schedule broadcast' : 'Send now'}
          </button>
        </div>
      </form>

      {/* History */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginTop: '1rem' }}>
        <h3 style={{ margin: 0 }}>Broadcast history</h3>
        <div className="table-wrap">
          {isLoading ? (
            <div className="empty-state">
              <span className="spinner" />
              <p>Loading broadcasts…</p>
            </div>
          ) : broadcasts.length === 0 ? (
            <div className="empty-state">
              <p style={{ fontSize: '2rem' }}>📣</p>
              <p>No broadcasts sent yet.</p>
            </div>
          ) : (
            <>
              <table>
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Audience</th>
                    <th>Status</th>
                    <th>Sent count</th>
                    <th>Date</th>
                  </tr>
                </thead>
                <tbody>
                  {broadcasts.map((b) => (
                    <tr key={b.id}>
                      <td>
                        <div style={{ fontWeight: 600 }}>{b.title}</div>
                        <div className="muted" style={{ fontSize: '0.75rem', maxWidth: '300px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {b.body}
                        </div>
                      </td>
                      <td><span className="badge badge-blue">{b.targetAudience}</span></td>
                      <td>
                        <span className={statusColors[b.status ?? ''] ?? 'badge badge-gray'}>
                          {b.status ?? 'SENT'}
                        </span>
                      </td>
                      <td>{b.sentCount ?? '—'}</td>
                      <td className="muted">
                        {b.createdAt ? new Date(b.createdAt).toLocaleDateString() : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {pagination && (
                <Pagination
                  {...pagination}
                  onPageChange={setPage}
                />
              )}
            </>
          )}
        </div>
      </div>
    </section>
  )
}
