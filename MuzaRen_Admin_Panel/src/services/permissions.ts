import type { AdminRole } from '../types/admin'

export type AdminCapability =
  // Phase 1
  | 'dashboard:view'
  | 'users:manage'
  | 'listings:manage'
  | 'bookings:view'
  | 'reports:manage'
  | 'support:manage'
  | 'categories:manage'
  | 'reviews:manage'
  // Phase 2
  | 'finance:view'
  | 'messaging:moderate'
  | 'broadcast:send'
  | 'analytics:view'
  | 'cities:manage'

const roleCapabilities: Record<AdminRole, AdminCapability[]> = {
  SUPER_ADMIN: [
    'dashboard:view',
    'users:manage',
    'listings:manage',
    'bookings:view',
    'reports:manage',
    'support:manage',
    'categories:manage',
    'reviews:manage',
    'finance:view',
    'messaging:moderate',
    'broadcast:send',
    'analytics:view',
    'cities:manage',
  ],
  ADMIN: [
    'dashboard:view',
    'users:manage',
    'listings:manage',
    'bookings:view',
    'reports:manage',
    'support:manage',
    'categories:manage',
    'reviews:manage',
    'finance:view',
    'messaging:moderate',
    'broadcast:send',
    'analytics:view',
    'cities:manage',
  ],
  MODERATOR: [
    'dashboard:view',
    'users:manage',
    'listings:manage',
    'bookings:view',
    'reports:manage',
    'support:manage',
    'reviews:manage',
    'messaging:moderate',
  ],
}

export function can(role: AdminRole | null, capability: AdminCapability): boolean {
  if (!role) return false
  return roleCapabilities[role]?.includes(capability) ?? false
}
