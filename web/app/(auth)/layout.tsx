/*
 * (auth)/layout.tsx
 * Authentication layout wrapping login and register pages — redirects already-
 * authenticated users to /dashboard, and renders a branding panel on large screens.
 */

"use client"

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { useAuth } from "@/contexts/auth"
import { Sparkles } from "lucide-react"

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!isLoading && isAuthenticated) router.replace("/dashboard") // skip auth pages for logged-in users
  }, [isAuthenticated, isLoading, router])

  if (isLoading) return (
    <div className="min-h-dvh flex items-center justify-center">
      <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center animate-pulse">
        <Sparkles size={14} className="text-white" />
      </div>
    </div>
  )

  return (
    <div className="min-h-dvh flex">
      {/* Left — branding panel */}
      <div className="hidden lg:flex lg:w-1/2 flex-col justify-between p-10 bg-[var(--color-surface)] border-r border-[var(--color-border)] relative overflow-hidden">
        {/* Ambient gradient */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_30%_20%,rgba(124,110,246,0.12)_0%,transparent_60%)] pointer-events-none" />

        <div className="relative flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center">
            <Sparkles size={16} className="text-white" />
          </div>
          <span className="font-semibold text-[var(--color-text-primary)]">Personal Finance Intelligence</span>
        </div>

        <div className="relative space-y-6">
          <div className="space-y-3">
            <h2 className="text-3xl font-bold text-[var(--color-text-primary)] leading-tight">
              Take control of your<br />
              <span className="text-[var(--color-accent-light)]">financial future</span>
            </h2>
            <p className="text-[var(--color-text-secondary)] leading-relaxed max-w-sm">
              Import bank statements, auto-categorise expenses with AI, track budgets, and get
              conversational financial insights — all in one place.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {[
              { stat: "₹0 subscriptions", label: "Always free" },
              { stat: "AI-powered", label: "GPT-4 / Gemini" },
              { stat: "Instant import", label: "Any bank CSV" },
              { stat: "Private data", label: "Your server" },
            ].map((item) => (
              <div key={item.stat} className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-3">
                <p className="text-sm font-semibold text-[var(--color-text-primary)]">{item.stat}</p>
                <p className="text-xs text-[var(--color-text-muted)]">{item.label}</p>
              </div>
            ))}
          </div>
        </div>

        <p className="relative text-xs text-[var(--color-text-muted)]">
          © 2025 Aayush Ramrakhyani · Personal Finance Intelligence
        </p>
      </div>

      {/* Right — form */}
      <div className="flex-1 flex items-center justify-center p-6 overflow-auto">
        {children}
      </div>
    </div>
  )
}
