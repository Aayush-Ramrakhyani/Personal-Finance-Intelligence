"use client"

import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Bell, Check, CheckCheck, Info, AlertTriangle, TrendingDown, Wallet } from "lucide-react"
import { notificationsApi } from "@/lib/api/notifications"
import type { Notification } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Stagger, StaggerItem } from "@/components/motion/stagger"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"
import { formatDate, cn } from "@/lib/utils"

const TYPE_ICONS: Record<string, React.ElementType> = {
  budget_alert:    AlertTriangle,
  budget_warning:  AlertTriangle,
  overspend:       TrendingDown,
  insight:         Info,
  budget_exceeded: AlertTriangle,
}

const TYPE_VARIANTS: Record<string, string> = {
  budget_alert:    "warning",
  budget_warning:  "warning",
  overspend:       "expense",
  insight:         "info",
  budget_exceeded: "expense",
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const [marking, setMarking] = useState(false)

  const unread = notifications.filter(n => !n.is_read).length

  useEffect(() => {
    notificationsApi.list({ limit: 50 })
      .then(r => setNotifications(r.data))
      .finally(() => setLoading(false))
  }, [])

  async function markAllRead() {
    setMarking(true)
    try {
      await notificationsApi.markAllRead()
      setNotifications(n => n.map(x => ({ ...x, is_read: true })))
    } finally {
      setMarking(false)
    }
  }

  async function markRead(id: string) {
    await notificationsApi.markRead([id])
    setNotifications(n => n.map(x => x.id === id ? { ...x, is_read: true } : x))
  }

  return (
    <PageTransition>
      <div className="max-w-2xl space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <p className="text-sm text-[var(--color-text-secondary)]">
              {unread > 0 ? `${unread} unread` : "All caught up"}
            </p>
          </div>
          {unread > 0 && (
            <Button variant="secondary" size="sm" isLoading={marking} leftIcon={<CheckCheck size={13} />} onClick={markAllRead}>
              Mark all read
            </Button>
          )}
        </div>

        {loading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-16 rounded-xl" />
            ))}
          </div>
        ) : notifications.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-48 gap-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-card)]">
            <Bell size={28} className="text-[var(--color-text-muted)]" />
            <p className="text-sm text-[var(--color-text-secondary)]">No notifications</p>
          </div>
        ) : (
          <Stagger className="space-y-1.5">
            {notifications.map((n) => {
              const Icon = TYPE_ICONS[n.type] ?? Info
              const variant = TYPE_VARIANTS[n.type] ?? "info"
              return (
                <StaggerItem key={n.id}>
                  <motion.div
                    layout
                    className={cn(
                      "flex gap-3 p-4 rounded-xl border transition-colors cursor-pointer",
                      n.is_read
                        ? "border-[var(--color-border)] bg-[var(--color-card)]"
                        : "border-[var(--color-border-strong)] bg-[var(--color-elevated)]"
                    )}
                    onClick={() => !n.is_read && markRead(n.id)}
                  >
                    <div className={cn(
                      "w-9 h-9 rounded-xl flex items-center justify-center shrink-0",
                      variant === "expense"  && "bg-[rgba(242,93,118,0.12)] text-[var(--color-expense)]",
                      variant === "warning"  && "bg-[rgba(245,166,35,0.12)]  text-[var(--color-warning)]",
                      variant === "info"     && "bg-[rgba(79,170,255,0.12)]  text-[var(--color-info)]",
                    )}>
                      <Icon size={15} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <p className={cn(
                          "text-sm font-medium",
                          n.is_read ? "text-[var(--color-text-secondary)]" : "text-[var(--color-text-primary)]"
                        )}>
                          {n.title}
                        </p>
                        {!n.is_read && (
                          <span className="w-2 h-2 rounded-full bg-[var(--color-accent)] shrink-0 mt-1" />
                        )}
                      </div>
                      <p className="text-xs text-[var(--color-text-muted)] mt-0.5 line-clamp-2">{n.body}</p>
                      <p className="text-[10px] text-[var(--color-text-muted)] mt-1">
                        {formatDate(n.created_at, "relative")}
                      </p>
                    </div>
                  </motion.div>
                </StaggerItem>
              )
            })}
          </Stagger>
        )}
      </div>
    </PageTransition>
  )
}
