/*
 * client.ts
 * Core API client — manages JWT token storage in localStorage, handles transparent
 * token refresh with a request queue, and exposes typed get/post/patch/delete helpers.
 */

"use client"

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1"

/* ─── Token storage ───────────────────────────────────────────────────────── */
const STORAGE_KEY_ACCESS  = "pfi_access_token"
const STORAGE_KEY_REFRESH = "pfi_refresh_token"

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem(STORAGE_KEY_ACCESS)
}
export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem(STORAGE_KEY_REFRESH)
}
export function setTokens(access: string, refresh: string): void {
  localStorage.setItem(STORAGE_KEY_ACCESS, access)
  localStorage.setItem(STORAGE_KEY_REFRESH, refresh)
}
export function clearTokens(): void {
  localStorage.removeItem(STORAGE_KEY_ACCESS)
  localStorage.removeItem(STORAGE_KEY_REFRESH)
}

/* ─── Refresh logic ───────────────────────────────────────────────────────── */
let isRefreshing = false
let refreshQueue: Array<(token: string | null) => void> = [] // pending requests waiting for a new token

async function refreshAccessToken(): Promise<string | null> {
  const refresh = getRefreshToken()
  if (!refresh) { clearTokens(); return null }

  if (isRefreshing) {
    return new Promise((resolve) => { refreshQueue.push(resolve) }) // coalesce concurrent refresh attempts into one request
  }

  isRefreshing = true
  try {
    const res = await fetch(`${BASE_URL}/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refresh }),
    })

    if (!res.ok) { clearTokens(); refreshQueue.forEach(cb => cb(null)); return null }

    const json = await res.json()
    const newAccess  = json.data?.access_token
    const newRefresh = json.data?.refresh_token ?? refresh

    if (newAccess) {
      setTokens(newAccess, newRefresh)
      refreshQueue.forEach(cb => cb(newAccess))
      return newAccess
    }
    clearTokens(); return null
  } finally {
    isRefreshing = false
    refreshQueue = []
  }
}

/* ─── Core fetch wrapper ──────────────────────────────────────────────────── */
interface FetchOptions extends RequestInit {
  params?: Record<string, string | number | boolean | undefined | null>
  retry?: boolean
}

export async function apiRequest<T>(
  path: string,
  options: FetchOptions = {}
): Promise<T> {
  const { params, retry = true, ...rest } = options

  let url = `${BASE_URL}${path}`
  if (params) {
    const search = new URLSearchParams()
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined && v !== null && v !== "") {
        search.set(k, String(v))
      }
    }
    const qs = search.toString()
    if (qs) url += `?${qs}`
  }

  const token = getAccessToken()
  const headers: Record<string, string> = {
    ...(rest.body instanceof FormData ? {} : { "Content-Type": "application/json" }),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(rest.headers ? Object.fromEntries(new Headers(rest.headers as HeadersInit)) : {}),
  }

  let response = await fetch(url, { ...rest, headers })

  if (response.status === 401 && retry) {
    const newToken = await refreshAccessToken() // silently refresh and replay the failed request once
    if (!newToken) {
      if (typeof window !== "undefined") window.location.href = "/login" // force re-login when refresh also fails
      throw new ApiRequestError("Session expired", 401)
    }
    headers["Authorization"] = `Bearer ${newToken}`
    response = await fetch(url, { ...rest, headers })
  }

  if (!response.ok) {
    let detail = ""
    try {
      const err = await response.json()
      detail = err?.detail ?? err?.message ?? ""
    } catch {}
    throw new ApiRequestError(
      detail || `Request failed: ${response.statusText}`,
      response.status
    )
  }

  if (response.status === 204) return undefined as T
  return response.json()
}

/* ─── Error class ─────────────────────────────────────────────────────────── */
export class ApiRequestError extends Error {
  constructor(message: string, public status: number) {
    super(message)
    this.name = "ApiRequestError"
  }
}

/* ─── Convenience methods ─────────────────────────────────────────────────── */
export const api = {
  get: <T>(path: string, params?: FetchOptions["params"]) =>
    apiRequest<T>(path, { method: "GET", params }),

  post: <T>(path: string, body?: unknown) =>
    apiRequest<T>(path, {
      method: "POST",
      body: body instanceof FormData ? body : JSON.stringify(body),
    }),

  patch: <T>(path: string, body?: unknown) =>
    apiRequest<T>(path, { method: "PATCH", body: JSON.stringify(body) }),

  delete: <T>(path: string) =>
    apiRequest<T>(path, { method: "DELETE" }),
}
