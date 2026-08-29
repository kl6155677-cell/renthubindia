import { useEffect, useState, useCallback } from 'react'
import { deleteMessage, fetchFlaggedMessages } from '../services/adminApi'
import type { FlaggedMessage, Pagination as PaginationType } from '../types/admin'
import { Search, ShieldAlert, MessageSquare } from 'lucide-react'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

export function MessagingPage() {
  const { page, limit, setPage, resetPagination } = usePagination(50)
  const [messages, setMessages] = useState<FlaggedMessage[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [search, setSearch] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')

  const loadMessages = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchFlaggedMessages({
        page,
        limit,
      })
      setMessages(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load flagged messages.')
    } finally {
      setIsLoading(false)
    }
  }, [page, limit])

  useEffect(() => {
    loadMessages()
  }, [loadMessages])

  const handleSearchChange = (val: string) => {
    setSearch(val)
    resetPagination()
  }

  const handleTakedown = async (msg: FlaggedMessage) => {
    const reason = window.prompt('Enter takedown reason for audit trail:', 'Abusive / policy-violating content')
    if (!reason?.trim()) return
    try {
      await deleteMessage(msg.id, reason)
      await loadMessages()
    } catch {
      setError('Failed to remove message.')
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <header className="page-header">
        <h2>Messaging Moderation</h2>
        <span className="phase-badge">Phase 2</span>
      </header>
      <p className="muted">
        Review flagged chat messages, inspect abuse patterns, and issue takedowns.
      </p>

      <div className="filter-bar">
        <div className="search-input-wrap">
          <Search size={18} />
          <input
            type="search"
            placeholder="Search messages or users…"
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
            className="search-input"
          />
        </div>
      </div>

      {error ? <p className="error-text">{error}</p> : null}

      <div className="table-wrap">
        {isLoading ? (
          <div className="empty-state">
            <span className="spinner" />
            <p>Loading flagged messages…</p>
          </div>
        ) : messages.length === 0 ? (
          <div className="empty-state">
            <MessageSquare size={48} color="var(--gray-300)" />
            <h3>No flagged messages found</h3>
            <p>Queue is clear.</p>
          </div>
        ) : (
          <>
            <table>
              <thead>
                <tr>
                  <th>From</th>
                  <th>To</th>
                  <th>Content</th>
                  <th>Reason</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {messages.map((msg) => (
                  <tr key={msg.id}>
                    <td>
                      <div className="user-name-cell">{msg.sender?.fullName ?? 'Unknown'}</div>
                      <div className="muted" style={{ fontSize: '0.75rem' }}>{msg.sender?.email}</div>
                    </td>
                    <td>
                      <div className="user-name-cell">{msg.receiver?.fullName ?? 'Unknown'}</div>
                      <div className="muted" style={{ fontSize: '0.75rem' }}>{msg.receiver?.email}</div>
                    </td>
                    <td style={{ maxWidth: '300px' }}>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: 'var(--gray-700)', fontStyle: 'italic' }}>
                        "{msg.content}"
                      </p>
                    </td>
                    <td>
                      <span className="badge badge-red">{msg.flagReason ?? 'Flagged'}</span>
                    </td>
                    <td>
                      <div className="action-row" style={{ justifyContent: 'flex-end' }}>
                        <button
                          type="button"
                          className="btn btn-outline-red btn-sm"
                          onClick={() => handleTakedown(msg)}
                        >
                          <ShieldAlert size={14} /> Takedown
                        </button>
                      </div>
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
    </section>
  )
}
