import { useEffect, useState, useCallback } from 'react'
import { fetchUsers, toggleUserBlock, verifyUser } from '../services/adminApi'
import type { AdminUser, Pagination as PaginationType } from '../types/admin'
import { Search, MoreVertical, ShieldAlert, ShieldCheck, Ban, CheckCircle2 } from 'lucide-react'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

const verificationColors: Record<string, string> = {
  VERIFIED: 'badge badge-green',
  PENDING: 'badge badge-amber',
  UNVERIFIED: 'badge badge-amber',
  REJECTED: 'badge badge-red',
}

const getInitials = (name: string) => {
  return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase() || '?'
}

const getAvatarColor = (name: string) => {
  const colors = ['#0D6E75', '#14b8a6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899']
  const charCode = name.charCodeAt(0) || 0
  return colors[charCode % colors.length]
}

export function UsersPage() {
  const { page, limit, setPage, resetPagination } = usePagination(50)
  const [users, setUsers] = useState<AdminUser[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('ALL')
  const [verificationFilter, setVerificationFilter] = useState('ALL')
  
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(true)

  const loadUsers = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchUsers({
        role: roleFilter,
        verificationStatus: verificationFilter,
        search: search.trim(),
        page,
        limit,
      })
      setUsers(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load users.')
    } finally {
      setIsLoading(false)
    }
  }, [roleFilter, verificationFilter, search, page, limit])

  useEffect(() => {
    const timer = setTimeout(() => {
      loadUsers()
    }, search ? 500 : 0) // Debounce search
    return () => clearTimeout(timer)
  }, [loadUsers])

  //hello
  // Reset to page 1 when filters change
  const handleFilterChange = (setter: (val: string) => void, val: string) => {
    setter(val)
    resetPagination()
  }

  const handleToggleBlock = async (user: AdminUser) => {
    if (!window.confirm(`${user.isBlocked ? 'Unblock' : 'Block'} user ${user.fullName}?`)) return
    try {
      await toggleUserBlock(user.id, !user.isBlocked)
      await loadUsers()
    } catch {
      setError('Failed to update user block status.')
    }
  }

  const handleVerify = async (user: AdminUser) => {
    if (!window.confirm(`Verify identity for ${user.fullName}?`)) return
    try {
      await verifyUser(user.id)
      await loadUsers()
    } catch {
      setError('Failed to verify user.')
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <div className="filter-bar">
        <div className="search-input-wrap">
          <Search size={18} />
          <input
            type="search"
            placeholder="Search name or email…"
            value={search}
            onChange={(e) => handleFilterChange(setSearch, e.target.value)}
            className="search-input"
            id="users-search"
          />
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <select
            id="users-role-filter"
            value={roleFilter}
            onChange={(e) => handleFilterChange(setRoleFilter, e.target.value)}
            className="filter-select"
            style={{ borderRadius: '8px' }}
          >
            <option value="ALL">All roles</option>
            <option value="USER">User</option>
            <option value="ADMIN">Admin</option>
          </select>
          <select
            id="users-verification-filter"
            value={verificationFilter}
            onChange={(e) => handleFilterChange(setVerificationFilter, e.target.value)}
            className="filter-select"
            style={{ borderRadius: '8px' }}
          >
            <option value="ALL">All statuses</option>
            <option value="VERIFIED">Verified</option>
            <option value="PENDING">Pending</option>
            <option value="UNVERIFIED">Unverified</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>
      </div>

      {error ? <p className="error-text">{error}</p> : null}
      
      <div className="table-wrap">
        {isLoading ? (
          <div className="empty-state">
            <span className="spinner" />
            <p>Loading users…</p>
          </div>
        ) : (
          <>
            <table>
              <thead>
                <tr>
                  <th>User</th>
                  <th>Role</th>
                  <th>Verification</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="empty-row">No users match your filters.</td>
                  </tr>
                ) : (
                  users.map((user) => (
                    <tr key={user.id}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                          <div 
                            className="avatar" 
                            style={{ background: getAvatarColor(user.fullName) }}
                          >
                            {getInitials(user.fullName)}
                          </div>
                          <div>
                            <div className="user-name-cell">{user.fullName}</div>
                            <div className="muted" style={{ fontSize: '0.75rem' }}>{user.email}</div>
                          </div>
                        </div>
                      </td>
                      <td><span className="badge badge-purple">{user.role}</span></td>
                      <td>
                        <span className={verificationColors[user.verificationStatus] ?? 'badge badge-gray'}>
                          {user.verificationStatus === 'VERIFIED' ? <ShieldCheck size={14} /> : <ShieldAlert size={14} />}
                          {user.verificationStatus}
                        </span>
                      </td>
                      <td>
                        <span className={user.isBlocked ? 'badge badge-red' : 'badge badge-green'}>
                          {user.isBlocked ? 'Blocked' : 'Active'}
                        </span>
                      </td>
                      <td className="muted">
                        {user.createdAt ? new Date(user.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' }) : '—'}
                      </td>
                      <td>
                        <div className="action-row" style={{ justifyContent: 'flex-end' }}>
                          {user.verificationStatus === 'PENDING' && (
                            <button
                              id={`verify-user-${user.id}`}
                              type="button"
                              className="btn btn-outline-green"
                              onClick={() => handleVerify(user)}
                            >
                              <CheckCircle2 size={16} /> Verify
                            </button>
                          )}
                          <button
                            id={`block-user-${user.id}`}
                            type="button"
                            className={user.isBlocked ? 'btn btn-outline-green' : 'btn btn-outline-red'}
                            onClick={() => handleToggleBlock(user)}
                          >
                            {user.isBlocked ? <CheckCircle2 size={16} /> : <Ban size={16} />}
                            {user.isBlocked ? 'Unblock' : 'Block'}
                          </button>
                          <button className="btn btn-outline-gray" style={{ padding: '6px' }} title="More options">
                            <MoreVertical size={16} />
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
