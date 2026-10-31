/*
 * (app)/import/page.tsx
 * Multi-step CSV import wizard: Upload → Column Mapping → Transaction Preview → Confirm.
 * Handles drag-and-drop, auto column detection, duplicate exclusion, and final commit.
 */

"use client"

import { useState, useCallback } from "react"
import { motion, AnimatePresence } from "framer-motion"
import {
  Upload, FileText, Table2, CheckCircle2, AlertCircle,
  ChevronRight, X, Check, AlertTriangle, Loader2,
} from "lucide-react"
import { importsApi } from "@/lib/api/imports"
import { accountsApi } from "@/lib/api/accounts"
import type { ImportJob, DetectedColumns, ImportPreview, StagedTransaction } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Button } from "@/components/ui/button"
import { Select } from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import { ProgressBar } from "@/components/ui/progress"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { formatCurrency, formatDate, cn } from "@/lib/utils"
import { staggerContainer, staggerItem, spring } from "@/lib/motion"
import { useEffect } from "react"

type Step = "upload" | "mapping" | "preview" | "confirm" | "done"

const STEPS: { key: Step; label: string; icon: typeof Upload }[] = [
  { key: "upload",  label: "Upload",  icon: Upload       },
  { key: "mapping", label: "Mapping", icon: Table2       },
  { key: "preview", label: "Preview", icon: FileText     },
  { key: "confirm", label: "Confirm", icon: CheckCircle2 },
]

const stepIndex = (s: Step) => STEPS.findIndex(x => x.key === s)

