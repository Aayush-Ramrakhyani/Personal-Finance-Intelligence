"use client"

import { cn } from "@/lib/utils"
import { ChevronDown } from "lucide-react"
import type { SelectHTMLAttributes } from "react"

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string
  error?: string
  options: { value: string; label: string }[]
  placeholder?: string
}

export function Select({ label, error, options, placeholder, className, id, ...props }: SelectProps) {
  const selectId = id ?? label?.toLowerCase().replace(/\s+/g, "-")

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={selectId} className="text-sm font-medium text-[var(--color-text-secondary)]">
          {label}
        </label>
      )}
      <div className="relative">
        <select
          id={selectId}
          className={cn(
            "w-full h-10 rounded-lg border bg-[var(--color-elevated)] text-[var(--color-text-primary)]",
            "px-3 pr-8 text-sm transition-colors appearance-none cursor-pointer",
            "border-[var(--color-border)] focus:border-[var(--color-accent)] focus:outline-none",
            "disabled:opacity-50 disabled:cursor-not-allowed",
            error && "border-[var(--color-expense)]",
            className
          )}
          {...props}
        >
          {placeholder && <option value="">{placeholder}</option>}
          {options.map(opt => (
            <option key={opt.value} value={opt.value}>{opt.label}</option>
          ))}
        </select>
        <ChevronDown
          size={14}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] pointer-events-none"
        />
      </div>
      {error && <p className="text-xs text-[var(--color-expense)]">{error}</p>}
    </div>
  )
}
