// ─────────────────────────────────────────────
//  Core primitives
// ─────────────────────────────────────────────

/** Roles that exist in the Prisma UserRole enum: USER | ADMIN.
 * SUPER_ADMIN and MODERATOR are used by the admin panel UI permissions layer
 * but require a DB migration to be stored. */
export type AdminRole = 'SUPER_ADMIN' | 'MODERATOR' | 'ADMIN'

export type VerificationStatus = 'UNVERIFIED' | 'PENDING' | 'VERIFIED' | 'REJECTED'

export type BookingStatus = 'PENDING' | 'ACCEPTED' | 'COMPLETED' | 'CANCELLED'

export type ReportCategory = 'FRAUD' | 'SPAM' | 'ABUSE' | 'FAKE_LISTING'

export type ReportTargetType = 'LISTING' | 'USER' | 'MESSAGE'

export type ReportStatus = 'OPEN' | 'REVIEWED' | 'RESOLVED'

export type TicketStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED'

export interface Pagination {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
  from: number;
  to: number;
}

// ─────────────────────────────────────────────
//  Dashboard
// ─────────────────────────────────────────────

export type DashboardStats = {
  totalUsers: number
  totalListings: number
  totalBookings: number
  openReports: number
  pendingVerifications: number
  openSupportTickets: number
  recentActivity?: { date: string; count: number }[]
  userGrowth?: number
  listingGrowth?: number
  bookingGrowth?: number
  newUsers7d?: number
  newListings7d?: number
  bookingCompletionRate7d?: number
  bookingCancellationRate7d?: number
}

// ─────────────────────────────────────────────
//  Users
// ─────────────────────────────────────────────

export type AdminUser = {
  id: string
  fullName: string
  email: string
  role: string
  phone?: string
  city?: string
  isBlocked: boolean
  verificationStatus: VerificationStatus | string
  createdAt?: string
  listingsCount?: number
  bookingsAsRenterCount?: number
  bookingsAsOwnerCount?: number
  reportsAgainstCount?: number
}

// ─────────────────────────────────────────────
//  Listings
// ─────────────────────────────────────────────

export type AdminListing = {
  id: string
  title: string
  description?: string
  city: string
  country: string
  pricePerDay: number
  status: string
  isApproved: boolean
  reportCount?: number
  images?: string[]
  owner?: {
    id?: string
    fullName: string
    email: string
  }
  category?: {
    id?: string
    name: string
  }
  createdAt?: string
}

// ─────────────────────────────────────────────
//  Reports
// ─────────────────────────────────────────────

export type AdminReport = {
  id: string
  targetType: ReportTargetType | string
  targetId?: string
  category: ReportCategory | string
  description: string
  status: ReportStatus | string
  adminNote?: string
  reporter?: {
    id?: string
    fullName: string
    email: string
  }
  createdAt?: string
}

// ─────────────────────────────────────────────
//  Support Tickets
// ─────────────────────────────────────────────

export type AdminSupportTicket = {
  id: string
  subject: string
  message: string
  status: TicketStatus | string
  adminReply?: string
  createdAt?: string
  user?: {
    id?: string
    fullName: string
    email: string
  }
}

// ─────────────────────────────────────────────
//  Categories
// ─────────────────────────────────────────────

/** Matches the Category model in schema.prisma exactly:
 * id, name, icon (required String), slug (required @unique String)
 * Note: no 'description' field exists in the DB */
export type AdminCategory = {
  id: string
  name: string
  icon: string       // required in DB
  slug: string       // required + unique in DB
  listingCount?: number
}

// ─────────────────────────────────────────────
//  Bookings
// ─────────────────────────────────────────────

export type AdminBooking = {
  id: string
  status: BookingStatus | string
  startDate?: string
  endDate?: string
  renter?: {
    id?: string
    fullName: string
    email: string
  }
  owner?: {
    id?: string
    fullName: string
    email: string
  }
  listing?: {
    id?: string
    title: string
    city?: string
    country?: string
  }
  relatedReportId?: string
  relatedTicketId?: string
}

// ─────────────────────────────────────────────
//  Reviews
// ─────────────────────────────────────────────

export type AdminReview = {
  id: string
  rating: number
  comment?: string
  createdAt?: string
  isFlagged?: boolean
  bookingId?: string
  listingId?: string
  reviewerId?: string
  revieweeId?: string
  /** Relation name in Prisma is 'reviewer' (not 'author') */
  reviewer?: {
    id?: string
    name?: string
    fullName?: string
    email?: string
  }
  reviewee?: {
    id?: string
    name?: string
    fullName?: string
    email?: string
  }
}

// ─────────────────────────────────────────────
//  Phase 2 — Flagged Messages
// ─────────────────────────────────────────────

export type FlaggedMessage = {
  id: string
  content: string
  senderId: string
  receiverId: string
  flagReason?: string
  createdAt?: string
  sender?: { fullName: string; email: string }
  receiver?: { fullName: string; email: string }
}

// ─────────────────────────────────────────────
//  Phase 2 — Broadcasts
// ─────────────────────────────────────────────

export type BroadcastAudience = 'ALL' | 'VERIFIED' | 'UNVERIFIED' | 'OWNERS' | 'RENTERS'

export type BroadcastStatus = 'DRAFT' | 'SENT' | 'SCHEDULED'

export type BroadcastRecord = {
  id: string
  title: string
  body: string
  targetAudience: BroadcastAudience
  scheduledAt?: string
  sentCount?: number
  status?: BroadcastStatus
  createdAt?: string
}

// ─────────────────────────────────────────────
//  Phase 2 — Analytics
// ─────────────────────────────────────────────

export type AnalyticsTimePoint = { date: string; count: number }

export type BookingFunnel = {
  created: number
  accepted: number
  completed: number
  cancelled: number
}

export type CategoryStat = { categoryName: string; listingCount: number }

export type GeoStat = { city: string; country: string; listingCount: number }

export type AnalyticsData = {
  userGrowth?: AnalyticsTimePoint[]
  listingGrowth?: AnalyticsTimePoint[]
  bookingFunnel?: BookingFunnel
  topCategories?: CategoryStat[]
  geoDemand?: GeoStat[]
}
