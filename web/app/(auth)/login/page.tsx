"use client"

import { useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { motion } from "framer-motion"
import { Eye, EyeOff, LogIn } from "lucide-react"
import { useAuth } from "@/contexts/auth"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { staggerContainer, staggerItem } from "@/lib/motion"

export default function LoginPage() {
  const [email, setEmail]       = useState("")
  const [password, setPassword] = useState("")
  const [showPw, setShowPw]     = useState(false)
  const [error, setError]       = useState("")
  const [loading, setLoading]   = useState(false)
  const { login } = useAuth()
  const router = useRouter()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError("")
    setLoading(true)
    try {
      await login({ email, password })
      router.push("/dashboard")
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Invalid email or password.")
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div
      variants={staggerContainer(0.07)}
      initial="hidden"
      animate="visible"
      className="w-full max-w-sm space-y-6"
    >
      <motion.div variants={staggerItem} className="space-y-1.5">
        <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Welcome back</h1>
        <p className="text-sm text-[var(--color-text-secondary)]">
          Sign in to your Finance Intelligence account
        </p>
      </motion.div>

      <motion.form
        variants={staggerItem}
        onSubmit={handleSubmit}
        className="space-y-4"
      >
        <Input
          label="Email address"
          type="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoComplete="email"
        />

        <Input
          label="Password"
          type={showPw ? "text" : "password"}
          placeholder="Your password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          autoComplete="current-password"
          rightIcon={
            <button
              type="button"
              onClick={() => setShowPw((s) => !s)}
              className="text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)] transition-colors"
              tabIndex={-1}
            >
              {showPw ? <EyeOff size={15} /> : <Eye size={15} />}
            </button>
          }
        />

        {error && (
          <motion.p
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-xs text-[var(--color-expense)] bg-[rgba(242,93,118,0.08)] border border-[rgba(242,93,118,0.20)] rounded-lg px-3 py-2"
          >
            {error}
          </motion.p>
        )}

        <Button type="submit" size="lg" isLoading={loading} leftIcon={<LogIn size={15} />} className="w-full">
          Sign in
        </Button>
      </motion.form>

      <motion.p variants={staggerItem} className="text-sm text-center text-[var(--color-text-secondary)]">
        New to Finance Intelligence?{" "}
        <Link href="/register" className="text-[var(--color-accent-light)] hover:text-[var(--color-accent)] font-medium transition-colors">
          Create account
        </Link>
      </motion.p>
    </motion.div>
  )
}
