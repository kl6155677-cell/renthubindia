import axios from 'axios'
import { clearAdminToken, getAdminToken } from './authStorage'

// ─── Base URL resolution ───────────────────────────────────────────────────────
const envBaseUrl = import.meta.env.VITE_API_BASE_URL ?? import.meta.env.BASE_URL

const normalizedBaseUrl = envBaseUrl
  ? envBaseUrl.startsWith('http')
    ? envBaseUrl
    : `https://${envBaseUrl}`
  : undefined

const baseURL = normalizedBaseUrl?.endsWith('/api')
  ? normalizedBaseUrl
  : `${normalizedBaseUrl ?? 'http://localhost:5000'}/api`

// ─── Debug flag: enable/disable in console with window.__ADMIN_DEBUG__ ─────────
const isDev = import.meta.env.DEV

function debugLog(label: string, color: string, ...args: unknown[]) {
  if (isDev || (window as Window & { __ADMIN_DEBUG__?: boolean }).__ADMIN_DEBUG__) {
    console.groupCollapsed(`%c[AdminAPI] ${label}`, `color:${color}; font-weight:bold`)
    args.forEach((a) => console.log(a))
    console.groupEnd()
  }
}

// Log the resolved base URL once on startup
debugLog(`Base URL → ${baseURL}`, '#0D6E75')

// ─── Axios instance ────────────────────────────────────────────────────────────
export const api = axios.create({
  baseURL,
  timeout: 15000,
})

// ─── REQUEST interceptor ──────────────────────────────────────────────────────
api.interceptors.request.use(
  (config) => {
    const token = getAdminToken()
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    debugLog(
      `▶ ${config.method?.toUpperCase()} ${config.baseURL}${config.url}`,
      '#3b82f6',
      {
        url:     `${config.baseURL}${config.url}`,
        method:  config.method?.toUpperCase(),
        headers: { Authorization: token ? 'Bearer [token]' : 'none' },
        params:  config.params  ?? '—',
        body:    config.data    ?? '—',
      },
    )

    return config
  },
  (error) => {
    console.error('[AdminAPI] ✖ Request setup error:', error)
    return Promise.reject(error)
  },
)

// ─── RESPONSE interceptor ─────────────────────────────────────────────────────
api.interceptors.response.use(
  (response) => {
    debugLog(
      `✔ ${response.status} ${response.config.method?.toUpperCase()} ${response.config.url}`,
      '#22c55e',
      {
        status:  response.status,
        success: response.data?.success,
        data:    response.data?.data ?? response.data,
      },
    )
    return response
  },
  (error) => {
    const status   = error?.response?.status
    const url      = error?.config?.url
    const method   = error?.config?.method?.toUpperCase()
    const resBody  = error?.response?.data
    const isNetwork = !error?.response

    // Print a clear, coloured error in the console
    console.group(`%c[AdminAPI] ✖ ERROR — ${method} ${url}`, 'color:#ef4444; font-weight:bold')

    if (isNetwork) {
      console.error('❌ Network error — backend is unreachable or CORS blocked.')
      console.info('💡 Check: Is the backend running? Is CORS configured to allow this origin?')
      console.info('   Current API base URL:', baseURL)
    } else {
      console.error(`HTTP ${status}`, resBody?.message ?? resBody)

      if (status === 401) {
        console.info('💡 Token missing, expired, or blacklisted. Redirecting to login…')
        clearAdminToken()
      }
      if (status === 403) {
        console.warn('💡 Forbidden — token is valid but role does not have permission for this route.')
        console.warn('   Your role:', getAdminToken() ? '[token present]' : '[no token]')
        console.warn('   Backend response:', resBody)
      }
      if (status === 400) {
        console.warn('💡 Validation error — check the request payload:')
        if (Array.isArray(resBody?.errors)) {
          resBody.errors.forEach((e: { field: string; message: string }) => {
            console.warn(`   ❌ Field "${e.field}": ${e.message}`)
          })
        } else {
          console.warn('   Response body:', resBody)
        }
      }
      if (status === 404) {
        console.warn('💡 Not found — this record may have been deleted or the ID is wrong.')
      }
      if (status === 409) {
        console.warn('💡 Conflict — a record with this data already exists (e.g. duplicate category name/slug).')
      }
      if (status === 500) {
        console.error('💡 Server error — check backend logs for the full stack trace.')
      }
    }

    console.groupEnd()
    return Promise.reject(error)
  },
)

// ─── CACHING LAYER ────────────────────────────────────────────────────────────

const CACHE_PREFIX = 'admin_cache_'
const DEFAULT_TTL_MS = 5 * 60 * 1000 // 5 minutes

export const clearApiCache = () => {
  try {
    const keys = Object.keys(localStorage)
    keys.forEach((key) => {
      if (key.startsWith(CACHE_PREFIX)) {
        localStorage.removeItem(key)
      }
    })
    debugLog('🗑 Cache cleared', '#8b5cf6')
  } catch (err) {
    console.error('Failed to clear cache', err)
  }
}

export const cachedGet = async (url: string, config?: any) => {
  const cacheKey = `${CACHE_PREFIX}${url}_${JSON.stringify(config?.params || {})}`
  
  try {
    const cachedItem = localStorage.getItem(cacheKey)
    if (cachedItem) {
      const parsed = JSON.parse(cachedItem)
      if (Date.now() - parsed.timestamp < DEFAULT_TTL_MS) {
        debugLog(`⚡ CACHE HIT: ${url}`, '#8b5cf6', { params: config?.params ?? '—' })
        // Return a mock AxiosResponse structure
        return { data: parsed.data } as any
      }
      // Cache expired
      localStorage.removeItem(cacheKey)
    }
  } catch (err) {
    // If JSON parsing fails or localStorage is blocked, ignore and just fetch
  }

  // Fetch from network
  const response = await api.get(url, config)
  
  try {
    // Only cache successful GET requests
    if (response.status >= 200 && response.status < 300) {
      localStorage.setItem(cacheKey, JSON.stringify({
        timestamp: Date.now(),
        data: response.data
      }))
    }
  } catch (err) {
    // Ignore, e.g., QuotaExceededError
  }
  
  return response
}
