"use client"

import { useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { motion } from "framer-motion"
import { Eye, EyeOff, UserPlus } from "lucide-react"
import { useAuth } from "@/contexts/auth"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { staggerContainer, staggerItem } from "@/lib/motion"

export default function RegisterPage() {
  const [form, setForm] = useState({
    first_name: "",
    last_name: "",
    email: "",
    password: "",
    confirm_password: "",
  })
  const [showPw, setShowPw]   = useState(false)
  const [error, setError]     = useState("")
  const [loading, setLoading] = useState(false)
  const { register } = useAuth()
  const router = useRouter()

  const set = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm((f) => ({ ...f, [k]: e.target.value }))

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError("")

    if (form.password !== form.confirm_password) {
      setError("Passwords do not match."); return
    }
    if (form.password.length < 8) {
      setError("Password must be at least 8 characters."); return
    }
    if (!/[A-Z]/.test(form.password)) {
      setError("Password must contain at least one uppercase letter."); return
    }
    if (!/\d/.test(form.password)) {
      setError("Password must contain at least one digit."); return
    }

    setLoading(true)
    try {
      await register({
        first_name: form.first_name,
        last_name:  form.last_name,
        email:      form.email,
        password:   form.password,
        currency:   "INR",
        timezone:   "Asia/Kolkata",
      })
      router.push("/dashboard")
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Registration failed. Please try again.")
    } finally {
      setLoading(false)
    }
  }

  return (
    <motion.div
      variants={staggerContainer(0.06)}
      initial="hidden"
      animate="visible"
      className="w-full max-w-sm space-y-6"
    >
      <motion.div variants={staggerItem} className="space-y-1.5">
        <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Create account</h1>
        <p className="text-sm text-[var(--color-text-secondary)]">
          Start tracking your finances with AI assistance
        </p>
      </motion.div>

      <motion.form variants={staggerItem} onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <Input label="First name" value={form.first_name} onChange={set("first_name")} required placeholder="Aayush" />
          <Input label="Last name"  value={form.last_name}  onChange={set("last_name")}  required placeholder="Doe" />
        </div>

        <Input
          label="Email address"
          type="email"
          value={form.email}
          onChange={set("email")}
          required
          placeholder="you@example.com"
        />

        <Input
          label="Password"
          type={showPw ? "text" : "password"}
          value={form.password}
          onChange={set("password")}
          required
          placeholder="Min. 8 chars, 1 uppercase, 1 digit"
          rightIcon={
            <button type="button" onClick={() => setShowPw((s) => !s)} tabIndex={-1} className="text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)] transition-colors">
              {showPw ? <EyeOff size={15} /> : <Eye size={15} />}
            </button>
          }
        />

        <Input
          label="Confirm password"
          type={showPw ? "text" : "password"}
          value={form.confirm_password}
          onChange={set("confirm_password")}
          required
          placeholder="Repeat password"
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

        <Button type="submit" size="lg" isLoading={loading} leftIcon={<UserPlus size={15} />} className="w-full">
          Create account
        </Button>
      </motion.form>

      <motion.p variants={staggerItem} className="text-sm text-center text-[var(--color-text-secondary)]">
        Already have an account?{" "}
        <Link href="/login" className="text-[var(--color-accent-light)] hover:text-[var(--color-accent)] font-medium transition-colors">
          Sign in
        </Link>
      </motion.p>
    </motion.div>
  )
}
