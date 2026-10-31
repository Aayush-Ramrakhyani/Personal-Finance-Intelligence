/*
 * badge.tsx
 * Small inline status badge with semantic colour variants (income, expense, warning,
 * info, etc.) and an optional leading dot for live-status indicators.
 */

import { cn } from "@/lib/utils"

export type BadgeVariant = "default" | "income" | "expense" | "transfer" | "warning" | "info" | "success" | "muted"

const variants: Record<BadgeVariant, string> = {
  default:  "bg-[var(--color-elevated)] text-[var(--color-text-secondary)] border-[var(--color-border)]",
  income:   "bg-[rgba(15,201,140,0.12)]  text-[var(--color-income)]   border-[rgba(15,201,140,0.20)]",
  expense:  "bg-[rgba(242,93,118,0.12)]  text-[var(--color-expense)]  border-[rgba(242,93,118,0.20)]",
  transfer: "bg-[rgba(167,139,250,0.12)] text-[var(--color-transfer)] border-[rgba(167,139,250,0.20)]",
  warning:  "bg-[rgba(245,166,35,0.12)]  text-[var(--color-warning)]  border-[rgba(245,166,35,0.20)]",
  info:     "bg-[rgba(79,170,255,0.12)]  text-[var(--color-info)]     border-[rgba(79,170,255,0.20)]",
  success:  "bg-[rgba(15,201,140,0.12)]  text-[var(--color-success)]  border-[rgba(15,201,140,0.20)]",
  muted:    "bg-[var(--color-card)] text-[var(--color-text-muted)] border-[var(--color-border)]",
}

interface BadgeProps {
  children: React.ReactNode
  variant?: BadgeVariant
  className?: string
  dot?: boolean
}

export function Badge({ children, variant = "default", className, dot }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium border",
        variants[variant],
        className
      )}
    >
      {dot && (
        <span className={cn(
          "w-1.5 h-1.5 rounded-full shrink-0",
          variant === "income"  && "bg-[var(--color-income)]",
          variant === "expense" && "bg-[var(--color-expense)]",
          variant === "warning" && "bg-[var(--color-warning)]",
          variant === "info"    && "bg-[var(--color-info)]",
          (variant === "default" || variant === "muted") && "bg-[var(--color-text-muted)]",
        )} />
      )}
      {children}
    </span>
  )
}
