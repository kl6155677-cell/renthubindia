import { Navigate, Route, Routes } from 'react-router-dom'
import { AdminLayout } from './components/layout/AdminLayout'
import { CapabilityGuard } from './components/layout/CapabilityGuard'
import { ProtectedRoute } from './components/layout/ProtectedRoute'
import { AnalyticsPage } from './pages/AnalyticsPage'
import { BookingsPage } from './pages/BookingsPage'
import { BroadcastPage } from './pages/BroadcastPage'
import { CategoriesPage } from './pages/CategoriesPage'
import { DashboardPage } from './pages/DashboardPage'
import { FinancePage } from './pages/FinancePage'
import { ListingsPage } from './pages/ListingsPage'
import { LoginPage } from './pages/LoginPage'
import { MessagingPage } from './pages/MessagingPage'
import { ReportsPage } from './pages/ReportsPage'
import { ReviewsPage } from './pages/ReviewsPage'
import { SupportPage } from './pages/SupportPage'
import { UsersPage } from './pages/UsersPage'
import { CitiesPage } from './pages/CitiesPage'

function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />

        {/* ── Phase 1 ── */}
        <Route
          path="dashboard"
          element={
            <CapabilityGuard capability="dashboard:view">
              <DashboardPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="users"
          element={
            <CapabilityGuard capability="users:manage">
              <UsersPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="listings"
          element={
            <CapabilityGuard capability="listings:manage">
              <ListingsPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="bookings"
          element={
            <CapabilityGuard capability="bookings:view">
              <BookingsPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="reports"
          element={
            <CapabilityGuard capability="reports:manage">
              <ReportsPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="reviews"
          element={
            <CapabilityGuard capability="reviews:manage">
              <ReviewsPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="support"
          element={
            <CapabilityGuard capability="support:manage">
              <SupportPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="categories"
          element={
            <CapabilityGuard capability="categories:manage">
              <CategoriesPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="cities"
          element={
            <CapabilityGuard capability="cities:manage">
              <CitiesPage />
            </CapabilityGuard>
          }
        />

        {/* ── Phase 2 ── */}
        <Route
          path="finance"
          element={
            <CapabilityGuard capability="finance:view">
              <FinancePage />
            </CapabilityGuard>
          }
        />
        <Route
          path="messaging"
          element={
            <CapabilityGuard capability="messaging:moderate">
              <MessagingPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="broadcast"
          element={
            <CapabilityGuard capability="broadcast:send">
              <BroadcastPage />
            </CapabilityGuard>
          }
        />
        <Route
          path="analytics"
          element={
            <CapabilityGuard capability="analytics:view">
              <AnalyticsPage />
            </CapabilityGuard>
          }
        />
      </Route>
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}

export default App
