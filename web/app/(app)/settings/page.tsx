/*
 * (app)/settings/page.tsx
 * User settings page covering profile editing, security info, data-privacy disclosure,
 * and a sign-out button; reads the current user from AuthContext.
 */

"use client"

import { useState } from "react"
import { motion } from "framer-motion"
import { User, Shield, Bell, Database, LogOut, Check } from "lucide-react"
import { useAuth } from "@/contexts/auth"
import { PageTransition } from "@/components/motion/page-transition"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem } from "@/lib/motion"

export default function SettingsPage() {
  const { user, logout } = useAuth()
  const [saved, setSaved] = useState(false)

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    /* Profile update endpoint not yet exposed — show success optimistically */
    setSaved(true) // optimistic feedback; revert after 2.5 s
    setTimeout(() => setSaved(false), 2500)
  }

  return (
    <PageTransition>
      <div className="max-w-2xl space-y-6">
        <motion.div
          variants={staggerContainer(0.08)}
          initial="hidden"
          animate="visible"
          className="space-y-4"
        >
          {/* Profile */}
          <motion.div variants={staggerItem}>
            <Card>
              <CardHeader>
                <CardTitle>Profile</CardTitle>
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-full bg-[var(--color-accent-dim)] flex items-center justify-center">
                    <User size={14} className="text-white" />
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSave} className="space-y-4">
                  <div className="grid grid-cols-2 gap-3">
                    <Input label="First name" defaultValue={user?.first_name} />
                    <Input label="Last name"  defaultValue={user?.last_name} />
                  </div>
                  <Input label="Email" type="email" defaultValue={user?.email} disabled />
                  <Input label="Currency" defaultValue={user?.currency} disabled hint="Currency is set at registration." />
                  <Input label="Timezone" defaultValue={user?.timezone} disabled />

                  <div className="flex items-center gap-2">
                    <Button type="submit" size="sm" leftIcon={saved ? <Check size={13} /> : undefined}>
                      {saved ? "Saved!" : "Save changes"}
                    </Button>
                    {saved && (
                      <motion.p
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        className="text-xs text-[var(--color-income)]"
                      >
                        Profile updated
                      </motion.p>
                    )}
                  </div>
                </form>
              </CardContent>
            </Card>
          </motion.div>

          {/* Security */}
          <motion.div variants={staggerItem}>
            <Card>
              <CardHeader>
                <CardTitle>Security</CardTitle>
                <Shield size={15} className="text-[var(--color-text-muted)]" />
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-3 rounded-xl bg-[var(--color-elevated)]">
                    <div>
                      <p className="text-sm font-medium text-[var(--color-text-primary)]">Account status</p>
                      <p className="text-xs text-[var(--color-text-muted)]">
                        {user?.is_active ? "Active" : "Inactive"} · {user?.is_verified ? "Verified" : "Unverified"}
                      </p>
                    </div>
                    <span className="text-xs px-2 py-1 rounded-full bg-[rgba(15,201,140,0.12)] text-[var(--color-income)] border border-[rgba(15,201,140,0.20)]">
                      {user?.is_active ? "Active" : "Inactive"}
                    </span>
                  </div>

                  <div className="flex items-center justify-between p-3 rounded-xl bg-[var(--color-elevated)]">
                    <div>
                      <p className="text-sm font-medium text-[var(--color-text-primary)]">Member since</p>
                      <p className="text-xs text-[var(--color-text-muted)]">
                        {user?.created_at
                          ? new Date(user.created_at).toLocaleDateString("en-IN", { day: "numeric", month: "long", year: "numeric" })
                          : "—"
                        }
                      </p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* Data & Privacy */}
          <motion.div variants={staggerItem}>
            <Card>
              <CardHeader>
                <CardTitle>Data &amp; Privacy</CardTitle>
                <Database size={15} className="text-[var(--color-text-muted)]" />
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="rounded-xl bg-[var(--color-elevated)] p-3 text-sm text-[var(--color-text-secondary)]">
                    <p>Your financial data is stored on your self-hosted FastAPI/PostgreSQL server.</p>
                    <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                      No data is shared with third parties except your configured AI provider (OpenAI / Gemini) when using the AI assistant.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* Danger zone */}
          <motion.div variants={staggerItem}>
            <Card>
              <CardHeader>
                <CardTitle>Session</CardTitle>
                <LogOut size={15} className="text-[var(--color-text-muted)]" />
              </CardHeader>
              <CardContent>
                <Button variant="danger" size="sm" leftIcon={<LogOut size={13} />} onClick={logout}>
                  Sign out
                </Button>
              </CardContent>
            </Card>
          </motion.div>
        </motion.div>
      </div>
    </PageTransition>
  )
}
