import type {
  AdminBooking,
  AdminCategory,
  AdminListing,
  AdminReport,
  AdminReview,
  AdminSupportTicket,
  AdminRole,
  AdminUser,
  DashboardStats,
  Pagination,
} from '../types/admin'
import { api, cachedGet, clearApiCache } from './api'

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

/** Backend uses 'name' field; admin UI expects 'fullName'. Remap safely. */
function toFullName<T extends { name?: string; fullName?: string }>(u: T): T & { fullName: string } {
  return { ...u, fullName: u.fullName ?? u.name ?? 'Unknown' }
}


// ─────────────────────────────────────────────
//  Auth
// ─────────────────────────────────────────────

type LoginResponse = { token: string; role: AdminRole }

export async function loginAdmin(email: string, password: string): Promise<LoginResponse> {
  const response = await api.post('/auth/login', { email, password })

  // Backend returns: { success: true, data: { user, accessToken, refreshToken, expiresIn } }
  const data = response.data?.data ?? {}
  const token = data.accessToken ?? ''
  const role: AdminRole = data.user?.role ?? 'ADMIN'

  if (!token) throw new Error('No access token returned from server')

  const allowedRoles: AdminRole[] = ['ADMIN', 'SUPER_ADMIN', 'MODERATOR']
  if (!allowedRoles.includes(role)) {
    throw new Error('Access denied — this account does not have admin privileges')
  }

  return { token, role }
}

// ─────────────────────────────────────────────
//  Dashboard  GET /api/admin/dashboard
//  Backend returns: { usersCount, listingsCount, bookingsCount, openReports }
// ─────────────────────────────────────────────

export async function fetchDashboardStats(): Promise<DashboardStats> {
  const response = await cachedGet('/admin/dashboard')
  const d = response.data?.data ?? {}
  return {
    totalUsers:          d.totalUsers          ?? d.usersCount    ?? 0,
    totalListings:       d.totalListings       ?? d.listingsCount ?? 0,
    totalBookings:       d.totalBookings       ?? d.bookingsCount ?? 0,
    openReports:         d.openReports         ?? d.reportsCount  ?? 0,
    pendingVerifications: d.pendingVerifications ?? 0,
    openSupportTickets:  d.openSupportTickets  ?? 0,
    newUsers7d:          d.newUsers7d,
    newListings7d:       d.newListings7d,
    bookingCompletionRate7d:    d.bookingCompletionRate7d,
    bookingCancellationRate7d:  d.bookingCancellationRate7d,
  }
}

// ─────────────────────────────────────────────
//  Users  GET /api/admin/users
//  Backend returns: { users: [...], pagination: {} }  with field 'name' not 'fullName'
// ─────────────────────────────────────────────

export async function fetchUsers(params?: {
  role?: string
  verificationStatus?: string
  search?: string
  page?: number
  limit?: number
}): Promise<{ data: AdminUser[]; pagination: Pagination }> {
  const response = await cachedGet('/users', { params })
  const { data: raw, pagination } = response.data
  const data = (raw || []).map(toFullName)
  return { data, pagination }
}

/** Block or unblock a user — PATCH /api/admin/users/:id/block */
export async function toggleUserBlock(userId: string, isBlocked: boolean): Promise<void> {
  await api.patch(`/users/${userId}/block`, { isBlocked })
  clearApiCache()
}

/** Verify a user identity — PATCH /api/admin/users/:id/verify */
export async function verifyUser(userId: string): Promise<void> {
  await api.patch(`/admin/users/${userId}/verify`)
  clearApiCache()
}

/** Fetch a single user — GET /api/admin/users/:id */
export async function fetchUserById(userId: string): Promise<AdminUser> {
  const response = await cachedGet(`/admin/users/${userId}`)
  const u = response.data?.data ?? {}
  return toFullName(u)
}

// ─────────────────────────────────────────────
//  Listings  GET /api/admin/listings
//  Backend returns: { listings: [...], pagination: {} }
//  Listing.user.name  →  owner.fullName
// ─────────────────────────────────────────────