export default function ImportPage() {
  const [step, setStep]       = useState<Step>("upload")
  const [dragging, setDragging] = useState(false)
  const [file, setFile]         = useState<File | null>(null)
  const [job, setJob]           = useState<ImportJob | null>(null)
  const [columns, setColumns]   = useState<DetectedColumns | null>(null)
  const [preview, setPreview]   = useState<ImportPreview | null>(null)
  const [accounts, setAccounts] = useState<{ value: string; label: string }[]>([])
  const [excluded, setExcluded] = useState<Set<string>>(new Set())
  const [result, setResult]     = useState<{ imported: number; duplicates: number; failed: number } | null>(null)
  const [error, setError]       = useState("")
  const [loading, setLoading]   = useState(false)

  const [mapping, setMapping] = useState({
    date_column:        "",
    amount_column:      "",
    debit_column:       "",
    credit_column:      "",
    description_column: "",
    merchant_column:    "",
    account_id:         "",
    date_format:        "",
    default_currency:   "INR",
  })

  useEffect(() => {
    accountsApi.list().then(r => {
      setAccounts(r.data.map(a => ({ value: a.id, label: `${a.name} (${a.type})` })))
    }).catch(() => {})
  }, [])

  const handleFile = useCallback((f: File) => {
    if (!f.name.match(/\.(csv|txt)$/i)) {
      setError("Only CSV files are supported."); return
    }
    setFile(f)
    setError("")
  }, [])

  async function handleUpload() {
    if (!file) return
    setLoading(true); setError("")
    try {
      const res = await importsApi.upload(file)
      setJob(res.data)
      const colRes = await importsApi.detectColumns(res.data.id)
      setColumns(colRes.data)
      /* Pre-fill suggested mapping */
      const s = colRes.data.suggested_mapping
      setMapping(m => ({
        ...m,
        date_column:        s.date_column        ?? "", // pre-fill from backend auto-detection
        amount_column:      s.amount_column      ?? "",
        debit_column:       s.debit_column       ?? "",
        credit_column:      s.credit_column      ?? "",
        description_column: s.description_column ?? "",
        merchant_column:    s.merchant_column    ?? "",
      }))
      setStep("mapping")
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Upload failed.")
    } finally {
      setLoading(false)
    }
  }

  async function handlePreview() {
    if (!job || !mapping.account_id) {
      setError("Please select an account."); return
    }
    setLoading(true); setError("")
    try {
      const res = await importsApi.preview(job.id, {
        date_column:        mapping.date_column,
        amount_column:      mapping.amount_column || undefined,
        debit_column:       mapping.debit_column  || undefined,
        credit_column:      mapping.credit_column || undefined,
        description_column: mapping.description_column || undefined,
        merchant_column:    mapping.merchant_column || undefined,
        account_id:         mapping.account_id,
        date_format:        mapping.date_format || undefined,
        default_currency:   mapping.default_currency,
      })
      setPreview(res.data)
      setExcluded(new Set(res.data.transactions.filter(t => t.is_duplicate).map(t => t.id))) // pre-exclude detected duplicates
      setStep("preview")
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Preview failed.")
    } finally {
      setLoading(false)
    }
  }

  async function handleConfirm() {
    if (!job) return
    setLoading(true); setError("")
    setStep("confirm")
    try {
      const res = await importsApi.confirm(job.id, Array.from(excluded))
      setResult(res.data)
      setStep("done")
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Import failed.")
      setStep("preview")
    } finally {
      setLoading(false)
    }
  }

  const columnOptions = (columns?.columns ?? []).map(c => ({ value: c, label: c }))

  return (
    <PageTransition>
      <div className="max-w-3xl space-y-6">

        {/* ── Progress stepper ── */}
        <div className="flex items-center gap-0">
          {STEPS.map((s, i) => {
            const done    = stepIndex(step) > i
            const current = step === s.key
            return (
              <div key={s.key} className="flex items-center flex-1 last:flex-none">
                <div className="flex flex-col items-center gap-1">
                  <motion.div
                    animate={{
                      backgroundColor: done    ? "var(--color-income)"
                                     : current ? "var(--color-accent)"
                                     : "var(--color-card)",
                      borderColor: done    ? "var(--color-income)"
                                 : current ? "var(--color-accent)"
                                 : "var(--color-border)",
                    }}
                    transition={spring.smooth}
                    className="w-9 h-9 rounded-full border-2 flex items-center justify-center"
                  >
                    {done
                      ? <Check size={14} className="text-white" />
                      : <s.icon size={14} className={current ? "text-white" : "text-[var(--color-text-muted)]"} />
                    }
                  </motion.div>
                  <span className={cn(
                    "text-[10px] font-medium",
                    current ? "text-[var(--color-accent-light)]" : "text-[var(--color-text-muted)]"
                  )}>
                    {s.label}
                  </span>
                </div>
                {i < STEPS.length - 1 && (
                  <motion.div
                    animate={{ backgroundColor: done ? "var(--color-income)" : "var(--color-border)" }}
                    transition={{ duration: 0.3 }}
                    className="flex-1 h-0.5 mb-5 mx-2"
                  />
                )}
              </div>
            )
          })}
        </div>

        {/* ── Error ── */}
        <AnimatePresence>
          {error && (
            <motion.div
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="flex items-center gap-2 rounded-xl border border-[rgba(242,93,118,0.20)] bg-[rgba(242,93,118,0.08)] px-4 py-3 text-sm text-[var(--color-expense)]"
            >
              <AlertCircle size={15} />
              {error}
              <button onClick={() => setError("")} className="ml-auto"><X size={13} /></button>
            </motion.div>
          )}
        </AnimatePresence>

        {/* ── Step: Upload ── */}
        <AnimatePresence mode="wait">
          {step === "upload" && (
            <motion.div key="upload" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -12 }}>
              <Card>
                <CardHeader><CardTitle>Upload CSV File</CardTitle></CardHeader>
                <CardContent>
                  <div
                    onDragOver={e => { e.preventDefault(); setDragging(true) }}
                    onDragLeave={() => setDragging(false)}
                    onDrop={e => {
                      e.preventDefault(); setDragging(false)
                      const f = e.dataTransfer.files[0]
                      if (f) handleFile(f)
                    }}
                    onClick={() => document.getElementById("csv-input")?.click()}
                    className={cn(
                      "relative rounded-xl border-2 border-dashed p-10 text-center cursor-pointer",
                      "transition-colors duration-200",
                      dragging
                        ? "border-[var(--color-accent)] bg-[rgba(124,110,246,0.08)]"
                        : "border-[var(--color-border)] hover:border-[var(--color-border-strong)] hover:bg-[var(--color-elevated)]"
                    )}
                  >
                    <motion.div
                      animate={{ scale: dragging ? 1.08 : 1 }}
                      transition={spring.snappy}
                      className="flex flex-col items-center gap-3"
                    >
                      <div className={cn(
                        "w-14 h-14 rounded-2xl flex items-center justify-center",
                        dragging ? "bg-[rgba(124,110,246,0.15)]" : "bg-[var(--color-elevated)]"
                      )}>
                        <Upload size={22} className={dragging ? "text-[var(--color-accent)]" : "text-[var(--color-text-muted)]"} />
                      </div>
                      <div>
                        <p className="font-medium text-[var(--color-text-primary)]">
                          {file ? file.name : "Drop your CSV file here"}
                        </p>
                        <p className="text-sm text-[var(--color-text-muted)] mt-1">
                          {file
                            ? `${(file.size / 1024).toFixed(1)} KB — ready to upload`
                            : "or click to browse · Max 10 MB · CSV / TXT"
                          }
                        </p>
                      </div>
                    </motion.div>
                    <input
                      id="csv-input"
                      type="file"
                      accept=".csv,.txt"
                      className="hidden"
                      onChange={e => { const f = e.target.files?.[0]; if (f) handleFile(f) }}
                    />
                  </div>

                  <div className="mt-4 flex justify-end">
                    <Button
                      disabled={!file}
                      isLoading={loading}
                      rightIcon={<ChevronRight size={14} />}
                      onClick={handleUpload}
                    >
                      Upload & Detect Columns
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          )}

          {/* ── Step: Mapping ── */}
          {step === "mapping" && columns && (
            <motion.div key="mapping" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card>
                <CardHeader>
                  <CardTitle>Map Columns</CardTitle>
                  <Badge variant="info">{columns.columns.length} columns detected</Badge>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <Select
                      label="Account *"
                      placeholder="Select account"
                      options={accounts}
                      value={mapping.account_id}
                      onChange={e => setMapping(m => ({ ...m, account_id: e.target.value }))}
                    />
                    <Select
                      label="Date column *"
                      placeholder="Select column"
                      options={columnOptions}
                      value={mapping.date_column}
                      onChange={e => setMapping(m => ({ ...m, date_column: e.target.value }))}
                    />
                    <Select
                      label="Amount column"
                      placeholder="Combined amount col"
                      options={[{ value: "", label: "None (use debit/credit)" }, ...columnOptions]}
                      value={mapping.amount_column}
                      onChange={e => setMapping(m => ({ ...m, amount_column: e.target.value }))}
                    />
                    <Select
                      label="Debit column"
                      placeholder="Optional"
                      options={[{ value: "", label: "None" }, ...columnOptions]}
                      value={mapping.debit_column}
                      onChange={e => setMapping(m => ({ ...m, debit_column: e.target.value }))}
                    />
                    <Select
                      label="Credit column"
                      placeholder="Optional"
                      options={[{ value: "", label: "None" }, ...columnOptions]}
                      value={mapping.credit_column}
                      onChange={e => setMapping(m => ({ ...m, credit_column: e.target.value }))}
                    />
                    <Select
                      label="Description column"
                      placeholder="Optional"
                      options={[{ value: "", label: "None" }, ...columnOptions]}
                      value={mapping.description_column}
                      onChange={e => setMapping(m => ({ ...m, description_column: e.target.value }))}
                    />
                    <Select
                      label="Merchant column"
                      placeholder="Optional"
                      options={[{ value: "", label: "None" }, ...columnOptions]}
                      value={mapping.merchant_column}
                      onChange={e => setMapping(m => ({ ...m, merchant_column: e.target.value }))}
                    />
                    <Select
                      label="Date format"
                      placeholder="Auto-detect"
                      options={[
                        { value: "", label: "Auto-detect" },
                        { value: "%d/%m/%Y", label: "DD/MM/YYYY" },
                        { value: "%m/%d/%Y", label: "MM/DD/YYYY" },
                        { value: "%Y-%m-%d", label: "YYYY-MM-DD" },
                        { value: "%d-%m-%Y", label: "DD-MM-YYYY" },
                        { value: "%d %b %Y", label: "DD Mon YYYY" },
                      ]}
                      value={mapping.date_format}
                      onChange={e => setMapping(m => ({ ...m, date_format: e.target.value }))}
                    />
                  </div>

                  {/* Sample rows */}
                  {columns.sample_rows.length > 0 && (
                    <div className="mt-4 rounded-xl bg-[var(--color-elevated)] p-3 overflow-x-auto">
                      <p className="text-xs text-[var(--color-text-muted)] mb-2">Sample data</p>
                      <table className="text-xs text-[var(--color-text-secondary)] w-full">
                        <thead>
                          <tr className="border-b border-[var(--color-border)]">
                            {columns.columns.map(c => (
                              <th key={c} className="px-2 py-1.5 text-left font-medium text-[var(--color-text-muted)]">{c}</th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {columns.sample_rows.slice(0, 3).map((row, i) => (
                            <tr key={i} className="border-b border-[var(--color-border)] last:border-0">
                              {columns.columns.map(c => (
                                <td key={c} className="px-2 py-1.5 truncate max-w-[120px]">{row[c] ?? "—"}</td>
                              ))}
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}

                  <div className="flex gap-2 mt-4 justify-end">
                    <Button variant="secondary" size="sm" onClick={() => setStep("upload")}>Back</Button>
                    <Button
                      isLoading={loading}
                      disabled={!mapping.date_column || !mapping.account_id}
                      rightIcon={<ChevronRight size={14} />}
                      onClick={handlePreview}
                    >
                      Preview Transactions
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          )}

          {/* ── Step: Preview ── */}
          {step === "preview" && preview && (
            <motion.div key="preview" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card>
                <CardHeader>
                  <CardTitle>Review Transactions</CardTitle>
                  <div className="flex items-center gap-2 text-xs">
                    <Badge variant="income">{preview.valid_rows} valid</Badge>
                    {preview.duplicate_rows > 0 && <Badge variant="warning">{preview.duplicate_rows} duplicates</Badge>}
                    {preview.error_rows > 0 && <Badge variant="expense">{preview.error_rows} errors</Badge>}
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-1.5 max-h-[400px] overflow-y-auto pr-1">
                    {preview.transactions.map((tx) => (
                      <motion.div
                        key={tx.id}
                        layout
                        className={cn(
                          "flex items-center gap-3 p-3 rounded-xl border transition-colors",
                          excluded.has(tx.id)
                            ? "border-[var(--color-border)] bg-[var(--color-card)] opacity-50"
                            : tx.parse_error
                            ? "border-[rgba(242,93,118,0.20)] bg-[rgba(242,93,118,0.05)]"
                            : tx.is_duplicate
                            ? "border-[rgba(245,166,35,0.20)] bg-[rgba(245,166,35,0.05)]"
                            : "border-[var(--color-border)] bg-[var(--color-card)]"
                        )}
                      >
                        <button
                          onClick={() => {
                            setExcluded(s => {
                              const n = new Set(s)
                              n.has(tx.id) ? n.delete(tx.id) : n.add(tx.id)
                              return n
                            })
                          }}
                          className={cn(
                            "w-5 h-5 rounded flex items-center justify-center shrink-0 border transition-colors",
                            excluded.has(tx.id)
                              ? "border-[var(--color-border)] bg-transparent"
                              : "border-[var(--color-accent)] bg-[var(--color-accent)]"
                          )}
                        >
                          {!excluded.has(tx.id) && <Check size={11} className="text-white" />}
                        </button>

                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-[var(--color-text-primary)] truncate">
                            {tx.merchant ?? tx.description ?? `Row ${tx.row_number}`}
                          </p>
                          <div className="flex items-center gap-2 mt-0.5 text-[10px] text-[var(--color-text-muted)]">
                            <span>{formatDate(tx.transaction_date, "short")}</span>
                            {tx.suggested_category_name && (
                              <span className="text-[var(--color-accent-light)]">→ {tx.suggested_category_name}</span>
                            )}
                            {tx.is_duplicate && <span className="text-[var(--color-warning)]">Duplicate</span>}
                            {tx.parse_error && <span className="text-[var(--color-expense)]">{tx.parse_error}</span>}
                          </div>
                        </div>

                        <span className={cn(
                          "text-sm font-semibold tabular-nums shrink-0",
                          tx.type === "income" ? "text-[var(--color-income)]" : "text-[var(--color-text-primary)]"
                        )}>
                          {tx.type === "income" ? "+" : "−"}{formatCurrency(tx.amount)}
                        </span>
                      </motion.div>
                    ))}
                  </div>

                  <div className="mt-4 pt-3 border-t border-[var(--color-border)] flex items-center justify-between">
                    <p className="text-xs text-[var(--color-text-muted)]">
                      {preview.transactions.length - excluded.size} of {preview.transactions.length} will be imported
                    </p>
                    <div className="flex gap-2">
                      <Button variant="secondary" size="sm" onClick={() => setStep("mapping")}>Back</Button>
                      <Button
                        isLoading={loading}
                        disabled={preview.transactions.length - excluded.size === 0}
                        rightIcon={<ChevronRight size={14} />}
                        onClick={handleConfirm}
                      >
                        Confirm Import
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          )}

          {/* ── Step: Confirming ── */}
          {step === "confirm" && (
            <motion.div key="confirm" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex flex-col items-center justify-center h-48 gap-4">
              <Loader2 size={32} className="text-[var(--color-accent)] animate-spin" />
              <p className="text-[var(--color-text-secondary)]">Importing transactions…</p>
            </motion.div>
          )}

          {/* ── Step: Done ── */}
          {step === "done" && result && (
            <motion.div key="done" initial={{ opacity: 0, scale: 0.94 }} animate={{ opacity: 1, scale: 1 }} transition={{ type: "spring", stiffness: 300, damping: 25 }}>
              <Card>
                <CardContent className="pt-8 text-center space-y-4">
                  <div className="flex justify-center">
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: "spring", stiffness: 400, damping: 20, delay: 0.1 }}
                      className="w-16 h-16 rounded-full bg-[rgba(15,201,140,0.15)] flex items-center justify-center"
                    >
                      <CheckCircle2 size={32} className="text-[var(--color-income)]" />
                    </motion.div>
                  </div>

                  <div>
                    <h2 className="text-xl font-bold text-[var(--color-text-primary)]">Import complete!</h2>
                    <p className="text-sm text-[var(--color-text-secondary)] mt-1">
                      Your transactions have been imported and categorised.
                    </p>
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    {[
                      { label: "Imported",   value: result.imported,   color: "var(--color-income)"  },
                      { label: "Duplicates", value: result.duplicates, color: "var(--color-warning)" },
                      { label: "Failed",     value: result.failed,     color: "var(--color-expense)" },
                    ].map(s => (
                      <div key={s.label} className="rounded-xl bg-[var(--color-elevated)] p-3">
                        <p className="text-2xl font-bold tabular-nums" style={{ color: s.color }}>{s.value}</p>
                        <p className="text-xs text-[var(--color-text-muted)] mt-0.5">{s.label}</p>
                      </div>
                    ))}
                  </div>

                  <div className="flex gap-2 justify-center pt-2">
                    <Button variant="secondary" onClick={() => {
                      setStep("upload"); setFile(null); setJob(null); setColumns(null); setPreview(null); setResult(null)
                    }}>
                      Import another
                    </Button>
                    <Button onClick={() => window.location.href = "/transactions"}>
                      View transactions
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </PageTransition>
  )
}
