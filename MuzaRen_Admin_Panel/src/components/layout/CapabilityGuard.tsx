import type { ReactNode } from 'react'
import { getAdminRole } from '../../services/authStorage'
import type { AdminRole } from '../../types/admin'
import type { AdminCapability } from '../../services/permissions'
import { can } from '../../services/permissions'

type CapabilityGuardProps = {
  capability: AdminCapability
  children: ReactNode
}

export function CapabilityGuard({ capability, children }: CapabilityGuardProps) {
  const role = getAdminRole() as AdminRole | null

  if (!can(role, capability)) {
    return (
      <section>
        <header className="page-header">
          <h2>Access denied</h2>
        </header>
        <p className="muted">Your current admin role does not have permission for this area.</p>
      </section>
    )
  }

  return children
}
