import { useEffect } from 'react'
import { NavLink, useNavigate, useLocation } from 'react-router-dom'
import {
  LayoutDashboard,
  LineChart,
  Users,
  Tags,
  CalendarDays,
  Flag,
  Star,
  MessageSquare,
  Ticket,
  Package,
  Megaphone,
  CircleDollarSign,
  LogOut,
  Hexagon,
  MapPin,
  X
} from 'lucide-react'
import type { AdminCapability } from '../../services/permissions'
import { can } from '../../services/permissions'
import { clearAdminToken, getAdminRole } from '../../services/authStorage'
import type { AdminRole } from '../../types/admin'

type NavGroup = {
  group: string
  items: { to: string; label: string; icon: React.ReactNode; capability: AdminCapability }[]
}

const navGroups: NavGroup[] = [
  {
    group: 'Overview',
    items: [
      { to: '/dashboard', label: 'Dashboard', icon: <LayoutDashboard size={20} />, capability: 'dashboard:view' },
      { to: '/analytics', label: 'Analytics', icon: <LineChart size={20} />, capability: 'analytics:view' },
    ],
  },
  {
    group: 'Operations',
    items: [
      { to: '/users', label: 'Users', icon: <Users size={20} />, capability: 'users:manage' },
      { to: '/listings', label: 'Listings', icon: <Tags size={20} />, capability: 'listings:manage' },
      { to: '/bookings', label: 'Bookings', icon: <CalendarDays size={20} />, capability: 'bookings:view' },
    ],
  },
  {
    group: 'Trust & Safety',
    items: [
      { to: '/reports', label: 'Reports', icon: <Flag size={20} />, capability: 'reports:manage' },
      { to: '/reviews', label: 'Reviews', icon: <Star size={20} />, capability: 'reviews:manage' },
      { to: '/messaging', label: 'Messaging', icon: <MessageSquare size={20} />, capability: 'messaging:moderate' },
    ],
  },
  {
    group: 'Support',
    items: [
      { to: '/support', label: 'Support Tickets', icon: <Ticket size={20} />, capability: 'support:manage' },
    ],
  },
  {
    group: 'Catalog',
    items: [
      { to: '/categories', label: 'Categories', icon: <Package size={20} />, capability: 'categories:manage' },
      { to: '/cities', label: 'Cities', icon: <MapPin size={20} />, capability: 'cities:manage' },
    ],
  },
  {
    group: 'Growth',
    items: [
      { to: '/broadcast', label: 'Broadcast', icon: <Megaphone size={20} />, capability: 'broadcast:send' },
      { to: '/finance', label: 'Finance', icon: <CircleDollarSign size={20} />, capability: 'finance:view' },
    ],
  },
]

export function Sidebar({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const navigate = useNavigate()
  const location = useLocation()
  const role = getAdminRole() as AdminRole | null

  // Close sidebar on navigation (mobile)
  useEffect(() => {
    onClose()
  }, [location.pathname])

  const handleLogout = () => {
    clearAdminToken()
    navigate('/login')
  }

  return (
    <aside className={`sidebar ${isOpen ? 'open' : ''}`}>
      <div className="sidebar-brand">
        <div className="sidebar-brand-left">
          <span className="brand-logo"><Hexagon size={22} color="#fff" /></span>
          <div>
            <h1 className="brand">RentHubIndia</h1>
          </div>
        </div>
        <button className="sidebar-close" onClick={onClose}>
          <X size={20} />
        </button>
      </div>

      <nav className="nav-menu">
        {navGroups.map((group) => {
          const visibleItems = group.items.filter((item) => can(role, item.capability))
          if (visibleItems.length === 0) return null
          return (
            <div key={group.group} className="nav-group">
              <p className="nav-group-label">{group.group}</p>
              {visibleItems.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}
                >
                  <span className="nav-icon">{item.icon}</span>
                  {item.label}
                </NavLink>
              ))}
            </div>
          )
        })}
      </nav>

      <button className="logout-btn" type="button" onClick={handleLogout}>
        <span className="nav-icon"><LogOut size={20} /></span> Sign out
      </button>
    </aside>
  )
}
