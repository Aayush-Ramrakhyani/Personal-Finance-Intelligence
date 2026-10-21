"use client"

import { motion } from "framer-motion"
import { staggerContainer, staggerItem, staggerItemScale } from "@/lib/motion"

interface StaggerProps {
  children: React.ReactNode
  className?: string
  staggerDelay?: number
  variant?: "up" | "scale"
}

export function Stagger({ children, className, staggerDelay = 0.06, variant = "up" }: StaggerProps) {
  return (
    <motion.div
      variants={staggerContainer(staggerDelay)}
      initial="hidden"
      animate="visible"
      className={className}
    >
      {children}
    </motion.div>
  )
}

export function StaggerItem({
  children,
  className,
  variant = "up",
}: {
  children: React.ReactNode
  className?: string
  variant?: "up" | "scale"
}) {
  return (
    <motion.div
      variants={variant === "scale" ? staggerItemScale : staggerItem}
      className={className}
    >
      {children}
    </motion.div>
  )
}
