import { useState } from 'react';
import {
  LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  Legend, ResponsiveContainer
} from 'recharts';
import MetricCard    from '../../components/analytics/MetricCard';
import ChartCard     from '../../components/analytics/ChartCard';
import PeriodSelector from '../../components/analytics/PeriodSelector';
import LoadingChart  from '../../components/analytics/LoadingChart';
import { useAnalytics } from '../../hooks/useAnalytics';
import { analyticsApi } from '../../api/analyticsApi';

const TEAL   = '#0D6E75';
const AMBER  = '#F5A623';
const GREEN  = '#16A34A';
const RED    = '#DC2626';
const PURPLE = '#7C3AED';
const BLUE   = '#2563EB';

const PIE_COLORS = [TEAL, AMBER, GREEN, RED, PURPLE, BLUE,
                    '#F59E0B', '#10B981', '#6366F1', '#EC4899'];

const TABS = [
  { id: 'overview',    label: '📊 Overview'   },
  { id: 'users',       label: '👥 Users'      },
  { id: 'listings',    label: '📦 Listings'   },
  { id: 'bookings',    label: '📅 Bookings'   },
  { id: 'revenue',     label: '💰 Revenue'    },
  { id: 'engagement',  label: '💬 Engagement' },
];

export default function AnalyticsPage() {
  const [activeTab, setActiveTab] = useState('overview');
  const [period,    setPeriod]    = useState('30d');

  return (
    <div className="p-6">
      {/* Page Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
          <p className="text-sm text-gray-500 mt-1">
            Platform performance and insights
          </p>
        </div>
        <PeriodSelector value={period} onChange={setPeriod} />
      </div>

      {/* Tab Navigation */}
      <div className="flex gap-1 mb-6 border-b border-gray-200 overflow-x-auto">
        {TABS.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`
              px-4 py-2.5 text-sm font-medium border-b-2 transition-colors -mb-px whitespace-nowrap
              ${activeTab === tab.id
                ? 'border-[#0D6E75] text-[#0D6E75]'
                : 'border-transparent text-gray-500 hover:text-gray-700'
              }
            `}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'overview'   && <OverviewTab   period={period} />}
      {activeTab === 'users'      && <UsersTab       period={period} />}
      {activeTab === 'listings'   && <ListingsTab    period={period} />}
      {activeTab === 'bookings'   && <BookingsTab    period={period} />}
      {activeTab === 'revenue'    && <RevenueTab     period={period} />}
      {activeTab === 'engagement' && <EngagementTab  period={period} />}
    </div>
  );
}

// ── OVERVIEW TAB ──────────────────────────────────────────────
function OverviewTab({ period }) {
  const { data, isLoading } = useAnalytics(
    analyticsApi.getOverview, { period }, [period]
  );

  return (
    <div className="space-y-6">
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          label="Total Users"
          value={data?.kpis?.totalUsers?.value ?? '—'}
          growth={data?.kpis?.totalUsers?.growth}
          sublabel={`${data?.kpis?.totalUsers?.new ?? 0} new this period`}
          icon="👥"
        />
        <MetricCard
          label="Total Listings"
          value={data?.kpis?.totalListings?.value ?? '—'}
          growth={data?.kpis?.totalListings?.growth}
          sublabel={`${data?.kpis?.totalListings?.new ?? 0} new this period`}
          icon="📦"
          color={AMBER}
        />
        <MetricCard
          label="Total Bookings"
          value={data?.kpis?.totalBookings?.value ?? '—'}
          growth={data?.kpis?.totalBookings?.growth}
          sublabel={`${data?.kpis?.totalBookings?.new ?? 0} new this period`}
          icon="📅"
          color={GREEN}
        />
        <MetricCard
          label="Active Listings"
          value={data?.kpis?.activeListings?.value ?? '—'}
          icon="✅"
          color={PURPLE}
        />
      </div>

      {/* Alerts Row */}
      {data?.alerts && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <AlertCard
            label="Pending Verifications"
            value={data.alerts.pendingVerifications}
            color="amber"
            href="/admin/users?verificationStatus=PENDING"
          />
          <AlertCard
            label="Open Reports"
            value={data.alerts.openReports}
            color="red"
            href="/admin/reports?status=OPEN"
          />
          <AlertCard
            label="Open Support Tickets"
            value={data.alerts.openTickets}
            color="blue"
            href="/admin/support?status=OPEN"
          />
        </div>
      )}

      {/* Booking Health */}
      {data?.bookingHealth && (
        <ChartCard
          title="Booking Health"
          subtitle={`Completion rate: ${data.bookingHealth.completionRate}%`}
        >
          <div className="grid grid-cols-3 gap-6 py-2">
            <div className="text-center">
              <p className="text-3xl font-bold text-green-600">
                {data.bookingHealth.completed}
              </p>
              <p className="text-sm text-gray-500 mt-1">Completed</p>
            </div>
            <div className="text-center">
              <p className="text-3xl font-bold text-red-500">
                {data.bookingHealth.cancelled}
              </p>
              <p className="text-sm text-gray-500 mt-1">Cancelled</p>
            </div>
            <div className="text-center">
              <p className="text-3xl font-bold text-[#0D6E75]">
                {data.bookingHealth.completionRate}%
              </p>
              <p className="text-sm text-gray-500 mt-1">Completion Rate</p>
            </div>
          </div>
        </ChartCard>
      )}
    </div>
  );
}

