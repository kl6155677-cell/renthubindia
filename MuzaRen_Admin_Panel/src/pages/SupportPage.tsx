import { useEffect, useState, useCallback } from 'react'
import type { FormEvent } from 'react'
import { fetchSupportTickets, replyToSupportTicket } from '../services/adminApi'
import type { AdminSupportTicket, Pagination as PaginationType } from '../types/admin'
import { Search, MessageSquare } from 'lucide-react'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

export function SupportPage() {
  const { page, limit, setPage, resetPagination } = usePagination(50)
  const [tickets, setTickets] = useState<AdminSupportTicket[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('ALL')
  
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [replyByTicket, setReplyByTicket] = useState<Record<string, string>>({})

  const loadTickets = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchSupportTickets({
        search: search.trim(),
        status: statusFilter === 'ALL' ? undefined : statusFilter,
        page,
        limit,
      })
      setTickets(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load support tickets.')
    } finally {
      setIsLoading(false)
    }
  }, [search, statusFilter, page, limit])

  useEffect(() => {
    const timer = setTimeout(() => {
      loadTickets()
    }, search ? 500 : 0)
    return () => clearTimeout(timer)
  }, [loadTickets])

  const handleFilterChange = (setter: (val: string) => void, val: string) => {
    setter(val)
    resetPagination()
  }

  const handleReply = async (event: FormEvent, ticketId: string) => {
    event.preventDefault()
    const reply = replyByTicket[ticketId]?.trim()
    if (!reply) return
    try {
      await replyToSupportTicket(ticketId, reply)
      setReplyByTicket((prev) => ({ ...prev, [ticketId]: '' }))
      await loadTickets()
    } catch {
      setError('Failed to send admin reply.')
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <div className="filter-bar">
        <div className="search-input-wrap">
          <Search size={18} />
          <input
            type="search"
            placeholder="Search subject…"
            value={search}
            onChange={(e) => handleFilterChange(setSearch, e.target.value)}
            className="search-input"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => handleFilterChange(setStatusFilter, e.target.value)}
          className="filter-select"
          style={{ borderRadius: '8px' }}
        >
          <option value="ALL">All statuses</option>
          <option value="OPEN">Open</option>
          <option value="IN_PROGRESS">In Progress</option>
          <option value="RESOLVED">Resolved</option>
          <option value="CLOSED">Closed</option>
        </select>
      </div>

      {error ? <p className="error-text">{error}</p> : null}
      
      <div className="table-wrap">
        {isLoading ? (
          <div className="empty-state">
            <span className="spinner" />
            <p>Loading tickets…</p>
          </div>
        ) : (
          <>
            <table>
              <thead>
                <tr>
                  <th>User</th>
                  <th>Subject</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {tickets.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="empty-row">No support tickets found.</td>
                  </tr>
                ) : (
                  tickets.map((ticket) => (
                    <tr key={ticket.id}>
                      <td>
                        <div className="user-name-cell">{ticket.user?.fullName ?? 'Unknown'}</div>
                        <div className="muted" style={{ fontSize: '0.75rem' }}>{ticket.user?.email}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: 500 }}>{ticket.subject}</div>
                        <div className="muted" style={{ fontSize: '0.75rem', maxWidth: '300px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {ticket.message}
                        </div>
                      </td>
                      <td>
                        <span className={`badge ${ticket.status === 'OPEN' ? 'badge-amber' : ticket.status === 'RESOLVED' ? 'badge-green' : 'badge-gray'}`}>
                          {ticket.status}
                        </span>
                      </td>
                      <td className="muted">
                        {ticket.createdAt ? new Date(ticket.createdAt).toLocaleDateString() : '—'}
                      </td>
                      <td>
                        <div className="action-row" style={{ justifyContent: 'flex-end' }}>
                          <form onSubmit={(event) => handleReply(event, ticket.id)} className="action-row">
                            <input
                              type="text"
                              placeholder="Quick reply..."
                              value={replyByTicket[ticket.id] ?? ''}
                              onChange={(event) =>
                                setReplyByTicket((prev) => ({ ...prev, [ticket.id]: event.target.value }))
                              }
                              style={{ width: '180px', height: '32px', fontSize: '12px' }}
                            />
                            <button className="btn btn-primary" type="submit" style={{ height: '32px' }}>
                              <MessageSquare size={14} /> Send
                            </button>
                          </form>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
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
