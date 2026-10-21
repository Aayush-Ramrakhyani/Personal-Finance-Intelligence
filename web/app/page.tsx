"use client"

import Link from "next/link"
import { motion } from "framer-motion"
import {
  Sparkles, ArrowRight, BarChart3, Bot, Upload, PiggyBank,
  Shield, Zap,
} from "lucide-react"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"

const features = [
  { icon: Upload,    title: "Bank-agnostic CSV import",   desc: "Import from any bank. Auto-detect columns, skip duplicates." },
  { icon: Bot,       title: "AI categorisation",           desc: "GPT-4 / Gemini classifies every transaction. Cached per merchant." },
  { icon: PiggyBank, title: "Smart budget tracking",       desc: "Set budgets per category. Real-time progress with alerts." },
  { icon: BarChart3, title: "Deep analytics",              desc: "Trends, anomalies, category breakdowns, savings rate." },
  { icon: Sparkles,  title: "Conversational AI assistant", desc: "Ask questions in plain language about your spending." },
  { icon: Shield,    title: "Self-hosted & private",       desc: "Your data stays on your server. No SaaS fees." },
]

export default function LandingPage() {
  return (
    <div className="min-h-dvh gradient-bg flex flex-col">
      {/* Nav */}
      <nav className="flex items-center justify-between px-6 py-4 max-w-6xl mx-auto w-full">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center">
            <Sparkles size={14} className="text-white" />
          </div>
          <span className="font-semibold text-[var(--color-text-primary)]">Finance AI</span>
        </div>
        <div className="flex items-center gap-2">
          <Link href="/login">
            <button className="px-4 py-2 text-sm text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] transition-colors">
              Sign in
            </button>
          </Link>
          <Link href="/register">
            <button className="px-4 py-2 rounded-lg bg-[var(--color-accent)] text-white text-sm font-medium hover:bg-[var(--color-accent-light)] transition-colors">
              Get started
            </button>
          </Link>
        </div>
      </nav>

      {/* Hero */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-6 py-16 max-w-4xl mx-auto w-full">
        <motion.div
          variants={staggerContainer(0.09)}
          initial="hidden"
          animate="visible"
          className="space-y-6"
        >
          <motion.div variants={staggerItem}>
            <span
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border"
              style={{
                borderColor: "rgba(124,110,246,0.30)",
                backgroundColor: "rgba(124,110,246,0.10)",
                color: "var(--color-accent-light)"
              }}
            >
              <Zap size={10} />
              AI-powered · Self-hosted · Free
            </span>
          </motion.div>

          <motion.h1
            variants={staggerItem}
            className="text-4xl sm:text-5xl lg:text-6xl font-bold text-[var(--color-text-primary)] leading-tight"
          >
            Take control of your{" "}
            <span style={{
              backgroundImage: "linear-gradient(to right, var(--color-accent), var(--color-accent-light))",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
            }}>
              financial future
            </span>
          </motion.h1>

          <motion.p
            variants={staggerItem}
            className="text-lg text-[var(--color-text-secondary)] max-w-xl mx-auto leading-relaxed"
          >
            Import bank statements, auto-categorise expenses with AI, track budgets,
            and get conversational insights — all on your own server.
          </motion.p>

          <motion.div variants={staggerItem} className="flex flex-col sm:flex-row gap-3 justify-center">
            <Link href="/register">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="px-6 py-3 rounded-xl bg-[var(--color-accent)] text-white font-medium flex items-center gap-2 hover:bg-[var(--color-accent-light)] transition-colors"
                style={{ boxShadow: "0 4px 24px rgba(124,110,246,0.30)" }}
              >
                Get started for free
                <ArrowRight size={16} />
              </motion.button>
            </Link>
            <Link href="/login">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="px-6 py-3 rounded-xl border border-[var(--color-border-strong)] text-[var(--color-text-primary)] font-medium hover:bg-[var(--color-elevated)] transition-colors"
              >
                Sign in
              </motion.button>
            </Link>
          </motion.div>
        </motion.div>

        {/* Features */}
        <motion.div
          variants={staggerContainer(0.06)}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-20 w-full"
        >
          {features.map((f) => (
            <motion.div
              key={f.title}
              variants={staggerItem}
              className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-5 text-left"
            >
              <div
                className="w-9 h-9 rounded-xl flex items-center justify-center mb-3"
                style={{ backgroundColor: "rgba(124,110,246,0.12)" }}
              >
                <f.icon size={16} className="text-[var(--color-accent-light)]" />
              </div>
              <p className="font-semibold text-[var(--color-text-primary)] mb-1">{f.title}</p>
              <p className="text-sm text-[var(--color-text-secondary)]">{f.desc}</p>
            </motion.div>
          ))}
        </motion.div>

        {/* Stack */}
        <motion.div
          variants={fadeInUp}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="mt-20 w-full max-w-2xl"
        >
          <p className="text-xs text-[var(--color-text-muted)] uppercase tracking-widest mb-4">Built with</p>
          <div className="flex flex-wrap justify-center gap-3">
            {["FastAPI", "PostgreSQL", "Redis", "Celery", "Next.js 16", "Flutter", "OpenAI", "Gemini"].map(t => (
              <span key={t} className="px-3 py-1.5 rounded-lg text-xs text-[var(--color-text-secondary)] border border-[var(--color-border)] bg-[var(--color-card)]">
                {t}
              </span>
            ))}
          </div>
        </motion.div>
      </main>

      <footer className="text-center py-6 text-xs text-[var(--color-text-muted)]">
        © 2025 Aayush Ramrakhyani · Personal Finance Intelligence
      </footer>
    </div>
  )
}
