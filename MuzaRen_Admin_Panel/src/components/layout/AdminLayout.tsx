import { useState } from 'react'
import { Outlet } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import { TopBar } from './TopBar'

export function AdminLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false)

  return (
    <div className={`admin-shell ${isSidebarOpen ? 'sidebar-open' : ''}`}>
      <Sidebar isOpen={isSidebarOpen} onClose={() => setIsSidebarOpen(false)} />
      {/* Mobile overlay */}
      {isSidebarOpen && (
        <div 
          className="sidebar-overlay" 
          onClick={() => setIsSidebarOpen(false)} 
        />
      )}
      <div className="content-area">
        <TopBar onToggleSidebar={() => setIsSidebarOpen(!isSidebarOpen)} />
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
