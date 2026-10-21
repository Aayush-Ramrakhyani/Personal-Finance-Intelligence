"use client"

import { motion } from "framer-motion"
import { cn } from "@/lib/utils"

interface CardProps {
  children: React.ReactNode
  className?: string
  hover?: boolean
  glow?: "accent" | "income" | "expense" | "none"
  onClick?: () => void
}

export function Card({ children, className, hover = false, glow = "none", onClick }: CardProps) {
  const glowClass = {
    accent:  "hover:shadow-[0_4px_24px_rgba(124,110,246,0.20)]",
    income:  "hover:shadow-[0_4px_16px_rgba(15,201,140,0.18)]",
    expense: "hover:shadow-[0_4px_16px_rgba(242,93,118,0.18)]",
    none: "",
  }[glow]

  return (
    <motion.div
      whileHover={hover ? { y: -2, transition: { type: "spring", stiffness: 400, damping: 30 } } : {}}
      onClick={onClick}
      className={cn(
        "rounded-xl border border-[var(--color-border)] bg-[var(--color-card)]",
        "transition-shadow duration-200",
        hover && "cursor-pointer",
        glow !== "none" && glowClass,
        className
      )}
    >
      {children}
    </motion.div>
  )
}

export function CardHeader({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={cn("px-5 pt-5 pb-3 flex items-center justify-between", className)}>
      {children}
    </div>
  )
}

export function CardTitle({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <h3 className={cn("text-sm font-semibold text-[var(--color-text-secondary)] uppercase tracking-wider", className)}>
      {children}
    </h3>
  )
}

export function CardContent({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={cn("px-5 pb-5", className)}>
      {children}
    </div>
  )
}
