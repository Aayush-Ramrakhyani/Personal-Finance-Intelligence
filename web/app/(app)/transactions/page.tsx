/*
 * (app)/transactions/page.tsx
 * Paginated, filterable transaction list — supports search with debounce, type/category/
 * date filters, sort toggling, and links to individual transaction detail pages.
 */

"use client"

import { useEffect, useState, useCallback } from "react"
import Link from "next/link"
import { motion, AnimatePresence } from "framer-motion"
import {
  Search, Filter, ArrowUpRight, ArrowDownRight, ArrowLeftRight,
  ChevronLeft, ChevronRight, X, SlidersHorizontal,
} from "lucide-react"
import { transactionsApi } from "@/lib/api/transactions"
import { categoriesApi } from "@/lib/api/categories"
import type { Transaction, TransactionFilters, Category } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Stagger, StaggerItem } from "@/components/motion/stagger"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select } from "@/components/ui/select"
import { TransactionSkeleton } from "@/components/ui/skeleton"
import { formatCurrency, formatDate, cn } from "@/lib/utils"
import { staggerContainer, staggerItem, listItemVariants } from "@/lib/motion"

const TYPE_OPTIONS = [
  { value: "", label: "All types" },
  { value: "income",   label: "Income"   },
  { value: "expense",  label: "Expense"  },
  { value: "transfer", label: "Transfer" },
]

