/*
 * page-transition.tsx
 * Thin wrapper that applies the shared pageVariants (fade + slide-up) to any page
 * component, ensuring consistent enter/exit transitions across the app.
 */

"use client"

import { motion } from "framer-motion"
import { pageVariants } from "@/lib/motion"

export function PageTransition({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      variants={pageVariants}
      initial="initial"
      animate="enter"
      exit="exit"
      className="min-h-full"
    >
      {children}
    </motion.div>
  )
}
