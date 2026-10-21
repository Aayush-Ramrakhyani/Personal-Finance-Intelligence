"use client"

import { useEffect, useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Plus, Trash2, Edit2, AlertTriangle, Check } from "lucide-react"
import { budgetsApi } from "@/lib/api/budgets"
import { categoriesApi } from "@/lib/api/categories"
import type { Budget, Category } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Stagger, StaggerItem } from "@/components/motion/stagger"
import { AnimatedNumber } from "@/components/motion/animated-number"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Select } from "@/components/ui/select"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { ProgressBar, CircularProgress } from "@/components/ui/progress"
import { CardSkeleton } from "@/components/ui/skeleton"
import { Dialog } from "@/components/ui/dialog"
import { formatCurrency, cn } from "@/lib/utils"
import { staggerContainer, staggerItem } from "@/lib/motion"

export default function BudgetsPage() {
  const [budgets, setBudgets]     = useState<Budget[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading]     = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [saving, setSaving]       = useState(false)
  const [deleteId, setDeleteId]   = useState<string | null>(null)

  const [form, setForm] = useState({
    category_id: "",
    amount: "",
    period: "monthly",
  })

  useEffect(() => {
    Promise.all([budgetsApi.list(), categoriesApi.list("expense")])
      .then(([b, c]) => { setBudgets(b.data); setCategories(c.data) })
      .finally(() => setLoading(false))
  }, [])

  async function handleCreate() {
    if (!form.category_id || !form.amount) return
    setSaving(true)
    try {
      const res = await budgetsApi.create({
        category_id: form.category_id,
        amount: parseFloat(form.amount),
        period: form.period,
      })
      setBudgets(b => [res.data, ...b])
      setShowCreate(false)
      setForm({ category_id: "", amount: "", period: "monthly" })
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(id: string) {
    await budgetsApi.delete(id)
    setBudgets(b => b.filter(x => x.id !== id))
    setDeleteId(null)
  }

  if (loading) return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {Array.from({ length: 6 }).map((_, i) => <CardSkeleton key={i} />)}
    </div>
  )

  const totalBudgeted = budgets.reduce((s, b) => s + parseFloat(b.amount), 0)
  const totalSpent    = budgets.reduce((s, b) => s + parseFloat(b.spent), 0)
  const overBudget    = budgets.filter(b => b.is_over_budget).length

  return (
    <PageTransition>
      <div className="space-y-6 max-w-[1200px]">

        {/* ── Header with summary ── */}
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="flex gap-4">
            <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] px-4 py-3">
              <p className="text-xs text-[var(--color-text-muted)]">Total budgeted</p>
              <p className="text-lg font-bold text-[var(--color-text-primary)] tabular-nums">
                <AnimatedNumber value={totalBudgeted} formatFn={n => formatCurrency(n, "INR", true)} />
              </p>
            </div>
            <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] px-4 py-3">
              <p className="text-xs text-[var(--color-text-muted)]">Total spent</p>
              <p className="text-lg font-bold tabular-nums" style={{
                color: totalSpent > totalBudgeted ? "var(--color-expense)" : "var(--color-text-primary)"
              }}>
                <AnimatedNumber value={totalSpent} formatFn={n => formatCurrency(n, "INR", true)} />
              </p>
            </div>
            {overBudget > 0 && (
              <div className="rounded-xl border border-[rgba(242,93,118,0.25)] bg-[rgba(242,93,118,0.08)] px-4 py-3 flex items-center gap-2">
                <AlertTriangle size={14} className="text-[var(--color-expense)]" />
                <div>
                  <p className="text-xs text-[var(--color-expense)]">Over budget</p>
                  <p className="text-base font-bold text-[var(--color-expense)]">{overBudget}</p>
                </div>
              </div>
            )}
          </div>
          <Button leftIcon={<Plus size={14} />} onClick={() => setShowCreate(true)}>
            New Budget
          </Button>
        </div>

        {/* ── Budget cards ── */}
        {budgets.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-52 rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] gap-3">
            <p className="text-[var(--color-text-muted)]">No budgets yet</p>
            <Button leftIcon={<Plus size={14} />} onClick={() => setShowCreate(true)}>Create your first budget</Button>
          </div>
        ) : (
          <Stagger className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {budgets.map((b) => {
              const pct      = parseFloat(b.percentage_used)
              const variant  = b.is_over_budget ? "expense" : pct >= 75 ? "warning" : "income"
              return (
                <StaggerItem key={b.id}>
                  <Card hover glow={b.is_over_budget ? "expense" : "none"} className="p-5 space-y-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-semibold text-[var(--color-text-primary)]">{b.category_name}</p>
                        <p className="text-xs text-[var(--color-text-muted)] capitalize">{b.period}</p>
                      </div>
                      <div className="flex items-center gap-1.5">
                        {b.is_over_budget && <Badge variant="expense" dot>Over</Badge>}
                        {!b.is_over_budget && b.alert_level && <Badge variant="warning" dot>{b.alert_level}%</Badge>}
                        <button
                          onClick={() => setDeleteId(b.id)}
                          className="p-1 rounded-md hover:bg-[rgba(242,93,118,0.10)] text-[var(--color-text-muted)] hover:text-[var(--color-expense)] transition-colors"
                        >
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </div>

                    <div className="flex items-center gap-4">
                      <CircularProgress value={pct} size={64} strokeWidth={5} variant={variant}>
                        <span className="text-[10px] font-bold tabular-nums" style={{
                          color: variant === "expense" ? "var(--color-expense)" : variant === "warning" ? "var(--color-warning)" : "var(--color-income)"
                        }}>
                          {pct.toFixed(0)}%
                        </span>
                      </CircularProgress>

                      <div className="flex-1 space-y-1">
                        <div className="flex justify-between text-xs">
                          <span className="text-[var(--color-text-muted)]">Spent</span>
                          <span className="text-[var(--color-text-primary)] tabular-nums font-medium">
                            {formatCurrency(b.spent, "INR", true)}
                          </span>
                        </div>
                        <div className="flex justify-between text-xs">
                          <span className="text-[var(--color-text-muted)]">Remaining</span>
                          <span className={cn(
                            "tabular-nums font-medium",
                            b.is_over_budget ? "text-[var(--color-expense)]" : "text-[var(--color-income)]"
                          )}>
                            {b.is_over_budget ? "−" : ""}{formatCurrency(Math.abs(parseFloat(b.remaining)), "INR", true)}
                          </span>
                        </div>
                        <div className="flex justify-between text-xs">
                          <span className="text-[var(--color-text-muted)]">Budget</span>
                          <span className="text-[var(--color-text-secondary)] tabular-nums">
                            {formatCurrency(b.amount, "INR", true)}
                          </span>
                        </div>
                      </div>
                    </div>

                    <ProgressBar value={pct} variant={variant} size="sm" />
                  </Card>
                </StaggerItem>
              )
            })}
          </Stagger>
        )}
      </div>

      {/* Create dialog */}
      <Dialog open={showCreate} onClose={() => setShowCreate(false)} title="Create Budget" size="sm">
        <div className="space-y-4">
          <Select
            label="Category *"
            placeholder="Select expense category"
            options={categories.map(c => ({ value: c.id, label: c.name }))}
            value={form.category_id}
            onChange={e => setForm(f => ({ ...f, category_id: e.target.value }))}
          />
          <Input
            label="Monthly limit (₹) *"
            type="number"
            placeholder="e.g. 5000"
            value={form.amount}
            onChange={e => setForm(f => ({ ...f, amount: e.target.value }))}
            min="1"
          />
          <Select
            label="Period"
            options={[
              { value: "monthly", label: "Monthly" },
              { value: "weekly",  label: "Weekly"  },
              { value: "yearly",  label: "Yearly"  },
            ]}
            value={form.period}
            onChange={e => setForm(f => ({ ...f, period: e.target.value }))}
          />
          <div className="flex gap-2 pt-1">
            <Button variant="secondary" size="sm" onClick={() => setShowCreate(false)} className="flex-1">Cancel</Button>
            <Button size="sm" isLoading={saving} disabled={!form.category_id || !form.amount} leftIcon={<Check size={13} />} onClick={handleCreate} className="flex-1">
              Create
            </Button>
          </div>
        </div>
      </Dialog>

      {/* Delete confirm */}
      <Dialog open={!!deleteId} onClose={() => setDeleteId(null)} title="Delete Budget" size="sm"
        description="This will permanently delete the budget. Your transaction history is unaffected.">
        <div className="flex gap-2">
          <Button variant="secondary" size="sm" onClick={() => setDeleteId(null)} className="flex-1">Cancel</Button>
          <Button variant="danger" size="sm" leftIcon={<Trash2 size={13} />} onClick={() => deleteId && handleDelete(deleteId)} className="flex-1">
            Delete
          </Button>
        </div>
      </Dialog>
    </PageTransition>
  )
}