export async function fetchListings(params?: {
  search?: string
  category?: string
  status?: string
  page?: number
  limit?: number
}): Promise<{ data: AdminListing[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/listings', { params })
  const { data: raw, pagination } = response.data
  const data = (raw || []).map((l: any) => ({
    ...l,
    owner: l.owner
      ? { ...l.owner, fullName: l.owner.fullName ?? l.owner.name ?? 'Unknown' }
      : l.user
      ? { fullName: l.user.name ?? 'Unknown', email: l.user.email ?? '' }
      : undefined,
  }))
  return { data, pagination }
}

/** Approve or unapprove a listing — PATCH /api/admin/listings/:id/approve */
export async function approveListing(listingId: string, isApproved: boolean): Promise<void> {
  await api.patch(`/admin/listings/${listingId}/approve`, { isApproved })
  clearApiCache()
}

/** Delete a listing — DELETE /api/admin/listings/:id */
export async function deleteListing(listingId: string): Promise<void> {
  await api.delete(`/admin/listings/${listingId}`)
  clearApiCache()
}

// ─────────────────────────────────────────────
//  Bookings  GET /api/admin/bookings
//  Backend returns: { bookings: [...], pagination: {} }
//  renter.name / owner.name  →  fullName
// ─────────────────────────────────────────────

export async function fetchBookings(params?: {
  status?: string
  page?: number
  limit?: number
}): Promise<{ data: AdminBooking[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/bookings', { params })
  const { data: raw, pagination } = response.data

  const data = (raw || []).map((b: any) => ({
    ...b,
    renter: b.renter ? { ...b.renter, fullName: b.renter.fullName ?? b.renter.name ?? 'Unknown' } : undefined,
    owner:  b.owner  ? { ...b.owner,  fullName: b.owner.fullName  ?? b.owner.name  ?? 'Unknown' } : undefined,
  }))
  return { data, pagination }
}

// ─────────────────────────────────────────────
//  Reports  GET /api/admin/reports
//  reporter.name  →  reporter.fullName
// ─────────────────────────────────────────────

export async function fetchReports(params?: {
  status?: string
  targetType?: string
  page?: number
  limit?: number
}): Promise<{ data: AdminReport[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/reports', { params })
  const { data: raw, pagination } = response.data
  const data = (raw || []).map((r: any) => ({
    ...r,
    reporter: r.reporter
      ? { ...r.reporter, fullName: r.reporter.fullName ?? r.reporter.name ?? 'Unknown' }
      : undefined,
  }))
  return { data, pagination }
}

/** Set a report's status — PATCH /api/admin/reports/:id/action */
export async function updateReportStatus(
  reportId: string,
  status: 'REVIEWED' | 'RESOLVED',
  adminNote?: string,
): Promise<void> {
  await api.patch(`/admin/reports/${reportId}/action`, { status, adminNote })
  clearApiCache()
}

// ─────────────────────────────────────────────
//  Support Tickets  GET /api/admin/support/tickets
//  ticket.user.name  →  user.fullName
// ─────────────────────────────────────────────

export async function fetchSupportTickets(params?: {
  status?: string
  search?: string
  page?: number
  limit?: number
}): Promise<{ data: AdminSupportTicket[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/support/tickets', { params })
  const { data: raw, pagination } = response.data
  const data = (raw || []).map((t: any) => ({
    ...t,
    user: t.user
      ? { ...t.user, fullName: t.user.fullName ?? t.user.name ?? 'Unknown' }
      : undefined,
  }))
  return { data, pagination }
}

/** Reply to a support ticket — PATCH /api/admin/support/tickets/:id/reply */
export async function replyToSupportTicket(ticketId: string, adminReply: string): Promise<void> {
  await api.patch(`/admin/support/tickets/${ticketId}/reply`, { adminReply })
  clearApiCache()
}

// ─────────────────────────────────────────────
//  Categories  GET/POST/PUT/DELETE /api/admin/categories
// ─────────────────────────────────────────────

export async function fetchCategories(params?: {
  search?: string
  page?: number
  limit?: number
}): Promise<{ data: AdminCategory[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/categories', { params })
  const { data: raw, pagination } = response.data
  return { data: raw || [], pagination }
}

export async function createCategory(payload: { name: string; icon?: string }): Promise<void> {
  await api.post('/admin/categories', payload)
  clearApiCache()
}

export async function updateCategory(
  categoryId: string,
  payload: { name: string; icon?: string },
): Promise<void> {
  await api.put(`/admin/categories/${categoryId}`, payload)
  clearApiCache()
}

export async function deleteCategory(categoryId: string): Promise<void> {
  await api.delete(`/admin/categories/${categoryId}`)
  clearApiCache()
}

// ─────────────────────────────────────────────
//  Reviews  GET /api/admin/reviews
//  review has no author relation in backend currently — handle gracefully
// ─────────────────────────────────────────────

export async function fetchReviews(params?: {
  page?: number
  limit?: number
}): Promise<{ data: AdminReview[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/reviews', { params })
  const { data: raw, pagination } = response.data
  return { data: raw || [], pagination }
}

export async function deleteReview(reviewId: string, reason: string): Promise<void> {
  await api.delete(`/admin/reviews/${reviewId}`, { data: { reason } })
  clearApiCache()
}

// ─────────────────────────────────────────────
//  Public endpoints usable with admin token
// ─────────────────────────────────────────────

export async function fetchListingReviews(listingId: string, page = 1, limit = 20): Promise<AdminReview[]> {
  const response = await cachedGet(`/reviews/listing/${listingId}`, { params: { page, limit } })
  return response.data?.data ?? []
}

export async function fetchUserReviews(userId: string, page = 1, limit = 20): Promise<AdminReview[]> {
  const response = await cachedGet(`/reviews/user/${userId}`, { params: { page, limit } })
  return response.data?.data ?? []
}

export async function fetchPublicCategories(): Promise<AdminCategory[]> {
  const response = await cachedGet('/categories')
  return response.data?.data ?? []
}

// ─────────────────────────────────────────────
//  Phase 2 — Messaging Moderation
// ─────────────────────────────────────────────

export type FlaggedMessage = {
  id: string; content: string; senderId: string; receiverId: string
  flagReason?: string; createdAt?: string
  sender?: { fullName: string; email: string }
  receiver?: { fullName: string; email: string }
}

export async function fetchFlaggedMessages(params?: {
  page?: number
  limit?: number
}): Promise<{ data: FlaggedMessage[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/messages/flagged', { params }).catch(() => ({ data: { data: [], pagination: {} } }))
  return {
    data: response.data?.data ?? [],
    pagination: response.data?.pagination ?? {}
  }
}

export async function deleteMessage(messageId: string, reason: string): Promise<void> {
  await api.delete(`/admin/messages/${messageId}`, { data: { reason } })
  clearApiCache()
}

// ─────────────────────────────────────────────
//  Phase 2 — Broadcast & Campaigns
// ─────────────────────────────────────────────

export type BroadcastPayload = {
  title: string; body: string
  targetAudience: 'ALL' | 'VERIFIED' | 'UNVERIFIED' | 'OWNERS' | 'RENTERS'
  scheduledAt?: string
}

export type BroadcastRecord = BroadcastPayload & {
  id: string; sentCount?: number
  status?: 'DRAFT' | 'SENT' | 'SCHEDULED'; createdAt?: string
}

export async function fetchBroadcasts(params?: {
  page?: number
  limit?: number
}): Promise<{ data: BroadcastRecord[]; pagination: Pagination }> {
  const response = await cachedGet('/admin/broadcasts', { params }).catch(() => ({ data: { data: [], pagination: {} } }))
  return {
    data: response.data?.data ?? [],
    pagination: response.data?.pagination ?? {}
  }
}

export async function sendBroadcast(payload: BroadcastPayload): Promise<void> {
  await api.post('/admin/broadcasts', payload)
  clearApiCache()
}

// ─────────────────────────────────────────────
//  Phase 2 — Analytics
// ─────────────────────────────────────────────

export type AnalyticsData = {
  userGrowth?: Array<{ date: string; count: number }>
  listingGrowth?: Array<{ date: string; count: number }>
  bookingFunnel?: { created: number; accepted: number; completed: number; cancelled: number }
  topCategories?: Array<{ categoryName: string; listingCount: number }>
  geoDemand?: Array<{ city: string; country: string; listingCount: number }>
}

export async function fetchAnalytics(range: '7d' | '30d' | '90d' = '30d'): Promise<AnalyticsData> {
  const response = await cachedGet('/admin/analytics', { params: { range } })
    .catch(() => ({ data: { data: {} } }))
  return response.data?.data ?? {}
}
