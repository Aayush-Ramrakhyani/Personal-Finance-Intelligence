"use client"

import { motion } from "framer-motion"
import { cn } from "@/lib/utils"

interface ProgressBarProps {
  value: number
  max?: number
  variant?: "default" | "income" | "expense" | "warning" | "gradient"
  size?: "xs" | "sm" | "md"
  showLabel?: boolean
  label?: string
  className?: string
  animated?: boolean
}

const trackVariants = {
  default:  "bg-[var(--color-border)]",
  income:   "bg-[rgba(15,201,140,0.15)]",
  expense:  "bg-[rgba(242,93,118,0.15)]",
  warning:  "bg-[rgba(245,166,35,0.15)]",
  gradient: "bg-[var(--color-border)]",
}

const fillVariants = {
  default:  "bg-[var(--color-accent)]",
  income:   "bg-[var(--color-income)]",
  expense:  "bg-[var(--color-expense)]",
  warning:  "bg-[var(--color-warning)]",
  gradient: "bg-gradient-to-r from-[var(--color-accent)] to-[var(--color-accent-light)]",
}

const sizeVariants = {
  xs: "h-1",
  sm: "h-1.5",
  md: "h-2",
}

export function ProgressBar({
  value,
  max = 100,
  variant = "default",
  size = "sm",
  showLabel = false,
  label,
  className,
  animated = true,
}: ProgressBarProps) {
  const percentage = Math.min((value / max) * 100, 100)

  const autoVariant =
    variant === "default" && percentage >= 90
      ? "expense"
      : variant === "default" && percentage >= 75
      ? "warning"
      : variant

  return (
    <div className={cn("space-y-1.5", className)}>
      {(showLabel || label) && (
        <div className="flex items-center justify-between text-xs text-[var(--color-text-secondary)]">
          <span>{label}</span>
          <span className="font-mono">{percentage.toFixed(0)}%</span>
        </div>
      )}
      <div className={cn("w-full rounded-full overflow-hidden", sizeVariants[size], trackVariants[autoVariant])}>
        <motion.div
          className={cn("h-full rounded-full", fillVariants[autoVariant])}
          initial={animated ? { width: 0 } : { width: `${percentage}%` }}
          animate={{ width: `${percentage}%` }}
          transition={{ type: "spring", stiffness: 120, damping: 20, delay: 0.2 }}
        />
      </div>
    </div>
  )
}

interface CircularProgressProps {
  value: number
  size?: number
  strokeWidth?: number
  variant?: "default" | "income" | "expense" | "warning"
  children?: React.ReactNode
  className?: string
}

export function CircularProgress({
  value,
  size = 80,
  strokeWidth = 6,
  variant = "default",
  children,
  className,
}: CircularProgressProps) {
  const radius = (size - strokeWidth) / 2
  const circumference = 2 * Math.PI * radius
  const percentage = Math.min(value, 100)
  const strokeDashoffset = circumference - (percentage / 100) * circumference

  const colors = {
    default: "var(--color-accent)",
    income:  "var(--color-income)",
    expense: "var(--color-expense)",
    warning: "var(--color-warning)",
  }

  return (
    <div className={cn("relative inline-flex items-center justify-center", className)}>
      <svg width={size} height={size} className="-rotate-90">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--color-border)"
          strokeWidth={strokeWidth}
        />
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={colors[variant]}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={circumference}
          initial={{ strokeDashoffset: circumference }}
          animate={{ strokeDashoffset }}
          transition={{ type: "spring", stiffness: 60, damping: 15, delay: 0.3 }}
        />
      </svg>
      {children && (
        <div className="absolute inset-0 flex items-center justify-center">
          {children}
        </div>
      )}
    </div>
  )
}
