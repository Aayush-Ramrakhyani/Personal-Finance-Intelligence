"use client"

import { useEffect, useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { TrendingUp, TrendingDown, Minus, AlertTriangle } from "lucide-react"
import {
  BarChart, Bar, LineChart, Line, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from "recharts"
import { analyticsApi } from "@/lib/api/analytics"
import type { TrendData, CategoryBreakdown, Anomaly } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Stagger, StaggerItem } from "@/components/motion/stagger"
import { AnimatedNumber } from "@/components/motion/animated-number"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ChartSkeleton, CardSkeleton } from "@/components/ui/skeleton"
import { Select } from "@/components/ui/select"
import { formatCurrency, getCategoryColor, cn } from "@/lib/utils"
import { fadeInUp } from "@/lib/motion"

const MONTH_OPTIONS = [
  { value: "3",  label: "3 months"  },
  { value: "6",  label: "6 months"  },
  { value: "12", label: "12 months" },
]

export default function AnalyticsPage() {
  const [months, setMonths]       = useState("6")
  const [trends, setTrends]       = useState<TrendData | null>(null)
  const [expenseCats, setExpCats] = useState<CategoryBreakdown[]>([])
  const [incomeCats, setIncCats]  = useState<CategoryBreakdown[]>([])
  const [anomalies, setAnomalies] = useState<Anomaly[]>([])
  const [loading, setLoading]     = useState(true)

  useEffect(() => {
    setLoading(true)
    Promise.all([
      analyticsApi.trends(parseInt(months)),
      analyticsApi.categories(undefined, undefined, "expense"),
      analyticsApi.categories(undefined, undefined, "income"),
      analyticsApi.anomalies(),
    ]).then(([t, ec, ic, an]) => {
      setTrends(t.data)
      setExpCats(ec.data)
      setIncCats(ic.data)
      setAnomalies(an.data)
    }).finally(() => setLoading(false))
  }, [months])

  const trendIcon = (t: string) =>
    t === "up"   ? <TrendingUp   size={14} className="text-[var(--color-income)]"  /> :
    t === "down" ? <TrendingDown size={14} className="text-[var(--color-expense)]" /> :
                  <Minus         size={14} className="text-[var(--color-text-muted)]" />

  const barData = trends?.months.map(m => ({
    name:     m.month_label,
    Income:   parseFloat(m.income),
    Expenses: parseFloat(m.expenses),
    Net:      parseFloat(m.net),
  })) ?? []

  const expPieData = expenseCats.slice(0, 7).map(c => ({
    name: c.category_name, value: parseFloat(c.amount), color: getCategoryColor(c.category_name),
  }))

  return (
    <PageTransition>
      <div className="space-y-6 max-w-[1400px]">

        {/* Toolbar */}
        <div className="flex justify-between items-center">
          <p className="text-sm text-[var(--color-text-muted)]">Spending trends and category breakdown</p>
          <Select
            options={MONTH_OPTIONS}
            value={months}
            onChange={e => setMonths(e.target.value)}
            className="w-36 h-9"
          />
        </div>

        {/* Summary stats */}
        {loading ? (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {Array.from({ length: 4 }).map((_, i) => <CardSkeleton key={i} />)}
          </div>
        ) : trends && (
          <Stagger className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { label: "Avg monthly income",   value: parseFloat(trends.avg_monthly_income),   trend: trends.income_trend,  isIncome: true },
              { label: "Avg monthly expenses", value: parseFloat(trends.avg_monthly_expenses), trend: trends.expense_trend, isIncome: false },
              { label: "Avg daily spend",      value: parseFloat(trends.avg_daily_expenses),   trend: "stable" as const,    isIncome: false },
              { label: "Months analysed",      value: trends.months.length,                    trend: "stable" as const,    raw: true },
            ].map((s) => (
              <StaggerItem key={s.label}>
                <Card>
                  <CardContent className="pt-5">
                    <p className="text-xs text-[var(--color-text-muted)] uppercase tracking-wider mb-3">{s.label}</p>
                    <p className="text-xl font-bold text-[var(--color-text-primary)] tabular-nums">
                      {s.raw
                        ? <AnimatedNumber value={s.value} formatFn={n => Math.round(n).toString()} />
                        : <AnimatedNumber value={s.value} formatFn={n => formatCurrency(n, "INR", true)} />
                      }
                    </p>
                    <div className="flex items-center gap-1 mt-1">
                      {trendIcon(s.trend)}
                      <span className="text-[10px] text-[var(--color-text-muted)] capitalize">{s.trend}</span>
                    </div>
                  </CardContent>
                </Card>
              </StaggerItem>
            ))}
          </Stagger>
        )}

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Bar chart */}
          <motion.div variants={fadeInUp} initial="hidden" animate="visible" className="lg:col-span-2">
            <Card>
              <CardHeader><CardTitle>Income vs Expenses</CardTitle></CardHeader>
              <CardContent>
                {loading ? <ChartSkeleton height="h-56" /> : (
                  <ResponsiveContainer width="100%" height={240}>
                    <BarChart data={barData} margin={{ top: 5, right: 5, bottom: 0, left: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} />
                      <XAxis dataKey="name" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                      <YAxis tickFormatter={v => `₹${(v/1000).toFixed(0)}k`} tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                      <Tooltip
                        formatter={(v: unknown) => formatCurrency(v as number)}
                        contentStyle={{ backgroundColor: "var(--color-elevated)", border: "1px solid var(--color-border-strong)", borderRadius: "12px", fontSize: 12 }}
                      />
                      <Bar dataKey="Income"   fill="var(--color-income)"  radius={[4,4,0,0]} animationDuration={1000} />
                      <Bar dataKey="Expenses" fill="var(--color-expense)" radius={[4,4,0,0]} animationDuration={1200} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </CardContent>
            </Card>
          </motion.div>

          {/* Pie chart */}
          <motion.div variants={fadeInUp} initial="hidden" animate="visible">
            <Card className="h-full">
              <CardHeader><CardTitle>Expense Breakdown</CardTitle></CardHeader>
              <CardContent>
                {loading ? <ChartSkeleton height="h-56" /> : (
                  <>
                    <ResponsiveContainer width="100%" height={180}>
                      <PieChart>
                        <Pie data={expPieData} cx="50%" cy="50%" innerRadius={50} outerRadius={78} paddingAngle={2} dataKey="value" animationBegin={200} animationDuration={900}>
                          {expPieData.map((e, i) => <Cell key={i} fill={e.color} stroke="transparent" />)}
                        </Pie>
                        <Tooltip formatter={(v: unknown) => formatCurrency(v as number)} contentStyle={{ backgroundColor: "var(--color-elevated)", border: "1px solid var(--color-border-strong)", borderRadius: "12px", fontSize: 12 }} />
                      </PieChart>
                    </ResponsiveContainer>
                    <div className="space-y-1.5 mt-1">
                      {expPieData.slice(0, 5).map(d => (
                        <div key={d.name} className="flex items-center justify-between text-xs">
                          <span className="flex items-center gap-2 text-[var(--color-text-secondary)]">
                            <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: d.color }} />
                            {d.name}
                          </span>
                          <span className="tabular-nums text-[var(--color-text-primary)] font-medium">{formatCurrency(d.value, "INR", true)}</span>
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </CardContent>
            </Card>
          </motion.div>
        </div>

        {/* Net trend line */}
        {!loading && barData.length > 0 && (
          <motion.div variants={fadeInUp} initial="hidden" animate="visible">
            <Card>
              <CardHeader><CardTitle>Net Cash Flow Trend</CardTitle></CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={180}>
                  <LineChart data={barData} margin={{ top: 5, right: 5, bottom: 0, left: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="name" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                    <YAxis tickFormatter={v => `₹${(v/1000).toFixed(0)}k`} tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                    <Tooltip formatter={(v: unknown) => formatCurrency(v as number)} contentStyle={{ backgroundColor: "var(--color-elevated)", border: "1px solid var(--color-border-strong)", borderRadius: "12px", fontSize: 12 }} />
                    <Line type="monotone" dataKey="Net" stroke="var(--color-accent)" strokeWidth={2.5} dot={{ fill: "var(--color-accent)", r: 4 }} activeDot={{ r: 6 }} animationDuration={1000} />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </motion.div>
        )}

        {/* Anomalies */}
        {anomalies.length > 0 && (
          <motion.div variants={fadeInUp} initial="hidden" animate="visible">
            <Card>
              <CardHeader>
                <CardTitle>Spending Anomalies</CardTitle>
                <Badge variant="warning" dot>{anomalies.length} detected</Badge>
              </CardHeader>
              <CardContent>
                <Stagger className="space-y-3">
                  {anomalies.map((a) => (
                    <StaggerItem key={a.category_id}>
                      <div className="flex items-center gap-4 p-3 rounded-xl bg-[var(--color-elevated)]">
                        <div className={cn(
                          "w-8 h-8 rounded-lg flex items-center justify-center shrink-0",
                          a.severity === "significant" ? "bg-[rgba(242,93,118,0.15)] text-[var(--color-expense)]"
                          : a.severity === "moderate"   ? "bg-[rgba(245,166,35,0.15)]  text-[var(--color-warning)]"
                          : "bg-[rgba(79,170,255,0.15)] text-[var(--color-info)]"
                        )}>
                          <AlertTriangle size={14} />
                        </div>
                        <div className="flex-1">
                          <p className="text-sm font-medium text-[var(--color-text-primary)]">{a.category_name}</p>
                          <p className="text-xs text-[var(--color-text-muted)]">
                            Current: {formatCurrency(a.current_amount)} · Average: {formatCurrency(a.average_amount)}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-sm font-bold text-[var(--color-expense)] tabular-nums">
                            +{parseFloat(a.deviation_percentage).toFixed(0)}%
                          </p>
                          <Badge variant={a.severity === "significant" ? "expense" : a.severity === "moderate" ? "warning" : "info"}>
                            {a.severity}
                          </Badge>
                        </div>
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
