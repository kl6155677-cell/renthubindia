import { useEffect, useState, useCallback } from 'react'
import { approveListing, deleteListing, fetchListings } from '../services/adminApi'
import type { AdminListing, Pagination as PaginationType } from '../types/admin'
import { Search, Image as ImageIcon, CheckCircle2, XCircle, Trash2, ShieldAlert } from 'lucide-react'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

export function ListingsPage() {
  const { page, limit, setPage, resetPagination } = usePagination(50)
  const [listings, setListings] = useState<AdminListing[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('ALL')

  const loadListings = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchListings({
        search: search.trim(),
        status: statusFilter === 'ALL' ? undefined : statusFilter,
        page,
        limit,
      })
      setListings(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load listings.')
    } finally {
      setIsLoading(false)
    }
  }, [search, statusFilter, page, limit])

  useEffect(() => {
    const timer = setTimeout(() => {
      loadListings()
    }, search ? 500 : 0)
    return () => clearTimeout(timer)
  }, [loadListings])

  const handleFilterChange = (setter: (val: string) => void, val: string) => {
    setter(val)
    resetPagination()
  }

  const handleApprove = async (listing: AdminListing) => {
    if (!window.confirm(`${listing.isApproved ? 'Unapprove' : 'Approve'} listing "${listing.title}"?`)) return
    try {
      await approveListing(listing.id, !listing.isApproved)
      await loadListings()
    } catch {
      setError('Failed to update listing approval.')
    }
  }

  const handleDelete = async (listing: AdminListing) => {
    if (!window.confirm(`Permanently delete listing "${listing.title}"? This cannot be undone.`)) return
    try {
      await deleteListing(listing.id)
      await loadListings()
    } catch {
      setError('Failed to delete listing. It may have active bookings preventing deletion.')
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <div className="filter-bar">
        <div className="search-input-wrap">
          <Search size={18} />
          <input
            type="search"
            placeholder="Search title or location…"
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
          <option value="ACTIVE">Active</option>
          <option value="INACTIVE">Inactive</option>
          <option value="DRAFT">Draft</option>
        </select>
      </div>

      {error ? <p className="error-text">{error}</p> : null}
      
      <div className="table-wrap">
        {isLoading ? (
          <div className="empty-state">
            <span className="spinner" />
            <p>Loading listings…</p>
          </div>
        ) : (
          <>
            <table>
              <thead>
                <tr>
                  <th style={{ width: '60px' }}>Media</th>
                  <th>Listing</th>
                  <th>Price/day</th>
                  <th>Status</th>
                  <th>Approved</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {listings.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="empty-row">No listings match your filters.</td>
                  </tr>
                ) : (
                  listings.map((listing) => (
                    <tr key={listing.id}>
                      <td>
                        <div style={{ width: '40px', height: '40px', borderRadius: '8px', background: 'var(--gray-100)', display: 'grid', placeItems: 'center', color: 'var(--gray-400)' }}>
                          <ImageIcon size={20} />
                        </div>
                      </td>
                      <td>
                        <div className="user-name-cell">{listing.title}</div>
                        <div className="muted" style={{ fontSize: '0.75rem' }}>{listing.city}, {listing.country}</div>
                      </td>
                      <td style={{ fontWeight: 500 }}>${listing.pricePerDay}</td>
                      <td>
                        <span className={listing.status === 'ACTIVE' ? 'badge badge-green' : 'badge badge-gray'}>
                          {listing.status}
                        </span>
                      </td>
                      <td>
                        {listing.isApproved ? (
                          <span style={{ color: 'var(--success)' }} title="Approved"><CheckCircle2 size={20} /></span>
                        ) : (
                          <span style={{ color: 'var(--danger)' }} title="Not approved"><XCircle size={20} /></span>
                        )}
                      </td>
                      <td>
                        <div className="action-row" style={{ justifyContent: 'flex-end' }}>
                          <button
                            type="button"
                            className={listing.isApproved ? 'btn btn-outline-amber' : 'btn btn-outline-green'}
                            onClick={() => handleApprove(listing)}
                          >
                            {listing.isApproved ? <ShieldAlert size={16} /> : <CheckCircle2 size={16} />}
                            {listing.isApproved ? 'Unapprove' : 'Approve'}
                          </button>
                          <button
                            type="button"
                            className="btn btn-outline-red"
                            onClick={() => handleDelete(listing)}
                          >
                            <Trash2 size={16} /> Delete
                          </button>
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
