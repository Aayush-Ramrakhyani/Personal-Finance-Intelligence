/*
 * auth.tsx
 * React AuthContext and AuthProvider — persists JWT tokens in localStorage, exposes
 * login/register/logout actions and a refreshUser helper consumed by the whole app.
 */

"use client"

import React, { createContext, useContext, useEffect, useState, useCallback } from "react"
import { authApi } from "@/lib/api/auth"
import { setTokens, clearTokens } from "@/lib/api/client"
import type { User, LoginRequest, RegisterRequest } from "@/types"

interface AuthState {
  user: User | null
  isLoading: boolean
  isAuthenticated: boolean
  login: (data: LoginRequest) => Promise<void>
  register: (data: RegisterRequest) => Promise<void>
  logout: () => void
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null) // null default forces consumers to be inside AuthProvider

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser]       = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const refreshUser = useCallback(async () => {
    try {
      const res = await authApi.me()
      setUser(res.data)
    } catch {
      setUser(null)
      clearTokens()
    }
  }, [])

  useEffect(() => {
    const token = typeof window !== "undefined"
      ? localStorage.getItem("pfi_access_token") // SSR guard — localStorage not available on the server
      : null

    if (token) {
      refreshUser().finally(() => setIsLoading(false)) // validate stored token with /auth/me on mount
    } else {
      setIsLoading(false)
    }
  }, [refreshUser])

  const login = async (data: LoginRequest) => {
    const res = await authApi.login(data)
    setTokens(res.data.access_token, res.data.refresh_token) // persist tokens to localStorage
    setUser(res.data.user)
  }

  const register = async (data: RegisterRequest) => {
    const res = await authApi.register(data)
    setTokens(res.data.access_token, res.data.refresh_token) // immediately sign in after registration
    setUser(res.data.user)
  }

  const logout = () => {
    clearTokens() // remove tokens from localStorage before navigating away
    setUser(null)
    window.location.href = "/login"
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user, // derived boolean so consumers don't have to null-check user themselves
        login,
        register,
        logout,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be inside AuthProvider")
  return ctx
}
