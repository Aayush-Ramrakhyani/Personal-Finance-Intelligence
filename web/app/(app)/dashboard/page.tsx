/*
 * (app)/dashboard/page.tsx
 * Main dashboard that fetches overview stats, cash-flow area chart, category pie,
 * budget progress, recent transactions, and account balances in a single parallel request.
 */

"use client"

import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import {
  TrendingUp, TrendingDown, Minus, ArrowUpRight, ArrowDownRight,
  Wallet, RefreshCw, AlertTriangle,
} from "lucide-react"
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from "recharts"
import { analyticsApi } from "@/lib/api/analytics"
import { transactionsApi } from "@/lib/api/transactions"
import { budgetsApi } from "@/lib/api/budgets"
import type { OverviewResponse, CashFlowMonth, CategoryBreakdown, Budget, Transaction } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Stagger, StaggerItem } from "@/components/motion/stagger"
import { AnimatedNumber } from "@/components/motion/animated-number"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { CardSkeleton, ChartSkeleton, TransactionSkeleton } from "@/components/ui/skeleton"
import { ProgressBar } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { formatCurrency, formatDate, getCategoryColor } from "@/lib/utils"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"

export default function DashboardPage() {
  const [overview, setOverview]     = useState<OverviewResponse | null>(null)
  const [cashFlow, setCashFlow]     = useState<CashFlowMonth[]>([])
  const [categories, setCategories] = useState<CategoryBreakdown[]>([])
  const [budgets, setBudgets]       = useState<Budget[]>([])
  const [recent, setRecent]         = useState<Transaction[]>([])
  const [loading, setLoading]       = useState(true)
  const [error, setError]           = useState("")

  useEffect(() => {
    Promise.all([
      analyticsApi.overview(),
      analyticsApi.cashFlow(6),
      analyticsApi.categories(undefined, undefined, "expense"),
      budgetsApi.list(),
      transactionsApi.list({ limit: 5, sort_order: "desc" }),
    ])
      .then(([ov, cf, cat, bud, tx]) => {
        setOverview(ov.data)
        setCashFlow(cf.data)
        setCategories(cat.data.slice(0, 6))
        setBudgets(bud.data.filter(b => b.is_active).slice(0, 4)) // show up to 4 active budgets in the summary widget
        setRecent(tx.data)
      })
      .catch(() => setError("Failed to load dashboard data."))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {Array.from({ length: 4 }).map((_, i) => <CardSkeleton key={i} />)}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ChartSkeleton height="h-64" />
        <ChartSkeleton height="h-64" />
      </div>
    </div>
  )

  if (error) return (
    <div className="flex flex-col items-center justify-center h-64 gap-3">
      <AlertTriangle className="text-[var(--color-warning)]" size={32} />
      <p className="text-[var(--color-text-secondary)]">{error}</p>
    </div>
  )

  const income   = parseFloat(overview?.total_income   ?? "0") // default to 0 when overview not yet loaded
  const expenses = parseFloat(overview?.total_expenses ?? "0")
  const net      = parseFloat(overview?.net_cash_flow  ?? "0")
  const savings  = parseFloat(overview?.savings_rate   ?? "0")

  const chartData = cashFlow.map(m => ({
    name:     m.month_label,
    Income:   parseFloat(m.income),
    Expenses: parseFloat(m.expenses),
    Net:      parseFloat(m.net),
  }))

  const pieData = categories.map(c => ({
    name:  c.category_name,
    value: parseFloat(c.amount),
    color: getCategoryColor(c.category_name),
  }))

  const summaryCards = [
    {
      label: "Total Income",
      value: income,
      icon: ArrowUpRight,
      color: "var(--color-income)",
      bg: "rgba(15,201,140,0.10)",
      trend: "up" as const,
    },
    {
      label: "Total Expenses",
      value: expenses,
      icon: ArrowDownRight,
      color: "var(--color-expense)",
      bg: "rgba(242,93,118,0.10)",
      trend: "down" as const,
    },
    {
      label: "Net Cash Flow",
      value: Math.abs(net),
      icon: net >= 0 ? TrendingUp : TrendingDown,
      color: net >= 0 ? "var(--color-income)" : "var(--color-expense)",
      bg: net >= 0 ? "rgba(15,201,140,0.10)" : "rgba(242,93,118,0.10)",
      trend: net >= 0 ? "up" as const : "down" as const,
    },
    {
      label: "Savings Rate",
      value: savings,
      icon: Wallet,
      color: "var(--color-accent-light)",
      bg: "rgba(124,110,246,0.10)",
      isPercent: true,
      trend: savings > 20 ? "up" as const : "stable" as const,
    },
  ]

  return (
    <PageTransition>
      <div className="space-y-6 max-w-[1400px]">

        {/* ── Summary cards ── */}
        <Stagger className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {summaryCards.map((card) => (
            <StaggerItem key={card.label}>
              <Card hover glow={card.trend === "up" && card.label === "Total Income" ? "income" : "none"}>
                <CardContent className="pt-5">
                  <div className="flex items-start justify-between mb-4">
                    <p className="text-xs font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">
                      {card.label}
                    </p>
                    <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                      style={{ backgroundColor: card.bg }}>
                      <card.icon size={15} style={{ color: card.color }} />
                    </div>
                  </div>
                  <p className="text-2xl font-bold text-[var(--color-text-primary)] tabular-nums">
                    {card.isPercent ? (
                      <AnimatedNumber
                        value={card.value}
                        formatFn={(n) => n.toFixed(1)}
                        suffix="%"
                      />
                    ) : (
                      <AnimatedNumber
                        value={card.value}
                        formatFn={(n) => formatCurrency(n, "INR", true)}
                      />
                    )}
                  </p>
                  <div className="mt-1.5 flex items-center gap-1">
                    {card.trend === "up" && <TrendingUp size={11} className="text-[var(--color-income)]" />}
                    {card.trend === "down" && <TrendingDown size={11} className="text-[var(--color-expense)]" />}
                    {card.trend === "stable" && <Minus size={11} className="text-[var(--color-text-muted)]" />}
                    <span className="text-[10px] text-[var(--color-text-muted)]">This month</span>
                  </div>
                </CardContent>
              </Card>
            </StaggerItem>
          ))}
        </Stagger>

        {/* ── Charts row ── */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Cash flow area chart */}
          <motion.div
            variants={fadeInUp}
            initial="hidden"
            animate="visible"
            className="lg:col-span-2"
          >
            <Card>
              <CardHeader>
                <CardTitle>Cash Flow — 6 Months</CardTitle>
                <div className="flex items-center gap-3 text-xs">
                  <span className="flex items-center gap-1.5 text-[var(--color-income)]">
                    <span className="w-2 h-2 rounded-full bg-[var(--color-income)]" />Income
                  </span>
                  <span className="flex items-center gap-1.5 text-[var(--color-expense)]">
                    <span className="w-2 h-2 rounded-full bg-[var(--color-expense)]" />Expenses
                  </span>
                </div>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={220}>
                  <AreaChart data={chartData} margin={{ top: 5, right: 5, bottom: 0, left: 0 }}>
                    <defs>
                      <linearGradient id="incomeGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%"  stopColor="var(--color-income)"  stopOpacity={0.25} />
                        <stop offset="95%" stopColor="var(--color-income)"  stopOpacity={0}    />
                      </linearGradient>
                      <linearGradient id="expenseGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%"  stopColor="var(--color-expense)" stopOpacity={0.25} />
                        <stop offset="95%" stopColor="var(--color-expense)" stopOpacity={0}    />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="name" tick={{ fontSize: 12 }} tickLine={false} axisLine={false} />
                    <YAxis tickFormatter={(v) => `₹${(v/1000).toFixed(0)}k`} tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                    <Tooltip
                      formatter={(v: unknown) => formatCurrency(v as number)}
                      contentStyle={{
                        backgroundColor: "var(--color-elevated)",
                        border: "1px solid var(--color-border-strong)",
                        borderRadius: "12px",
                        color: "var(--color-text-primary)",
                        fontSize: 12,
                      }}
                    />
                    <Area type="monotone" dataKey="Income"   stroke="var(--color-income)"  strokeWidth={2} fill="url(#incomeGrad)"  animationDuration={1200} />
                    <Area type="monotone" dataKey="Expenses" stroke="var(--color-expense)" strokeWidth={2} fill="url(#expenseGrad)" animationDuration={1400} />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </motion.div>

          {/* Pie chart */}
          <motion.div variants={fadeInUp} initial="hidden" animate="visible" style={{ transitionDelay: "0.1s" }}>
            <Card className="h-full">
              <CardHeader>
                <CardTitle>Spend by Category</CardTitle>
              </CardHeader>
              <CardContent>
                {pieData.length === 0 ? (
                  <div className="flex items-center justify-center h-40 text-sm text-[var(--color-text-muted)]">
                    No expense data
                  </div>
                ) : (
                  <>
                    <ResponsiveContainer width="100%" height={160}>
                      <PieChart>
                        <Pie
                          data={pieData}
                          cx="50%" cy="50%"
                          innerRadius={45} outerRadius={70}
                          paddingAngle={3}
                          dataKey="value"
                          animationBegin={200}
                          animationDuration={1000}
                        >
                          {pieData.map((entry, i) => (
                            <Cell key={i} fill={entry.color} stroke="transparent" />
                          ))}
                        </Pie>
                        <Tooltip
                          formatter={(v: unknown) => formatCurrency(v as number)}
                          contentStyle={{
                            backgroundColor: "var(--color-elevated)",
                            border: "1px solid var(--color-border-strong)",
                            borderRadius: "12px",
                            fontSize: 12,
                          }}
                        />
                      </PieChart>
                    </ResponsiveContainer>
                    <div className="space-y-2 mt-2">
                      {pieData.slice(0, 4).map((d) => (
                        <div key={d.name} className="flex items-center justify-between text-xs">
                          <span className="flex items-center gap-2 text-[var(--color-text-secondary)]">
                            <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: d.color }} />
                            {d.name}
                          </span>
                          <span className="font-medium text-[var(--color-text-primary)] tabular-nums">
                            {formatCurrency(d.value, "INR", true)}
                          </span>
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </CardContent>
            </Card>
          </motion.div>
        </div>

        {/* ── Budgets + Recent transactions ── */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Budgets */}
          <motion.div variants={fadeInUp} initial="hidden" animate="visible">
            <Card>
              <CardHeader>
                <CardTitle>Budget Status</CardTitle>
                <RefreshCw size={14} className="text-[var(--color-text-muted)]" />
              </CardHeader>
              <CardContent>
                {budgets.length === 0 ? (
                  <p className="text-sm text-[var(--color-text-muted)] text-center py-8">
                    No active budgets. <a href="/budgets" className="text-[var(--color-accent-light)]">Create one →</a>
                  </p>
                ) : (
                  <motion.div
                    variants={staggerContainer(0.07)}
                    initial="hidden"
                    animate="visible"
                    className="space-y-4"
                  >
                    {budgets.map((b) => {
                      const pct = parseFloat(b.percentage_used)
                      return (
                        <motion.div key={b.id} variants={staggerItem} className="space-y-1.5">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-medium text-[var(--color-text-primary)]">
                                {b.category_name}
                              </span>
                              {b.is_over_budget && (
                                <Badge variant="expense" dot>Over</Badge>
                              )}
                              {!b.is_over_budget && b.alert_level && (
                                <Badge variant="warning" dot>Alert</Badge>
                              )}
                            </div>
                            <span className="text-xs text-[var(--color-text-muted)] tabular-nums">
                              {formatCurrency(b.spent)} / {formatCurrency(b.amount)}
                            </span>
                          </div>
                          <ProgressBar
                            value={pct}
                            variant={b.is_over_budget ? "expense" : pct >= 75 ? "warning" : "income"}
                          />
                        </motion.div>
                      )
                    })}
                  </motion.div>
                )}
              </CardContent>
            </Card>
          </motion.div>

          {/* Recent transactions */}
          <motion.div variants={fadeInUp} initial="hidden" animate="visible">
            <Card>
              <CardHeader>
                <CardTitle>Recent Transactions</CardTitle>
                <a href="/transactions" className="text-xs text-[var(--color-accent-light)] hover:text-[var(--color-accent)] transition-colors">
                  View all →
                </a>
              </CardHeader>
              <CardContent>
                {recent.length === 0 ? (
                  <p className="text-sm text-[var(--color-text-muted)] text-center py-8">
                    No transactions yet. <a href="/import" className="text-[var(--color-accent-light)]">Import CSV →</a>
                  </p>
                ) : (
                  <motion.div
                    variants={staggerContainer(0.06)}
                    initial="hidden"
                    animate="visible"
                    className="space-y-2"
                  >
                    {recent.map((tx) => (
                      <motion.div
                        key={tx.id}
                        variants={staggerItem}
                        className="flex items-center gap-3 p-3 rounded-xl hover:bg-[var(--color-elevated)] transition-colors cursor-pointer"
                      >
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
                          tx.type === "income"
                            ? "bg-[rgba(15,201,140,0.12)] text-[var(--color-income)]"
                            : tx.type === "transfer"
                            ? "bg-[rgba(167,139,250,0.12)] text-[var(--color-transfer)]"
                            : "bg-[rgba(242,93,118,0.12)] text-[var(--color-expense)]"
                        }`}>
                          {tx.type === "income" ? <ArrowUpRight size={15} /> : <ArrowDownRight size={15} />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-[var(--color-text-primary)] truncate">
                            {tx.merchant ?? tx.description ?? "Transaction"}
                          </p>
                          <p className="text-[11px] text-[var(--color-text-muted)]">
                            {formatDate(tx.transaction_date, "short")}
                            {tx.category && ` · ${tx.category.name}`}
                          </p>
                        </div>
                        <span className={`text-sm font-semibold tabular-nums shrink-0 ${
                          tx.type === "income" ? "text-[var(--color-income)]" : "text-[var(--color-text-primary)]"
                        }`}>
                          {tx.type === "income" ? "+" : "−"}{formatCurrency(tx.amount, tx.currency)}
                        </span>
                      </motion.div>
                    ))}
                  </motion.div>
                )}
              </CardContent>
            </Card>
          </motion.div>
        </div>

        {/* ── Account balances ── */}
        {overview && overview.account_balances.length > 0 && (
          <motion.div variants={fadeInUp} initial="hidden" animate="visible">
            <Card>
              <CardHeader>
                <CardTitle>Account Balances</CardTitle>
              </CardHeader>
              <CardContent>
                <Stagger className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                  {overview.account_balances.map((acc) => (
                    <StaggerItem key={acc.account_id}>
                      <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-elevated)] p-4">
                        <p className="text-xs text-[var(--color-text-muted)] mb-1 truncate">{acc.account_name}</p>
                        <p className="text-base font-bold text-[var(--color-text-primary)] tabular-nums">
                          <AnimatedNumber
                            value={parseFloat(acc.balance)}
                            formatFn={(n) => formatCurrency(n, "INR", true)}
                          />
                        </p>
                        <p className="text-[10px] text-[var(--color-text-muted)] mt-0.5 capitalize">{acc.account_type}</p>
                      </div>
                    </StaggerItem>
                  ))}
                </Stagger>
              </CardContent>
            </Card>
          </motion.div>
        )}
      </div>
    </PageTransition>
  )
}
