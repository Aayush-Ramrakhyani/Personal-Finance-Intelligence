/*
 * dialog.tsx
 * Accessible modal dialog with animated backdrop (overlayVariants) and panel
 * (dialogVariants), Escape-key dismissal, and body scroll-lock while open.
 */

"use client"

import { motion, AnimatePresence } from "framer-motion"
import { X } from "lucide-react"
import { cn } from "@/lib/utils"
import { dialogVariants, overlayVariants } from "@/lib/motion"
import { useEffect } from "react"

interface DialogProps {
  open: boolean
  onClose: () => void
  title?: string
  description?: string
  children: React.ReactNode
  className?: string
  size?: "sm" | "md" | "lg" | "xl"
}

const sizeClass = {
  sm: "max-w-sm",
  md: "max-w-md",
  lg: "max-w-lg",
  xl: "max-w-2xl",
}

export function Dialog({ open, onClose, title, description, children, className, size = "md" }: DialogProps) {
  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => { if (e.key === "Escape") onClose() } // close on Escape key
    document.addEventListener("keydown", handler)
    return () => document.removeEventListener("keydown", handler)
  }, [open, onClose])

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "" // prevent background scroll while dialog is open
    return () => { document.body.style.overflow = "" }
  }, [open])

  return (
    <AnimatePresence>
      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <motion.div
            variants={overlayVariants}
            initial="hidden"
            animate="visible"
            exit="hidden"
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={onClose}
          />
          <motion.div
            variants={dialogVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
            className={cn(
              "relative w-full z-10",
              "rounded-2xl border border-[var(--color-border-strong)]",
              "bg-[var(--color-elevated)] shadow-[0_24px_64px_rgba(0,0,0,0.6)]",
              sizeClass[size],
              className
            )}
            role="dialog"
            aria-modal="true"
          >
            {(title || description) && (
              <div className="flex items-start justify-between p-6 pb-4 border-b border-[var(--color-border)]">
                <div className="space-y-1">
                  {title && (
                    <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">{title}</h2>
                  )}
                  {description && (
                    <p className="text-sm text-[var(--color-text-secondary)]">{description}</p>
                  )}
                </div>
                <button
                  onClick={onClose}
                  className="p-1.5 rounded-lg hover:bg-[var(--color-overlay)] text-[var(--color-text-muted)] hover:text-[var(--color-text-primary)] transition-colors"
                  aria-label="Close"
                >
                  <X size={16} />
                </button>
              </div>
            )}
            <div className="p-6">{children}</div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  )
}
