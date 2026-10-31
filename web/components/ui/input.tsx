/*
 * input.tsx
 * Styled text input (and TextArea variant) with optional label, error/hint messages,
 * and left/right icon slots; auto-generates an id from the label for accessibility.
 */

"use client"

import { cn } from "@/lib/utils"
import type { InputHTMLAttributes } from "react"

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  hint?: string
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
}

export function Input({
  label,
  error,
  hint,
  leftIcon,
  rightIcon,
  className,
  id,
  ...props
}: InputProps) {
  const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-")

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label
          htmlFor={inputId}
          className="text-sm font-medium text-[var(--color-text-secondary)]"
        >
          {label}
        </label>
      )}
      <div className="relative">
        {leftIcon && (
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]">
            {leftIcon}
          </span>
        )}
        <input
          id={inputId}
          className={cn(
            "w-full h-10 rounded-lg border bg-[var(--color-elevated)] text-[var(--color-text-primary)]",
            "px-3 text-sm transition-colors duration-150",
            "placeholder:text-[var(--color-text-muted)]",
            "border-[var(--color-border)] focus:border-[var(--color-accent)] focus:outline-none",
            "disabled:opacity-50 disabled:cursor-not-allowed",
            leftIcon  && "pl-9",
            rightIcon && "pr-9",
            error && "border-[var(--color-expense)] focus:border-[var(--color-expense)]",
            className
          )}
          {...props}
        />
        {rightIcon && (
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]">
            {rightIcon}
          </span>
        )}
      </div>
      {error && <p className="text-xs text-[var(--color-expense)]">{error}</p>}
      {hint && !error && <p className="text-xs text-[var(--color-text-muted)]">{hint}</p>}
    </div>
  )
}

interface TextAreaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string
  error?: string
}

export function TextArea({ label, error, className, id, ...props }: TextAreaProps) {
  const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-") // same id derivation for TextArea
  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={inputId} className="text-sm font-medium text-[var(--color-text-secondary)]">
          {label}
        </label>
      )}
      <textarea
        id={inputId}
        className={cn(
          "w-full rounded-lg border bg-[var(--color-elevated)] text-[var(--color-text-primary)]",
          "px-3 py-2.5 text-sm transition-colors resize-none",
          "placeholder:text-[var(--color-text-muted)]",
          "border-[var(--color-border)] focus:border-[var(--color-accent)] focus:outline-none",
          error && "border-[var(--color-expense)]",
          className
        )}
        {...props}
      />
      {error && <p className="text-xs text-[var(--color-expense)]">{error}</p>}
    </div>
  )
}
