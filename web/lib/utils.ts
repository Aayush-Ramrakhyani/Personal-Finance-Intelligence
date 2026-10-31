/*
 * utils.ts
 * Shared utility functions: Tailwind class merging (cn), INR currency/date formatting,
 * percent/clamp helpers, category colour mapping, and a truncate utility.
 */

import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(
  amount: number | string,
  currency = "INR",
  compact = false
): string {
  const num = typeof amount === "string" ? parseFloat(amount) : amount
  if (isNaN(num)) return "—"

  if (compact && Math.abs(num) >= 1_00_000) {
    const lakhs = num / 1_00_000 // Indian number system: 1 lakh = 100 000
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency,
      maximumFractionDigits: 1,
    }).format(lakhs) + "L"
  }

  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency,
    maximumFractionDigits: 2,
    minimumFractionDigits: 0,
  }).format(num)
}

export function formatDate(
  dateStr: string | Date,
  format: "short" | "medium" | "long" | "relative" = "medium"
): string {
  const date = typeof dateStr === "string" ? new Date(dateStr) : dateStr
  if (isNaN(date.getTime())) return "—"

  if (format === "relative") {
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const days = Math.floor(diff / 86_400_000)
    if (days === 0) return "Today"
    if (days === 1) return "Yesterday"
    if (days < 7) return `${days} days ago`
    if (days < 30) return `${Math.floor(days / 7)} weeks ago`
    if (days < 365) return `${Math.floor(days / 30)} months ago`
    return `${Math.floor(days / 365)} years ago`
  }

  const opts: Intl.DateTimeFormatOptions =
    format === "short"
      ? { day: "2-digit", month: "short" }
      : format === "medium"
      ? { day: "2-digit", month: "short", year: "numeric" }
      : { day: "2-digit", month: "long", year: "numeric" }

  return new Intl.DateTimeFormat("en-IN", opts).format(date)
}

export function formatPercent(value: number | string, decimals = 1): string {
  const num = typeof value === "string" ? parseFloat(value) : value
  if (isNaN(num)) return "0%"
  return `${num.toFixed(decimals)}%`
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

export const CATEGORY_COLORS: Record<string, string> = {
  "Food & Dining":   "#F25D76",
  "Shopping":        "#7C6EF6",
  "Transport":       "#4FAAFF",
  "Entertainment":   "#F5A623",
  "Bills":           "#A78BFA",
  "Health":          "#0FC98C",
  "Travel":          "#F97316",
  "Education":       "#22D3EE",
  "Investments":     "#10B981",
  "Salary":          "#0FC98C",
  "Freelance":       "#84CC16",
  "Other":           "#8892B0",
}

export function getCategoryColor(name?: string | null): string {
  if (!name) return "#8892B0"
  return CATEGORY_COLORS[name] ?? "#8892B0"
}

export function truncate(str: string, length = 40): string {
  if (str.length <= length) return str
  return str.slice(0, length - 1) + "…"
}
