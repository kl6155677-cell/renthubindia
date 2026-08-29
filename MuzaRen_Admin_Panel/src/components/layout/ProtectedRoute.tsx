import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { getAdminToken } from '../../services/authStorage'

type ProtectedRouteProps = {
  children: ReactNode
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const location = useLocation()
  const token = getAdminToken()

  if (!token) {
    return <Navigate to="/login" state={{ from: location }} replace />
  }

  return children
}
