"use client"

import { useEffect, useRef, useState } from "react"
import { useInView } from "framer-motion"
import { cn } from "@/lib/utils"

interface AnimatedNumberProps {
  value: number
  duration?: number
  formatFn?: (n: number) => string
  className?: string
  prefix?: string
  suffix?: string
}

function easeOutQuart(t: number): number {
  return 1 - Math.pow(1 - t, 4)
}

export function AnimatedNumber({
  value,
  duration = 1200,
  formatFn = (n) => n.toLocaleString("en-IN"),
  className,
  prefix = "",
  suffix = "",
}: AnimatedNumberProps) {
  const [display, setDisplay] = useState(0)
  const ref = useRef<HTMLSpanElement>(null)
  const inView = useInView(ref, { once: true, margin: "-20px" })
  const startTime = useRef<number | null>(null)
  const startValue = useRef(0)
  const raf = useRef<number | null>(null)

  useEffect(() => {
    if (!inView) return

    const from = startValue.current
    const to   = value
    startTime.current = null

    const step = (timestamp: number) => {
      if (!startTime.current) startTime.current = timestamp
      const elapsed  = timestamp - startTime.current
      const progress = Math.min(elapsed / duration, 1)
      const eased    = easeOutQuart(progress)
      const current  = from + (to - from) * eased
      setDisplay(current)

      if (progress < 1) {
        raf.current = requestAnimationFrame(step)
      } else {
        startValue.current = to
      }
    }

    raf.current = requestAnimationFrame(step)
    return () => { if (raf.current) cancelAnimationFrame(raf.current) }
  }, [value, duration, inView])

  return (
    <span ref={ref} className={cn("tabular-nums", className)}>
      {prefix}{formatFn(display)}{suffix}
    </span>
  )
}
