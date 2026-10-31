/*
 * button.tsx
 * Animated button component with multiple visual variants, size scales,
 * left/right icon slots, and an integrated loading spinner via Framer Motion tap/hover.
 */

"use client"

import { motion } from "framer-motion"
import { cn } from "@/lib/utils"
import { Loader2 } from "lucide-react"
import type { ButtonHTMLAttributes } from "react"

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "danger" | "outline" | "income" | "expense"
  size?: "xs" | "sm" | "md" | "lg"
  isLoading?: boolean
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
}

const variants = {
  primary:   "bg-accent text-white hover:bg-accent-light border border-accent/20 shadow-sm",
  secondary: "bg-elevated text-text-primary hover:bg-overlay border border-border-strong",
  ghost:     "text-text-secondary hover:text-text-primary hover:bg-elevated border border-transparent",
  danger:    "bg-expense/10 text-expense hover:bg-expense/20 border border-expense/20",
  outline:   "border border-border-strong text-text-primary hover:bg-elevated",
  income:    "bg-income/10 text-income hover:bg-income/20 border border-income/20",
  expense:   "bg-expense/10 text-expense hover:bg-expense/20 border border-expense/20",
}

const sizes = {
  xs: "h-7  px-2.5 text-xs  gap-1.5 rounded-md",
  sm: "h-8  px-3   text-sm  gap-1.5 rounded-lg",
  md: "h-10 px-4   text-sm  gap-2   rounded-lg",
  lg: "h-11 px-5   text-base gap-2   rounded-xl",
}

export function Button({
  variant = "primary",
  size = "md",
  isLoading = false,
  leftIcon,
  rightIcon,
  children,
  className,
  disabled,
  ...props
}: ButtonProps) {
  return (
    <motion.button
      whileTap={{ scale: 0.97 }} // subtle press feedback
      whileHover={{ scale: 1.01 }} // gentle lift on hover
      transition={{ type: "spring", stiffness: 500, damping: 35 }}
      className={cn(
        "inline-flex items-center justify-center font-medium",
        "transition-colors duration-150",
        "disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none",
        "cursor-pointer select-none",
        variants[variant],
        sizes[size],
        className
      )}
      disabled={disabled || isLoading}
      {...(props as React.ComponentPropsWithoutRef<typeof motion.button>)}
    >
      {isLoading ? (
        <Loader2 className="animate-spin" size={14} />
      ) : leftIcon ? (
        <span className="shrink-0">{leftIcon}</span>
      ) : null}
      {children}
      {rightIcon && !isLoading && <span className="shrink-0">{rightIcon}</span>}
    </motion.button>
  )
}
