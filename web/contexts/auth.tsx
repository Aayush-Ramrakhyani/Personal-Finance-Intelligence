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

const AuthContext = createContext<AuthState | null>(null)

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
      ? localStorage.getItem("pfi_access_token")
      : null

    if (token) {
      refreshUser().finally(() => setIsLoading(false))
    } else {
      setIsLoading(false)
    }
  }, [refreshUser])

  const login = async (data: LoginRequest) => {
    const res = await authApi.login(data)
    setTokens(res.data.access_token, res.data.refresh_token)
    setUser(res.data.user)
  }

  const register = async (data: RegisterRequest) => {
    const res = await authApi.register(data)
    setTokens(res.data.access_token, res.data.refresh_token)
    setUser(res.data.user)
  }

  const logout = () => {
    clearTokens()
    setUser(null)
    window.location.href = "/login"
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
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
