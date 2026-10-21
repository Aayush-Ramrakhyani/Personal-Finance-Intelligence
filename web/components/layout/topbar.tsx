"use client"

import { usePathname } from "next/navigation"
import Link from "next/link"
import { motion } from "framer-motion"
import { Bell, Search } from "lucide-react"
import { cn } from "@/lib/utils"
import { useEffect, useState } from "react"
import { notificationsApi } from "@/lib/api/notifications"
import { fadeIn } from "@/lib/motion"

const pageTitles: Record<string, string> = {
  "/dashboard":    "Dashboard",
  "/transactions": "Transactions",
  "/import":       "Import CSV",
  "/budgets":      "Budgets",
  "/analytics":    "Analytics",
  "/ai":           "AI Assistant",
  "/notifications":"Notifications",
  "/settings":     "Settings",
}

export function Topbar() {
  const pathname = usePathname()
  const [unread, setUnread] = useState(0)

  const title = Object.entries(pageTitles).find(([k]) =>
    pathname === k || pathname.startsWith(k + "/")
  )?.[1] ?? "Finance AI"

  useEffect(() => {
    notificationsApi.unreadCount()
      .then((r) => setUnread(r.data.count))
      .catch(() => {})
  }, [pathname])

  return (
    <motion.header
      variants={fadeIn}
      initial="hidden"
      animate="visible"
      className={cn(
        "sticky top-0 z-30 h-14 flex items-center justify-between",
        "px-6 border-b border-[var(--color-border)]",
        "bg-[var(--color-surface)]/80 backdrop-blur-md"
      )}
    >
      <h1 className="text-base font-semibold text-[var(--color-text-primary)]">{title}</h1>

      <div className="flex items-center gap-2">
        {/* Search hint */}
        <button className={cn(
          "hidden sm:flex items-center gap-2 h-8 px-3 rounded-lg text-xs",
          "border border-[var(--color-border)] bg-[var(--color-card)]",
          "text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)]",
          "transition-colors cursor-pointer"
        )}>
          <Search size={13} />
          <span>Search…</span>
          <kbd className="ml-1 px-1.5 py-0.5 rounded text-[10px] border border-[var(--color-border)] bg-[var(--color-elevated)]">⌘K</kbd>
        </button>

        {/* Notifications bell */}
        <Link href="/notifications">
          <button className={cn(
            "relative flex items-center justify-center w-8 h-8 rounded-lg",
            "border border-[var(--color-border)] bg-[var(--color-card)]",
            "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]",
            "transition-colors"
          )}>
            <Bell size={15} />
            {unread > 0 && (
              <motion.span
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-[var(--color-accent)] text-white text-[10px] font-bold flex items-center justify-center"
              >
                {unread > 9 ? "9+" : unread}
              </motion.span>
            )}
          </button>
        </Link>
      </div>
    </motion.header>
  )
}
