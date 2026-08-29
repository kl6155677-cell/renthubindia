import { useLocation } from 'react-router-dom'
import { getAdminRole } from '../../services/authStorage'

const routeTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/analytics': 'Analytics',
  '/users': 'Users',
  '/listings': 'Listings',
  '/bookings': 'Bookings',
  '/reports': 'Reports',
  '/reviews': 'Reviews',
  '/messaging': 'Messaging',
  '/support': 'Support Tickets',
  '/categories': 'Categories',
  '/broadcast': 'Broadcast',
  '/finance': 'Finance',
}

import { Menu } from 'lucide-react'

export function TopBar({ onToggleSidebar }: { onToggleSidebar: () => void }) {
  const location = useLocation()
  const title = routeTitles[location.pathname] || 'RentHubIndia Admin'
  const role = getAdminRole() || 'Admin'

  const initials = role === 'SUPER_ADMIN' ? 'SA' : role === 'MODERATOR' ? 'M' : 'A'

  return (
    <header className="topbar">
      <div className="topbar-left">
        <button className="mobile-toggle" onClick={onToggleSidebar}>
          <Menu size={20} />
        </button>
        <div className="topbar-titles">
          <span className="breadcrumb">Pages / {title}</span>
          <h2 className="page-title">{title}</h2>
        </div>
      </div>
      <div className="topbar-right">
        <div className="admin-avatar" title={`Logged in as ${role}`}>
          {initials}
        </div>
      </div>
    </header>
  )
}
