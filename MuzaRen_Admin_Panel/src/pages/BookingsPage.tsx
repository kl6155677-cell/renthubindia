import { useEffect, useState, useCallback } from 'react'
import { fetchBookings } from '../services/adminApi'
import type { AdminBooking, Pagination as PaginationType } from '../types/admin'
import { Clock, CheckCircle2, XCircle, CalendarCheck, Filter } from 'lucide-react'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

const statusOptions = ['ALL', 'PENDING', 'ACCEPTED', 'COMPLETED', 'CANCELLED'] as const

const getStatusBadge = (status: string) => {
  switch (status) {
    case 'PENDING':
      return <span className="badge badge-amber"><Clock size={14} /> Pending</span>
    case 'COMPLETED':
      return <span className="badge badge-green"><CheckCircle2 size={14} /> Completed</span>
    case 'ACCEPTED':
      return <span className="badge badge-blue"><CalendarCheck size={14} /> Accepted</span>
    case 'CANCELLED':
      return <span className="badge badge-red"><XCircle size={14} /> Cancelled</span>
    default:
      return <span className="badge badge-gray">{status}</span>
  }
}

const formatDate = (isoString?: string) => {
  if (!isoString) return '-'
  const d = new Date(isoString)
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
}

export function BookingsPage() {
  const { page, limit, setPage, resetPagination } = usePagination(50)
  const [bookings, setBookings] = useState<AdminBooking[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [statusFilter, setStatusFilter] = useState<(typeof statusOptions)[number]>('ALL')
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(true)

  const loadBookings = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchBookings({
        status: statusFilter === 'ALL' ? undefined : statusFilter,
        page,
        limit,
      })
      setBookings(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load bookings.')
    } finally {
      setIsLoading(false)
    }
  }, [statusFilter, page, limit])

  useEffect(() => {
    loadBookings()
  }, [loadBookings])

  const handleFilterChange = (val: string) => {
    setStatusFilter(val as any)
    resetPagination()
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <div className="filter-bar">
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Filter size={18} className="muted" />
          <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--gray-700)' }}>Filter by status:</span>
        </div>
        <select
          value={statusFilter}
          onChange={(event) => handleFilterChange(event.target.value)}
          className="filter-select"
          style={{ width: '200px', borderRadius: '8px' }}
        >
          {statusOptions.map((status) => (
            <option key={status} value={status}>
              {status === 'ALL' ? 'All bookings' : status}
            </option>
          ))}
        </select>
      </div>

      {error ? <p className="error-text">{error}</p> : null}
      
      <div className="table-wrap">
        {isLoading ? (
          <div className="empty-state">
            <span className="spinner" />
            <p>Loading bookings…</p>
          </div>
        ) : (
          <>
            <table>
              <thead>
                <tr>
                  <th>Listing</th>
                  <th>Renter</th>
                  <th>Owner</th>
                  <th>Status</th>
                  <th>Timeline</th>
                </tr>
              </thead>
              <tbody>
                {bookings.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="empty-row">No bookings found.</td>
                  </tr>
                ) : (
                  bookings.map((booking) => (
                    <tr key={booking.id}>
                      <td>
                        <strong style={{ color: 'var(--gray-900)' }}>{booking.listing?.title ?? 'Unknown listing'}</strong>
                      </td>
                      <td>{booking.renter?.fullName ?? 'Unknown renter'}</td>
                      <td>{booking.owner?.fullName ?? 'Unknown owner'}</td>
                      <td>{getStatusBadge(booking.status)}</td>
                      <td className="muted" style={{ fontSize: '0.8rem' }}>
                        {formatDate(booking.startDate)} → {formatDate(booking.endDate)}
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