// ── USERS TAB ────────────────────────────────────────────────
function UsersTab({ period }) {
  const { data, isLoading } = useAnalytics(
    analyticsApi.getUsers, { period }, [period]
  );

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* User Growth Chart */}
        <ChartCard title="User Growth" subtitle="New registrations over time">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={data?.userGrowthChart || []}>
                <defs>
                  <linearGradient id="userGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor={TEAL} stopOpacity={0.2} />
                    <stop offset="95%" stopColor={TEAL} stopOpacity={0}   />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Area type="monotone" dataKey="count"
                  stroke={TEAL} fill="url(#userGrad)"
                  strokeWidth={2} name="New Users" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Verification Funnel */}
        <ChartCard title="Verification Funnel" subtitle="User identity verification status">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={[
                { name: 'Unverified', value: data?.verificationFunnel?.UNVERIFIED || 0 },
                { name: 'Pending',    value: data?.verificationFunnel?.PENDING    || 0 },
                { name: 'Verified',   value: data?.verificationFunnel?.VERIFIED   || 0 },
              ]}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                  <Cell fill={RED}   />
                  <Cell fill={AMBER} />
                  <Cell fill={GREEN} />
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Top Countries */}
        <ChartCard title="Users by Country" subtitle="Top 10 countries">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart
                data={data?.topCountries || []}
                layout="vertical"
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 11 }} />
                <YAxis dataKey="country" type="category"
                  tick={{ fontSize: 11 }} width={60} />
                <Tooltip />
                <Bar dataKey="count" fill={TEAL} radius={[0, 6, 6, 0]} name="Users" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Active vs Blocked */}
        <ChartCard title="User Status" subtitle="Active vs blocked accounts">
          {isLoading ? <LoadingChart height={280} /> : (
            <div className="flex items-center justify-center h-[280px]">
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie
                    data={[
                      { name: 'Active',  value: (data?.kpis?.totalUsers?.value || 0) - (data?.blockedUsers || 0) },
                      { name: 'Blocked', value: data?.blockedUsers || 0 },
                    ]}
                    cx="50%" cy="50%"
                    innerRadius={60} outerRadius={90}
                    paddingAngle={4}
                    dataKey="value"
                    label={({ name, percent }) =>
                      `${name} ${(percent * 100).toFixed(0)}%`
                    }
                  >
                    <Cell fill={TEAL} />
                    <Cell fill={RED}  />
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </ChartCard>
      </div>
    </div>
  );
}

