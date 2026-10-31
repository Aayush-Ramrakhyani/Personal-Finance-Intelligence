/*
 * sidebar.tsx
 * Collapsible navigation sidebar — animates between expanded (220 px) and icon-only
 * (64 px) modes, highlights the active route, and exposes user info and logout.
 */

"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { motion, AnimatePresence } from "framer-motion"
import {
  LayoutDashboard, ArrowLeftRight, Upload, PiggyBank, BarChart3,
  Bot, Bell, Settings, LogOut, ChevronLeft, ChevronRight,
  Sparkles, User,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useAuth } from "@/contexts/auth"
import { spring, staggerContainer, staggerItem } from "@/lib/motion"

const navItems = [
  { href: "/dashboard",    icon: LayoutDashboard, label: "Dashboard"    },
  { href: "/transactions", icon: ArrowLeftRight,   label: "Transactions" },
  { href: "/import",       icon: Upload,           label: "Import CSV"   },
  { href: "/budgets",      icon: PiggyBank,        label: "Budgets"      },
  { href: "/analytics",    icon: BarChart3,        label: "Analytics"    },
  { href: "/ai",           icon: Bot,              label: "AI Assistant" },
  { href: "/notifications",icon: Bell,             label: "Alerts"       },
  { href: "/settings",     icon: Settings,         label: "Settings"     },
]

export function Sidebar() {
  const [expanded, setExpanded] = useState(true)
  const pathname = usePathname()
  const { user, logout } = useAuth()

  /* Collapse on mobile by default */
  useEffect(() => {
    const mq = window.matchMedia("(max-width: 1024px)")
    if (mq.matches) setExpanded(false) // start collapsed on mobile
    const handler = (e: MediaQueryListEvent) => { if (e.matches) setExpanded(false) }
    mq.addEventListener("change", handler) // re-collapse if viewport shrinks past breakpoint
    return () => mq.removeEventListener("change", handler)
  }, [])

  return (
    <motion.aside
      animate={{ width: expanded ? 220 : 64 }}
      transition={spring.smooth}
      className={cn(
        "relative flex flex-col h-full shrink-0 overflow-hidden",
        "border-r border-[var(--color-border)] bg-[var(--color-surface)]",
        "py-4"
      )}
    >
      {/* ── Logo ── */}
      <div className="flex items-center gap-3 px-4 mb-6 h-10">
        <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center shrink-0">
          <Sparkles size={14} className="text-white" />
        </div>
        <AnimatePresence>
          {expanded && (
            <motion.span
              initial={{ opacity: 0, x: -8 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -8 }}
              transition={{ duration: 0.15 }}
              className="font-semibold text-sm text-[var(--color-text-primary)] whitespace-nowrap truncate"
            >
              Finance AI
            </motion.span>
          )}
        </AnimatePresence>
      </div>

      {/* ── Nav items ── */}
      <motion.nav
        variants={staggerContainer(0.04)}
        initial="hidden"
        animate="visible"
        className="flex-1 flex flex-col gap-0.5 px-2"
      >
        {navItems.map((item) => {
          const active = pathname === item.href || pathname.startsWith(item.href + "/") // match nested routes like /transactions/:id
          return (
            <motion.div key={item.href} variants={staggerItem}>
              <Link href={item.href}>
                <div
                  className={cn(
                    "group relative flex items-center gap-3 h-10 px-3 rounded-lg cursor-pointer",
                    "transition-colors duration-150",
                    active
                      ? "bg-[rgba(124,110,246,0.15)] text-[var(--color-accent-light)]"
                      : "text-[var(--color-text-secondary)] hover:bg-[var(--color-card)] hover:text-[var(--color-text-primary)]"
                  )}
                >
                  {active && (
                    <motion.div
                      layoutId="nav-active" // shared layoutId makes the active indicator slide between items
                      className="absolute inset-0 rounded-lg bg-[rgba(124,110,246,0.12)] border border-[rgba(124,110,246,0.20)]"
                      transition={spring.smooth}
                    />
                  )}
                  <item.icon size={17} className="relative z-10 shrink-0" />
                  <AnimatePresence>
                    {expanded && (
                      <motion.span
                        initial={{ opacity: 0, x: -8 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: -8 }}
                        transition={{ duration: 0.15 }}
                        className="relative z-10 text-sm font-medium whitespace-nowrap"
                      >
                        {item.label}
                      </motion.span>
                    )}
                  </AnimatePresence>

                  {/* Tooltip when collapsed */}
                  {!expanded && (
                    <div className={cn(
                      "absolute left-full ml-3 z-50 pointer-events-none",
                      "px-2.5 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap",
                      "bg-[var(--color-elevated)] border border-[var(--color-border-strong)] text-[var(--color-text-primary)]",
                      "shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-150",
                      "-translate-y-1/2 top-1/2",
                    )}>
                      {item.label}
                    </div>
                  )}
                </div>
              </Link>
            </motion.div>
          )
        })}
      </motion.nav>

      {/* ── User + Logout ── */}
      <div className="px-2 mt-4 border-t border-[var(--color-border)] pt-4 space-y-1">
        <div className={cn(
          "flex items-center gap-3 px-3 py-2 rounded-lg",
          "text-[var(--color-text-secondary)]"
        )}>
          <div className="w-7 h-7 rounded-full bg-[var(--color-accent-dim)] flex items-center justify-center shrink-0">
            <User size={13} className="text-white" />
          </div>
          <AnimatePresence>
            {expanded && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
                className="min-w-0 flex-1"
              >
                <p className="text-xs font-medium text-[var(--color-text-primary)] truncate">
                  {user?.first_name} {user?.last_name}
                </p>
                <p className="text-[10px] text-[var(--color-text-muted)] truncate">{user?.email}</p>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <button
          onClick={logout}
          className={cn(
            "group relative flex items-center gap-3 h-9 px-3 w-full rounded-lg",
            "text-[var(--color-text-muted)] hover:text-[var(--color-expense)] hover:bg-[rgba(242,93,118,0.08)]",
            "transition-colors duration-150 text-sm"
          )}
        >
          <LogOut size={16} className="shrink-0" />
          <AnimatePresence>
            {expanded && (
              <motion.span
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
                className="whitespace-nowrap text-sm"
              >
                Sign out
              </motion.span>
            )}
          </AnimatePresence>
          {!expanded && (
            <div className="absolute left-full ml-3 z-50 pointer-events-none px-2.5 py-1.5 rounded-lg text-xs whitespace-nowrap bg-[var(--color-elevated)] border border-[var(--color-border-strong)] shadow-lg opacity-0 group-hover:opacity-100 transition-opacity -translate-y-1/2 top-1/2">
              Sign out
            </div>
          )}
        </button>
      </div>

      {/* ── Collapse toggle ── */}
      <button
        onClick={() => setExpanded((e) => !e)}
        className={cn(
          "absolute -right-3.5 top-1/2 -translate-y-1/2 z-20",
          "w-7 h-7 rounded-full border border-[var(--color-border-strong)]",
          "bg-[var(--color-elevated)] flex items-center justify-center",
          "text-[var(--color-text-muted)] hover:text-[var(--color-text-primary)]",
          "transition-colors shadow-md hover:shadow-[var(--color-accent)]/20"
        )}
        aria-label={expanded ? "Collapse sidebar" : "Expand sidebar"}
      >
        {expanded ? <ChevronLeft size={12} /> : <ChevronRight size={12} />}
      </button>
    </motion.aside>
  )
}
