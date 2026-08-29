import { useEffect, useState, useCallback } from 'react'
import { fetchReports, updateReportStatus } from '../services/adminApi'
import type { AdminReport, Pagination as PaginationType } from '../types/admin'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

export function ReportsPage() {
  const { page, limit, setPage, resetPagination } = usePagination(50)
  const [reports, setReports] = useState<AdminReport[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [statusFilter, setStatusFilter] = useState('ALL')
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(true)

  const loadReports = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchReports({
        status: statusFilter === 'ALL' ? undefined : statusFilter,
        page,
        limit,
      })
      setReports(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load reports.')
    } finally {
      setIsLoading(false)
    }
  }, [statusFilter, page, limit])

  useEffect(() => {
    loadReports()
  }, [loadReports])

  const handleFilterChange = (val: string) => {
    setStatusFilter(val)
    resetPagination()
  }

  const handleStatus = async (report: AdminReport, status: 'REVIEWED' | 'RESOLVED') => {
    if (!window.confirm(`Mark this report as ${status}?`)) return
    try {
      await updateReportStatus(report.id, status)
      await loadReports()
    } catch {
      setError('Failed to update report status.')
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <div className="filter-bar">
        <select
          value={statusFilter}
          onChange={(e) => handleFilterChange(e.target.value)}
          className="filter-select"
          style={{ borderRadius: '8px' }}
        >
          <option value="ALL">All statuses</option>
          <option value="OPEN">Open</option>
          <option value="REVIEWED">Reviewed</option>
          <option value="RESOLVED">Resolved</option>
        </select>
      </div>

      {error ? <p className="error-text">{error}</p> : null}
      
      <div className="table-wrap">
        {isLoading ? (
          <div className="empty-state">
            <span className="spinner" />
            <p>Loading reports…</p>
          </div>
        ) : (
          <>
            <table>
              <thead>
                <tr>
                  <th>Target</th>
                  <th>Category</th>
                  <th>Description</th>
                  <th>Status</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {reports.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="empty-row">No reports match your filters.</td>
                  </tr>
                ) : (
                  reports.map((report) => (
                    <tr key={report.id}>
                      <td>{report.targetType}</td>
                      <td>
                        <span className="badge badge-amber">{report.category}</span>
                      </td>
                      <td>{report.description}</td>
                      <td>
                        <span className={`badge ${report.status === 'RESOLVED' ? 'badge-green' : 'badge-gray'}`}>
                          {report.status}
                        </span>
                      </td>
                      <td>
                        <div className="action-row" style={{ justifyContent: 'flex-end' }}>
                          {report.status === 'OPEN' && (
                            <button
                              type="button"
                              className="btn btn-outline-gray"
                              onClick={() => handleStatus(report, 'REVIEWED')}
                            >
                              Mark reviewed
                            </button>
                          )}
                          {report.status !== 'RESOLVED' && (
                            <button
                              type="button"
                              className="btn btn-primary"
                              onClick={() => handleStatus(report, 'RESOLVED')}
                            >
                              Resolve
                            </button>
                          )}
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