// ── LISTINGS TAB ─────────────────────────────────────────────
function ListingsTab({ period }) {
  const { data, isLoading } = useAnalytics(
    analyticsApi.getListings, { period }, [period]
  );

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Listing Growth */}
        <ChartCard title="Listing Growth" subtitle="New listings over time">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={data?.listingGrowthChart || []}>
                <defs>
                  <linearGradient id="listingGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor={AMBER} stopOpacity={0.2} />
                    <stop offset="95%" stopColor={AMBER} stopOpacity={0}   />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Area type="monotone" dataKey="count"
                  stroke={AMBER} fill="url(#listingGrad)"
                  strokeWidth={2} name="New Listings" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Category Breakdown */}
        <ChartCard title="Listings by Category" subtitle="Top 10 categories">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={data?.categoryBreakdown || []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 11 }} />
                <YAxis dataKey="category" type="category"
                  tick={{ fontSize: 10 }} width={80} />
                <Tooltip />
                <Bar dataKey="count" fill={TEAL} radius={[0, 6, 6, 0]} name="Listings" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Status Breakdown */}
        <ChartCard title="Listing Status" subtitle="Current listing status distribution">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={[
                    { name: 'Active',  value: data?.statusBreakdown?.ACTIVE  || 0 },
                    { name: 'Paused',  value: data?.statusBreakdown?.PAUSED  || 0 },
                    { name: 'Expired', value: data?.statusBreakdown?.EXPIRED || 0 },
                  ]}
                  cx="50%" cy="50%"
                  outerRadius={90} paddingAngle={4}
                  dataKey="value"
                  label={({ name, percent }) =>
                    `${name} ${(percent * 100).toFixed(0)}%`
                  }
                >
                  <Cell fill={GREEN} />
                  <Cell fill={AMBER} />
                  <Cell fill={RED}   />
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Avg Price by Category */}
        <ChartCard title="Average Price/Day by Category"
          subtitle="Which categories command the highest prices">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={data?.avgPriceChart || []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 11 }}
                  tickFormatter={v => `$${v}`} />
                <YAxis dataKey="category" type="category"
                  tick={{ fontSize: 10 }} width={80} />
                <Tooltip formatter={v => [`$${v}`, 'Avg Price/Day']} />
                <Bar dataKey="avgPrice" fill={PURPLE}
                  radius={[0, 6, 6, 0]} name="Avg Price" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </div>
    </div>
  );
}

// ── BOOKINGS TAB ─────────────────────────────────────────────
function BookingsTab({ period }) {
  const { data, isLoading } = useAnalytics(
    analyticsApi.getBookings, { period }, [period]
  );

  return (
    <div className="space-y-6">
      {/* Metrics Row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Completion Rate"
          value={data?.completionRate ?? '—'} suffix="%" icon="✅" color={GREEN} />
        <MetricCard label="Cancellation Rate"
          value={data?.cancellationRate ?? '—'} suffix="%" icon="❌" color={RED} />
        <MetricCard label="Avg Duration"
          value={data?.avgDuration ?? '—'} suffix=" days" icon="📆" color={TEAL} />
        <MetricCard label="Avg Booking Value"
          value={data?.avgBookingValue ?? '—'} prefix="$" icon="💵" color={AMBER} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Booking Growth */}
        <ChartCard title="Booking Trends" subtitle="New bookings over time">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={data?.bookingGrowthChart || []}>
                <defs>
                  <linearGradient id="bookingGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor={GREEN} stopOpacity={0.2} />
                    <stop offset="95%" stopColor={GREEN} stopOpacity={0}   />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Area type="monotone" dataKey="count"
                  stroke={GREEN} fill="url(#bookingGrad)"
                  strokeWidth={2} name="Bookings" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Status Funnel */}
        <ChartCard title="Booking Status Funnel"
          subtitle="Where bookings end up">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={[
                { name: 'Pending',   value: data?.statusFunnel?.PENDING   || 0 },
                { name: 'Accepted',  value: data?.statusFunnel?.ACCEPTED  || 0 },
                { name: 'Completed', value: data?.statusFunnel?.COMPLETED || 0 },
                { name: 'Cancelled', value: data?.statusFunnel?.CANCELLED || 0 },
              ]}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                  <Cell fill={AMBER} />
                  <Cell fill={TEAL}  />
                  <Cell fill={GREEN} />
                  <Cell fill={RED}   />
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Bookings by Day of Week */}
        <ChartCard title="Bookings by Day of Week"
          subtitle="When do renters book most?">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={data?.bookingsByDay || []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="day" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="count" fill={TEAL}
                  radius={[6, 6, 0, 0]} name="Bookings" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Top Booked Categories */}
        <ChartCard title="Most Booked Categories"
          subtitle="Top categories by booking count">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={data?.topCategories || []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 11 }} />
                <YAxis dataKey="category" type="category"
                  tick={{ fontSize: 10 }} width={80} />
                <Tooltip />
                <Bar dataKey="count" fill={AMBER}
                  radius={[0, 6, 6, 0]} name="Bookings" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </div>
    </div>
  );
}

