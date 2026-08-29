const TOKEN_KEY = 'renthubindia_admin_token'
const ROLE_KEY = 'renthubindia_admin_role'

export function getAdminToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function setAdminToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token)
}

export function clearAdminToken(): void {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(ROLE_KEY)
}

export function setAdminRole(role: string): void {
  localStorage.setItem(ROLE_KEY, role)
}

export function getAdminRole(): string | null {
  return localStorage.getItem(ROLE_KEY)
}