const SORT_OPTIONS = [
  { value: "transaction_date", label: "Date" },
  { value: "amount",           label: "Amount" },
  { value: "merchant",         label: "Merchant" },
]

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [total, setTotal]               = useState(0)
  const [pages, setPages]               = useState(1)
  const [loading, setLoading]           = useState(true)
  const [categories, setCategories]     = useState<Category[]>([])
  const [showFilters, setShowFilters]   = useState(false)

  const [filters, setFilters] = useState<TransactionFilters>({
    page: 1, limit: 20, sort_by: "transaction_date", sort_order: "desc",
  })
  const [search, setSearch]     = useState("")
  const [searchDebounced, setSearchDebounced] = useState("")

  /* Debounce search */
  useEffect(() => {
    const t = setTimeout(() => setSearchDebounced(search), 400) // 400 ms debounce before firing API search
    return () => clearTimeout(t)
  }, [search])

  useEffect(() => {
    setFilters(f => ({ ...f, search: searchDebounced || undefined, page: 1 }))
  }, [searchDebounced])

  useEffect(() => {
    categoriesApi.list().then(r => setCategories(r.data)).catch(() => {})
  }, [])

  const fetchTransactions = useCallback(() => {
    setLoading(true)
    transactionsApi.list(filters)
      .then(r => {
        setTransactions(r.data)
        setTotal(r.total)
        setPages(r.pages)
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [filters])

  useEffect(() => { fetchTransactions() }, [fetchTransactions])

  const setFilter = <K extends keyof TransactionFilters>(k: K, v: TransactionFilters[K]) =>
    setFilters(f => ({ ...f, [k]: v, page: 1 })) // reset to page 1 whenever any filter changes

  const clearFilters = () =>
    setFilters({ page: 1, limit: 20, sort_by: "transaction_date", sort_order: "desc" })

  const hasActiveFilters = !!(filters.type || filters.category_id || filters.start_date || filters.end_date)

  return (
    <PageTransition>
      <div className="space-y-4 max-w-[1200px]">

        {/* ── Toolbar ── */}
        <div className="flex flex-wrap gap-3 items-center">
          <div className="flex-1 min-w-[200px]">
            <Input
              placeholder="Search merchants, descriptions…"
              leftIcon={<Search size={14} />}
              value={search}
              onChange={e => setSearch(e.target.value)}
              rightIcon={search ? (
                <button onClick={() => setSearch("")} className="hover:text-[var(--color-text-primary)] transition-colors">
                  <X size={13} />
                </button>
              ) : undefined}
            />
          </div>

          <Button
            variant="secondary"
            size="sm"
            leftIcon={<SlidersHorizontal size={13} />}
            onClick={() => setShowFilters(s => !s)}
            className={showFilters ? "border-[var(--color-accent)]" : ""}
          >
            Filters
            {hasActiveFilters && (
              <span className="ml-1 w-4 h-4 rounded-full bg-[var(--color-accent)] text-white text-[10px] flex items-center justify-center">
                !
              </span>
            )}
          </Button>

          <Select
            options={SORT_OPTIONS}
            value={filters.sort_by}
            onChange={e => setFilter("sort_by", e.target.value)}
            className="w-36 h-9"
          />

          <Button
            variant="ghost"
            size="sm"
            onClick={() => setFilter("sort_order", filters.sort_order === "desc" ? "asc" : "desc")}
            className="px-2"
          >
            {filters.sort_order === "desc" ? "↓ Newest" : "↑ Oldest"}
          </Button>
        </div>

        {/* ── Filter panel ── */}
        <AnimatePresence>
          {showFilters && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.2 }}
              className="overflow-hidden"
            >
              <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-4">
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
                  <Select
                    label="Type"
                    options={TYPE_OPTIONS}
                    value={filters.type ?? ""}
                    onChange={e => setFilter("type", e.target.value || undefined)}
                  />
                  <Select
                    label="Category"
                    placeholder="All categories"
                    options={categories.map(c => ({ value: c.id, label: c.name }))}
                    value={filters.category_id ?? ""}
                    onChange={e => setFilter("category_id", e.target.value || undefined)}
                  />
                  <Input
                    label="From"
                    type="date"
                    value={filters.start_date ?? ""}
                    onChange={e => setFilter("start_date", e.target.value || undefined)}
                  />
                  <Input
                    label="To"
                    type="date"
                    value={filters.end_date ?? ""}
                    onChange={e => setFilter("end_date", e.target.value || undefined)}
                  />
                  <div className="flex items-end">
                    <Button variant="ghost" size="sm" onClick={clearFilters} className="w-full">
                      <X size={13} /> Clear
                    </Button>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* ── Stats row ── */}
        <div className="flex items-center gap-4 text-xs text-[var(--color-text-muted)]">
          <span>{total.toLocaleString()} transactions</span>
          <span>·</span>
          <span>Page {filters.page} of {pages}</span>
        </div>

        {/* ── Transaction list ── */}
        {loading ? (
          <div className="space-y-2">
            {Array.from({ length: 8 }).map((_, i) => <TransactionSkeleton key={i} />)}
          </div>
        ) : transactions.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] h-52 gap-3">
            <Filter size={28} className="text-[var(--color-text-muted)]" />
            <p className="text-sm text-[var(--color-text-secondary)]">No transactions found</p>
            {hasActiveFilters && (
              <Button variant="ghost" size="sm" onClick={clearFilters}>Clear filters</Button>
            )}
          </div>
        ) : (
          <motion.div
            key={`${filters.page}-${filters.type}-${searchDebounced}`}
            variants={staggerContainer(0.04)}
            initial="hidden"
            animate="visible"
            className="space-y-1.5"
          >
            {transactions.map((tx) => (
              <motion.div key={tx.id} variants={listItemVariants} layout>
                <Link href={`/transactions/${tx.id}`}>
                  <div className="group flex items-center gap-3 p-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] hover:bg-[var(--color-elevated)] hover:border-[var(--color-border-strong)] transition-all duration-150 cursor-pointer">
                    <div className={cn(
                      "w-10 h-10 rounded-xl flex items-center justify-center shrink-0",
                      tx.type === "income"   && "bg-[rgba(15,201,140,0.12)]  text-[var(--color-income)]",
                      tx.type === "expense"  && "bg-[rgba(242,93,118,0.12)]  text-[var(--color-expense)]",
                      tx.type === "transfer" && "bg-[rgba(167,139,250,0.12)] text-[var(--color-transfer)]",
                    )}>
                      {tx.type === "income"   ? <ArrowUpRight size={16} />   :
                       tx.type === "transfer" ? <ArrowLeftRight size={16} /> :
                       <ArrowDownRight size={16} />}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-[var(--color-text-primary)] truncate">
                          {tx.merchant ?? tx.description ?? "Transaction"}
                        </p>
                        {tx.is_recurring && (
                          <Badge variant="info" className="shrink-0">Recurring</Badge>
                        )}
                      </div>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="text-xs text-[var(--color-text-muted)]">
                          {formatDate(tx.transaction_date, "short")}
                        </span>
                        {tx.category && (
                          <>
                            <span className="text-[var(--color-border-strong)]">·</span>
                            <span className="text-xs text-[var(--color-text-secondary)]">{tx.category.name}</span>
                          </>
                        )}
                        {tx.payment_method && (
                          <>
                            <span className="text-[var(--color-border-strong)]">·</span>
                            <span className="text-xs text-[var(--color-text-muted)] capitalize">{tx.payment_method}</span>
                          </>
                        )}
                      </div>
                    </div>

                    <div className="text-right shrink-0">
                      <p className={cn(
                        "text-sm font-semibold tabular-nums",
                        tx.type === "income"   ? "text-[var(--color-income)]"  :
                        tx.type === "transfer" ? "text-[var(--color-transfer)]" :
                        "text-[var(--color-text-primary)]"
                      )}>
                        {tx.type === "income" ? "+" : tx.type === "expense" ? "−" : ""}
                        {formatCurrency(tx.amount, tx.currency)}
                      </p>
                      <Badge
                        variant={tx.type === "income" ? "income" : tx.type === "transfer" ? "transfer" : "expense"}
                        className="mt-1"
                      >
                        {tx.type}
                      </Badge>
                    </div>
                  </div>
                </Link>
              </motion.div>
            ))}
          </motion.div>
        )}

        {/* ── Pagination ── */}
        {pages > 1 && (
          <div className="flex items-center justify-center gap-2 pt-2">
            <Button
              variant="secondary"
              size="sm"
              disabled={(filters.page ?? 1) <= 1}
              onClick={() => setFilter("page", (filters.page ?? 1) - 1)}
              leftIcon={<ChevronLeft size={14} />}
            >
              Prev
            </Button>
            <span className="text-sm text-[var(--color-text-secondary)] px-2">
              {filters.page} / {pages}
            </span>
            <Button
              variant="secondary"
              size="sm"
              disabled={(filters.page ?? 1) >= pages}
              onClick={() => setFilter("page", (filters.page ?? 1) + 1)}
              rightIcon={<ChevronRight size={14} />}
            >
              Next
            </Button>
          </div>
        )}
      </div>
    </PageTransition>
  )
}