// ── REVENUE TAB ──────────────────────────────────────────────
function RevenueTab({ period }) {
  const { data, isLoading } = useAnalytics(
    analyticsApi.getRevenue, { period }, [period]
  );

  return (
    <div className="space-y-6">
      {/* Revenue KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard label="Total Booking Value"
          value={data?.totalRevenue ?? '—'}
          growth={data?.revenueGrowth}
          prefix="$" icon="💰" color={GREEN} />
        <MetricCard label="Avg per Booking"
          value={data?.avgRevenuePerBooking ?? '—'}
          prefix="$" icon="📊" color={TEAL} />
        <MetricCard label="Revenue Growth"
          value={data?.revenueGrowth ?? '—'}
          suffix="%" icon="📈" color={AMBER} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Over Time */}
        <div className="lg:col-span-2">
          <ChartCard title="Revenue Trend" subtitle="Total booking value over time">
            {isLoading ? <LoadingChart height={320} /> : (
              <ResponsiveContainer width="100%" height={320}>
                <AreaChart data={data?.revenueChart || []}>
                  <defs>
                    <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%"  stopColor={GREEN} stopOpacity={0.2} />
                      <stop offset="95%" stopColor={GREEN} stopOpacity={0}   />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 11 }} tickFormatter={v => `$${v}`} />
                  <Tooltip formatter={v => [`$${v}`, 'Revenue']} />
                  <Area type="monotone" dataKey="revenue"
                    stroke={GREEN} fill="url(#revenueGrad)"
                    strokeWidth={2} name="Revenue" />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </ChartCard>
        </div>

        {/* Revenue by Category */}
        <ChartCard title="Revenue by Category"
          subtitle="Which categories generate most value">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={data?.revenueByCategoryChart || []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 11 }}
                  tickFormatter={v => `$${v}`} />
                <YAxis dataKey="category" type="category"
                  tick={{ fontSize: 10 }} width={80} />
                <Tooltip formatter={v => [`$${v}`, 'Revenue']} />
                <Bar dataKey="revenue" fill={GREEN}
                  radius={[0, 6, 6, 0]} name="Revenue" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Revenue by Country */}
        <ChartCard title="Revenue by Country"
          subtitle="Top countries by booking value">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={data?.revenueByCountryChart || []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 11 }}
                  tickFormatter={v => `$${v}`} />
                <YAxis dataKey="country" type="category"
                  tick={{ fontSize: 10 }} width={50} />
                <Tooltip formatter={v => [`$${v}`, 'Revenue']} />
                <Bar dataKey="revenue" fill={PURPLE}
                  radius={[0, 6, 6, 0]} name="Revenue" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </div>

      {/* Top Earning Listings Table */}
      <ChartCard title="Top Earning Listings" subtitle="Listings with highest total booking value">
        {isLoading ? <LoadingChart height={200} /> : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100">
                  <th className="text-left py-2 text-gray-500 font-medium">Listing</th>
                  <th className="text-right py-2 text-gray-500 font-medium">Price/Day</th>
                  <th className="text-right py-2 text-gray-500 font-medium">Bookings</th>
                  <th className="text-right py-2 text-gray-500 font-medium">Total Value</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {(data?.topListings || []).map((listing, i) => (
                  <tr key={listing.id} className="hover:bg-gray-50">
                    <td className="py-2.5 font-medium text-gray-900">
                      <span className="text-gray-400 mr-2">#{i + 1}</span>
                      {listing.title}
                    </td>
                    <td className="py-2.5 text-right text-gray-600">
                      ${listing.pricePerDay}/day
                    </td>
                    <td className="py-2.5 text-right text-gray-600">
                      {listing.bookings}
                    </td>
                    <td className="py-2.5 text-right font-semibold text-green-600">
                      ${listing.totalRevenue.toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </ChartCard>
    </div>
  );
}

// ── ENGAGEMENT TAB ───────────────────────────────────────────
function EngagementTab({ period }) {
  const { data, isLoading } = useAnalytics(
    analyticsApi.getEngagement, { period }, [period]
  );

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Total Messages"
          value={data?.chat?.totalMessages ?? '—'} icon="💬" color={TEAL} />
        <MetricCard label="Avg Rating"
          value={data?.reviews?.avgRating ?? '—'} icon="⭐" color={AMBER} />
        <MetricCard label="Report Resolution"
          value={data?.reports?.reportResolutionRate ?? '—'}
          suffix="%" icon="🛡️" color={GREEN} />
        <MetricCard label="Ticket Resolution"
          value={data?.support?.ticketResolutionRate ?? '—'}
          suffix="%" icon="🎫" color={PURPLE} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Rating Distribution */}
        <ChartCard title="Rating Distribution"
          subtitle="How users rate their rental experiences">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={data?.reviews?.ratingDistribution || []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="rating" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="count" fill={AMBER}
                  radius={[6, 6, 0, 0]} name="Reviews" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Reports by Category */}
        <ChartCard title="Reports by Category"
          subtitle="Types of reports submitted by users">
          {isLoading ? <LoadingChart /> : (
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={data?.reports?.byCategory || []}
                  cx="50%" cy="50%"
                  outerRadius={90}
                  dataKey="count"
                  nameKey="category"
                  label={({ category, percent }) =>
                    `${category} ${(percent * 100).toFixed(0)}%`
                  }
                >
                  {(data?.reports?.byCategory || []).map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Support Metrics */}
        <ChartCard title="Support Performance"
          subtitle="Ticket resolution metrics">
          {isLoading ? <LoadingChart /> : (
            <div className="space-y-4 py-2">
              {[
                { label: 'Total Tickets',       value: data?.support?.totalTickets     || 0 },
                { label: 'Resolved Tickets',     value: data?.support?.resolvedTickets  || 0 },
                { label: 'Avg Resolution Time',  value: `${data?.support?.avgResolutionHours || 0}h` },
                { label: 'Resolution Rate',      value: `${data?.support?.ticketResolutionRate || 0}%` },
              ].map(item => (
                <div key={item.label}
                  className="flex items-center justify-between py-2
                             border-b border-gray-50 last:border-0">
                  <span className="text-sm text-gray-500">{item.label}</span>
                  <span className="text-sm font-semibold text-gray-900">{item.value}</span>
                </div>
              ))}
            </div>
          )}
        </ChartCard>

        {/* Chat Metrics */}
        <ChartCard title="Chat Engagement"
          subtitle="Messaging activity metrics">
          {isLoading ? <LoadingChart /> : (
            <div className="space-y-4 py-2">
              {[
                { label: 'Total Chats Started', value: data?.chat?.totalChats       || 0 },
                { label: 'Total Messages Sent',  value: data?.chat?.totalMessages    || 0 },
                { label: 'Avg Messages/Chat',    value: data?.chat?.avgMessagesPerChat || 0 },
              ].map(item => (
                <div key={item.label}
                  className="flex items-center justify-between py-2
                             border-b border-gray-50 last:border-0">
                  <span className="text-sm text-gray-500">{item.label}</span>
                  <span className="text-sm font-semibold text-gray-900">
                    {typeof item.value === 'number'
                      ? item.value.toLocaleString() : item.value}
                  </span>
                </div>
              ))}
            </div>
          )}
        </ChartCard>
      </div>
    </div>
  );
}

// ── ALERT CARD ───────────────────────────────────────────────
function AlertCard({ label, value, color, href }) {
  const colors = {
    amber: { bg: '#FFFBEB', text: '#D97706', border: '#FDE68A' },
    red:   { bg: '#FEF2F2', text: '#DC2626', border: '#FECACA' },
    blue:  { bg: '#EFF6FF', text: '#2563EB', border: '#BFDBFE' },
  };
  const c = colors[color] || colors.blue;

  return (
    <a href={href}
      className="block rounded-xl p-4 border transition-transform hover:scale-105"
      style={{ backgroundColor: c.bg, borderColor: c.border }}
    >
      <p className="text-2xl font-bold" style={{ color: c.text }}>
        {value}
      </p>
      <p className="text-sm mt-1" style={{ color: c.text }}>{label}</p>
      <p className="text-xs mt-2 opacity-70" style={{ color: c.text }}>
        Click to view →
      </p>
    </a>
  );
}
