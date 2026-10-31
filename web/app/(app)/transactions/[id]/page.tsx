/*
 * (app)/transactions/[id]/page.tsx
 * Transaction detail page — shows amount hero, metadata grid, notes, and provides
 * inline edit (category, merchant, notes) and permanent delete via modal dialogs.
 */

"use client"

import { useEffect, useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { motion } from "framer-motion"
import {
  ArrowLeft, Calendar, CreditCard, Tag, FileText,
  Edit2, Trash2, Check, X,
} from "lucide-react"
import { transactionsApi } from "@/lib/api/transactions"
import { categoriesApi } from "@/lib/api/categories"
import type { Transaction, Category } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Select } from "@/components/ui/select"
import { Input } from "@/components/ui/input"
import { Skeleton } from "@/components/ui/skeleton"
import { Dialog } from "@/components/ui/dialog"
import { formatCurrency, formatDate, cn } from "@/lib/utils"
import { staggerContainer, staggerItem } from "@/lib/motion"

export default function TransactionDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router  = useRouter()

  const [tx, setTx]               = useState<Transaction | null>(null)
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading]       = useState(true)
  const [editing, setEditing]       = useState(false)
  const [saving, setSaving]         = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [deleting, setDeleting]     = useState(false)

  const [editForm, setEditForm] = useState({
    category_id: "",
    merchant: "",
    notes: "",
  })

  useEffect(() => {
    Promise.all([
      transactionsApi.get(id),
      categoriesApi.list(),
    ]).then(([txRes, catRes]) => {
      setTx(txRes.data)
      setCategories(catRes.data)
      setEditForm({
        category_id: txRes.data.category_id ?? "",
        merchant:    txRes.data.merchant ?? "",
        notes:       txRes.data.notes ?? "",
      })
    }).finally(() => setLoading(false))
  }, [id])

  async function handleSave() {
    if (!tx) return
    setSaving(true)
    try {
      const res = await transactionsApi.update(id, {
        category_id: editForm.category_id || undefined,
        merchant:    editForm.merchant || undefined,
        notes:       editForm.notes || undefined,
      })
      setTx(res.data)
      setEditing(false)
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete() {
    setDeleting(true)
    try {
      await transactionsApi.delete(id)
      router.push("/transactions")
    } finally {
      setDeleting(false)
    }
  }

  if (loading) return (
    <div className="max-w-2xl space-y-4">
      <Skeleton className="h-8 w-32" />
      <Skeleton className="h-48" />
      <Skeleton className="h-32" />
    </div>
  )
  if (!tx) return (
    <p className="text-[var(--color-text-muted)]">Transaction not found.</p>
  )

  const typeColor = {
    income:   "var(--color-income)",
    expense:  "var(--color-expense)",
    transfer: "var(--color-transfer)",
  }[tx.type]

  return (
    <PageTransition>
      <div className="max-w-2xl space-y-5">
        {/* Back button */}
        <button
          onClick={() => router.back()}
          className="flex items-center gap-1.5 text-sm text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] transition-colors"
        >
          <ArrowLeft size={15} /> Back
        </button>

        {/* Main card */}
        <motion.div
          variants={staggerContainer(0.06)}
          initial="hidden"
          animate="visible"
        >
          <Card>
            <CardContent className="pt-6">
              {/* Amount hero */}
              <motion.div variants={staggerItem} className="text-center py-4 border-b border-[var(--color-border)] mb-6">
                <p className="text-xs text-[var(--color-text-muted)] uppercase tracking-wider mb-2">
                  {tx.type === "income" ? "Income received" : tx.type === "transfer" ? "Transfer" : "Expense"}
                </p>
                <p className="text-4xl font-bold tabular-nums" style={{ color: typeColor }}>
                  {tx.type === "income" ? "+" : tx.type === "expense" ? "−" : ""}
                  {formatCurrency(tx.amount, tx.currency)}
                </p>
                <p className="text-sm text-[var(--color-text-secondary)] mt-1">
                  {tx.merchant ?? tx.description ?? "Transaction"}
                </p>
              </motion.div>

              {/* Details grid */}
              <motion.div variants={staggerItem} className="grid grid-cols-2 gap-4">
                {[
                  { icon: Calendar, label: "Date",           value: formatDate(tx.transaction_date, "long") },
                  { icon: Tag,      label: "Category",       value: tx.category?.name ?? "Uncategorised" },
                  { icon: CreditCard,label: "Payment method",value: tx.payment_method ?? "—" },
                  { icon: FileText, label: "Source",         value: tx.source },
                ].map((item) => (
                  <div key={item.label} className="rounded-xl bg-[var(--color-elevated)] p-3.5">
                    <div className="flex items-center gap-2 mb-1">
                      <item.icon size={13} className="text-[var(--color-text-muted)]" />
                      <span className="text-xs text-[var(--color-text-muted)]">{item.label}</span>
                    </div>
                    <p className="text-sm font-medium text-[var(--color-text-primary)] capitalize">
                      {item.value}
                    </p>
                  </div>
                ))}
              </motion.div>

              {tx.notes && (
                <motion.div variants={staggerItem} className="mt-4 rounded-xl bg-[var(--color-elevated)] p-3.5">
                  <p className="text-xs text-[var(--color-text-muted)] mb-1">Notes</p>
                  <p className="text-sm text-[var(--color-text-secondary)]">{tx.notes}</p>
                </motion.div>
              )}

              {tx.external_reference && (
                <motion.div variants={staggerItem} className="mt-2 rounded-xl bg-[var(--color-elevated)] p-3.5">
                  <p className="text-xs text-[var(--color-text-muted)] mb-1">Reference</p>
                  <p className="text-xs font-mono text-[var(--color-text-secondary)] break-all">{tx.external_reference}</p>
                </motion.div>
              )}

              {/* Actions */}
              <motion.div variants={staggerItem} className="flex gap-2 mt-6 pt-4 border-t border-[var(--color-border)]">
                <Button
                  variant="secondary"
                  size="sm"
                  leftIcon={<Edit2 size={13} />}
                  onClick={() => setEditing(true)}
                >
                  Edit
                </Button>
                <Button
                  variant="danger"
                  size="sm"
                  leftIcon={<Trash2 size={13} />}
                  onClick={() => setDeleteOpen(true)}
                >
                  Delete
                </Button>
              </motion.div>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Edit dialog */}
      <Dialog
        open={editing}
        onClose={() => setEditing(false)}
        title="Edit Transaction"
        size="md"
      >
        <div className="space-y-4">
          <Select
            label="Category"
            placeholder="Select category"
            options={categories.map(c => ({ value: c.id, label: c.name }))}
            value={editForm.category_id}
            onChange={e => setEditForm(f => ({ ...f, category_id: e.target.value }))}
          />
          <Input
            label="Merchant"
            value={editForm.merchant}
            onChange={e => setEditForm(f => ({ ...f, merchant: e.target.value }))}
            placeholder="Merchant name"
          />
          <Input
            label="Notes"
            value={editForm.notes}
            onChange={e => setEditForm(f => ({ ...f, notes: e.target.value }))}
            placeholder="Optional note"
          />
          <div className="flex gap-2 pt-2">
            <Button variant="secondary" size="sm" onClick={() => setEditing(false)} className="flex-1">
              Cancel
            </Button>
            <Button size="sm" isLoading={saving} leftIcon={<Check size={13} />} onClick={handleSave} className="flex-1">
              Save
            </Button>
          </div>
        </div>
      </Dialog>

      {/* Delete confirm dialog */}
      <Dialog
        open={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        title="Delete Transaction"
        description="This action cannot be undone. The transaction will be permanently deleted."
        size="sm"
      >
        <div className="flex gap-2">
          <Button variant="secondary" size="sm" onClick={() => setDeleteOpen(false)} className="flex-1">
            Cancel
          </Button>
          <Button variant="danger" size="sm" isLoading={deleting} leftIcon={<Trash2 size={13} />} onClick={handleDelete} className="flex-1">
            Delete
          </Button>
        </div>
      </Dialog>
    </PageTransition>
  )
}
