import { useEffect, useState, useCallback } from 'react'
import { deleteReview, fetchReviews } from '../services/adminApi'
import type { AdminReview, Pagination as PaginationType } from '../types/admin'
import { Star, StarHalf, Trash2, Copy, CheckCircle2 } from 'lucide-react'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

const getInitials = (name: string) => {
  return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase() || '?'
}

const getAvatarColor = (name: string) => {
  const colors = ['#0D6E75', '#14b8a6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899']
  const charCode = name.charCodeAt(0) || 0
  return colors[charCode % colors.length]
}

function StarRating({ rating }: { rating: number }) {
  const stars = []
  for (let i = 1; i <= 5; i++) {
    if (i <= rating) {
      stars.push(<Star key={i} size={14} fill="var(--warning)" color="var(--warning)" />)
    } else if (i - 0.5 === rating) {
      stars.push(<StarHalf key={i} size={14} fill="var(--warning)" color="var(--warning)" />)
    } else {
      stars.push(<Star key={i} size={14} color="var(--gray-300)" />)
    }
  }
  return <div style={{ display: 'flex', gap: '2px' }}>{stars}</div>
}

function CopyableUuid({ uuid }: { uuid: string }) {
  const [copied, setCopied] = useState(false)
  if (!uuid) return <span>-</span>

  const handleCopy = () => {
    navigator.clipboard.writeText(uuid)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="action-row" style={{ display: 'inline-flex' }}>
      <code className="code-chip">{uuid.substring(0, 8)}...</code>
      {copied ? (
        <CheckCircle2 size={14} color="var(--success)" />
      ) : (
        <Copy size={14} className="copy-icon" onClick={handleCopy} />
      )}
    </div>
  )
}

export function ReviewsPage() {
  const { page, limit, setPage } = usePagination(50)
  const [reviews, setReviews] = useState<AdminReview[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(true)

  const loadReviews = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchReviews({ page, limit })
      setReviews(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load reviews.')
    } finally {
      setIsLoading(false)
    }
  }, [page, limit])

  useEffect(() => {
    loadReviews()
  }, [loadReviews])

  const handleDelete = async (review: AdminReview) => {
    const reason = window.prompt('Delete reason for audit trail:', 'Abusive or policy-violating content')
    if (!reason?.trim()) {
      return
    }

    try {
      await deleteReview(review.id, reason)
      await loadReviews()
    } catch {
      setError('Failed to delete review.')
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {error ? <p className="error-text">{error}</p> : null}
      
      <div className="table-wrap">
        {isLoading ? (
          <div className="empty-state">
            <span className="spinner" />
            <p>Loading reviews…</p>
          </div>
        ) : (
          <>
            <table>
              <thead>
                <tr>
                  <th>Author</th>
                  <th>Rating</th>
                  <th>Comment</th>
                  <th>Booking</th>
                  <th style={{ textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {reviews.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="empty-row">No reviews found.</td>
                  </tr>
                ) : (
                  reviews.map((review) => {
                    const authorName = review.reviewer?.fullName ?? review.reviewer?.name ?? 'Unknown'
                    return (
                      <tr key={review.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <div className="avatar" style={{ background: getAvatarColor(authorName), width: '28px', height: '28px', fontSize: '10px' }}>
                              {getInitials(authorName)}
                            </div>
                            <span className="user-name-cell">{authorName}</span>
                          </div>
                        </td>
                        <td>
                          <StarRating rating={review.rating} />
                        </td>
                        <td style={{ maxWidth: '300px' }}>
                          <p style={{ margin: 0, color: 'var(--gray-700)', lineHeight: 1.4 }}>
                            {review.comment}
                          </p>
                        </td>
                        <td>
                          <CopyableUuid uuid={review.bookingId ?? ''} />
                        </td>
                        <td>
                          <div className="action-row" style={{ justifyContent: 'flex-end' }}>
                            <button type="button" className="btn btn-outline-red" onClick={() => handleDelete(review)}>
                              <Trash2 size={16} /> Delete
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  })
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
