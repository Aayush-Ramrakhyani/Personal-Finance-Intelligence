"use client"

import Link from "next/link"
import { motion } from "framer-motion"
import { ArrowLeft, Home } from "lucide-react"
import { staggerContainer, staggerItem } from "@/lib/motion"

export default function NotFound() {
  return (
    <div className="min-h-dvh gradient-bg flex items-center justify-center px-6">
      <motion.div
        variants={staggerContainer(0.08)}
        initial="hidden"
        animate="visible"
        className="text-center space-y-6 max-w-md"
      >
        <motion.p
          variants={staggerItem}
          className="text-8xl font-black tabular-nums"
          style={{ color: "var(--color-accent)" }}
        >
          404
        </motion.p>
        <motion.div variants={staggerItem} className="space-y-2">
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Page not found</h1>
          <p className="text-[var(--color-text-secondary)]">
            The page you&apos;re looking for doesn&apos;t exist or has been moved.
          </p>
        </motion.div>
        <motion.div variants={staggerItem} className="flex gap-3 justify-center">
          <Link href="/">
            <button className="flex items-center gap-2 px-4 py-2 rounded-xl border border-[var(--color-border-strong)] text-sm text-[var(--color-text-primary)] hover:bg-[var(--color-elevated)] transition-colors">
              <Home size={14} />
              Home
            </button>
          </Link>
          <button
            onClick={() => window.history.back()}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[var(--color-accent)] text-white text-sm hover:bg-[var(--color-accent-light)] transition-colors"
          >
            <ArrowLeft size={14} />
            Go back
          </button>
        </motion.div>
      </motion.div>
    </div>
  )
}
