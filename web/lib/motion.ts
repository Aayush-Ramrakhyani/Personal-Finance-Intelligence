/*
 * motion.ts
 * Central Framer Motion configuration — spring presets, easing curves, and reusable
 * Variants for pages, stagger lists, cards, dialogs, drawers, and progress bars.
 */

import type { Variants, Transition } from "framer-motion"

/* ─── Durations ───────────────────────────────────────────────────────────── */
export const duration = {
  fast:   0.15,
  base:   0.25,
  slow:   0.4,
  slower: 0.6,
} as const

/* ─── Easings ─────────────────────────────────────────────────────────────── */
export const ease = {
  standard:  [0.4, 0, 0.2, 1]  as [number, number, number, number],
  decelerate:[0, 0, 0.2, 1]    as [number, number, number, number],
  accelerate:[0.4, 0, 1, 1]    as [number, number, number, number],
  sharp:     [0.4, 0, 0.6, 1]  as [number, number, number, number],
} as const

/* ─── Spring presets ──────────────────────────────────────────────────────── */
export const spring = {
  snappy:  { type: "spring", stiffness: 500, damping: 35, mass: 0.8 } as Transition,
  smooth:  { type: "spring", stiffness: 300, damping: 30, mass: 1.0 } as Transition,
  gentle:  { type: "spring", stiffness: 200, damping: 28, mass: 1.0 } as Transition,
  bouncy:  { type: "spring", stiffness: 400, damping: 20, mass: 0.8 } as Transition,
  slow:    { type: "spring", stiffness: 150, damping: 26, mass: 1.2 } as Transition,
} as const

/* ─── Page transition variants ───────────────────────────────────────────── */
export const pageVariants: Variants = {
  initial: { opacity: 0, y: 12 },
  enter:   {
    opacity: 1, y: 0,
    transition: { duration: duration.slow, ease: ease.decelerate },
  },
  exit: {
    opacity: 0, y: -8,
    transition: { duration: duration.base, ease: ease.accelerate },
  },
}

/* ─── Stagger container ───────────────────────────────────────────────────── */
export function staggerContainer(
  staggerChildren = 0.06,
  delayChildren   = 0.05
): Variants {
  return {
    hidden:  {},
    visible: {
      transition: { staggerChildren, delayChildren },
    },
  }
}

/* ─── Stagger item variants ───────────────────────────────────────────────── */
export const staggerItem: Variants = {
  hidden:  { opacity: 0, y: 16 },
  visible: {
    opacity: 1, y: 0,
    transition: { duration: duration.slow, ease: ease.decelerate },
  },
}

export const staggerItemLeft: Variants = {
  hidden:  { opacity: 0, x: -16 },
  visible: {
    opacity: 1, x: 0,
    transition: { duration: duration.slow, ease: ease.decelerate },
  },
}

export const staggerItemScale: Variants = {
  hidden:  { opacity: 0, scale: 0.94 },
  visible: {
    opacity: 1, scale: 1,
    transition: spring.smooth,
  },
}

/* ─── Card hover ──────────────────────────────────────────────────────────── */
export const cardHover = {
  rest: { y: 0, boxShadow: "0 1px 3px rgba(0,0,0,0.4)" },
  hover: {
    y: -3,
    boxShadow: "0 8px 24px rgba(0,0,0,0.5)",
    transition: spring.snappy,
  },
}

/* ─── Fade variants ───────────────────────────────────────────────────────── */
export const fadeIn: Variants = {
  hidden:  { opacity: 0 },
  visible: { opacity: 1, transition: { duration: duration.base } },
}

export const fadeInUp: Variants = {
  hidden:  { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: duration.slow, ease: ease.decelerate } },
}

export const fadeInScale: Variants = {
  hidden:  { opacity: 0, scale: 0.92 },
  visible: { opacity: 1, scale: 1, transition: spring.smooth },
}

/* ─── Dialog / modal ──────────────────────────────────────────────────────── */
export const dialogVariants: Variants = {
  hidden:  { opacity: 0, scale: 0.94, y: 8 },
  visible: { opacity: 1, scale: 1,    y: 0, transition: spring.snappy },
  exit:    { opacity: 0, scale: 0.96, y: 4, transition: { duration: 0.15, ease: ease.accelerate } },
}

export const overlayVariants: Variants = {
  hidden:  { opacity: 0 },
  visible: { opacity: 1, transition: { duration: 0.2 } },
  exit:    { opacity: 0, transition: { duration: 0.15 } },
}

/* ─── Drawer ──────────────────────────────────────────────────────────────── */
export const drawerVariants: Variants = {
  hidden:  { x: "100%" },
  visible: { x: 0, transition: spring.smooth },
  exit:    { x: "100%", transition: { duration: 0.2, ease: ease.accelerate } },
}

/* ─── Dropdown ────────────────────────────────────────────────────────────── */
export const dropdownVariants: Variants = {
  hidden:  { opacity: 0, y: -8, scale: 0.96 },
  visible: { opacity: 1, y: 0,  scale: 1,    transition: spring.snappy },
  exit:    { opacity: 0, y: -4, scale: 0.98, transition: { duration: 0.12 } },
}

/* ─── Sidebar ─────────────────────────────────────────────────────────────── */
export const sidebarItemVariants: Variants = {
  hidden:  { opacity: 0, x: -8 },
  visible: { opacity: 1, x: 0, transition: { duration: 0.2, ease: ease.decelerate } },
}

/* ─── Progress bar ────────────────────────────────────────────────────────── */
export function progressTransition(value: number): Transition {
  return {
    ...spring.smooth,
    delay: 0.3,
  }
}

/* ─── List item ───────────────────────────────────────────────────────────── */
export const listItemVariants: Variants = {
  hidden:  { opacity: 0, x: -8 },
  visible: { opacity: 1, x: 0,  transition: { duration: 0.2, ease: ease.decelerate } },
  exit:    { opacity: 0, x: 8,  transition: { duration: 0.15 } },
}
