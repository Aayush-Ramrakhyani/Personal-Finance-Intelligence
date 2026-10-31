/*
 * skeleton.tsx
 * Loading skeleton primitives (Skeleton, CardSkeleton, TransactionSkeleton, ChartSkeleton)
 * using the CSS shimmer animation defined in globals.css.
 */

import { cn } from "@/lib/utils"

interface SkeletonProps {
  className?: string
  variant?: "line" | "circle" | "rect"
  style?: React.CSSProperties
}

export function Skeleton({ className, variant = "rect" }: SkeletonProps) {
  return (
    <div
      className={cn(
        "shimmer",
        variant === "circle" && "rounded-full",
        variant === "line"   && "rounded-md h-4",
        variant === "rect"   && "rounded-xl",
        className
      )}
    />
  )
}

export function CardSkeleton() {
  return (
    <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-5 space-y-4">
      <div className="flex items-center justify-between">
        <Skeleton className="h-4 w-28" />
        <Skeleton className="h-8 w-8 rounded-lg" />
      </div>
      <Skeleton className="h-8 w-36" />
      <Skeleton className="h-3 w-20" />
    </div>
  )
}

export function TransactionSkeleton() {
  return (
    <div className="flex items-center gap-3 p-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-card)]">
      <Skeleton className="h-10 w-10 rounded-xl shrink-0" />
      <div className="flex-1 space-y-2">
        <Skeleton className="h-4 w-40" />
        <Skeleton className="h-3 w-24" />
      </div>
      <div className="space-y-2 text-right">
        <Skeleton className="h-4 w-20" />
        <Skeleton className="h-3 w-14" />
      </div>
    </div>
  )
}

export function ChartSkeleton({ height = "h-48" }: { height?: string }) {
  return (
    <div className={cn("rounded-xl border border-[var(--color-border)] bg-[var(--color-card)]", height)}>
      <div className="h-full p-5 flex flex-col gap-3 justify-end">
        <div className="flex gap-2 items-end h-full">
          {Array.from({ length: 8 }).map((_, i) => (
            <Skeleton
              key={i}
              className="flex-1 rounded-sm"
              style={{ height: `${30 + Math.random() * 60}%` } as React.CSSProperties}
            />
          ))}
        </div>
      </div>
    </div>
  )
}
