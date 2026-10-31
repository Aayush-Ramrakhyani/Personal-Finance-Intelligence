/*
 * (app)/layout.tsx
 * Protected shell layout for all authenticated app routes — guards against
 * unauthenticated access by redirecting to /login, then renders Sidebar + Topbar.
 */

"use client"

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { useAuth } from "@/contexts/auth"
import { Sidebar } from "@/components/layout/sidebar"
import { Topbar } from "@/components/layout/topbar"
import { Sparkles } from "lucide-react"

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!isLoading && !isAuthenticated) router.replace("/login") // redirect unauthenticated users to login
  }, [isAuthenticated, isLoading, router])

  if (isLoading) {
    return (
      <div className="min-h-dvh flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center animate-pulse">
            <Sparkles size={18} className="text-white" />
          </div>
          <p className="text-sm text-[var(--color-text-muted)]">Loading…</p>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) return null // prevent flash of app shell before redirect completes

  return (
    <div className="flex h-dvh overflow-hidden">
      <Sidebar />
      <div className="flex flex-col flex-1 overflow-hidden">
        <Topbar />
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
