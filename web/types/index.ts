/* ─── Common API envelopes ────────────────────────────────────────────────── */
export interface SuccessResponse<T> {
  success: true
  data: T
}

export interface PaginatedResponse<T> {
  success: true
  data: T[]
  total: number
  page: number
  limit: number
  pages: number
}

/* ─── Auth ────────────────────────────────────────────────────────────────── */
export interface User {
  id: string
  email: string
  first_name: string
  last_name: string
  currency: string
  timezone: string
  is_active: boolean
  is_verified: boolean
  onboarding_completed: boolean
  created_at: string
}

export interface TokenResponse {
  access_token: string
  refresh_token: string
  token_type: string
  expires_in: number
}

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  email: string
  password: string
  first_name: string
  last_name: string
  currency?: string
  timezone?: string
}

/* ─── Account ─────────────────────────────────────────────────────────────── */
export interface Account {
  id: string
  user_id: string
  name: string
  type: string
  balance: string
  currency: string
  institution?: string
  account_number?: string
  is_active: boolean
  created_at: string
}

/* ─── Category ────────────────────────────────────────────────────────────── */
export interface Category {
  id: string
  name: string
  type: string
  icon?: string
  color?: string
}

/* ─── Transaction ─────────────────────────────────────────────────────────── */
export interface Transaction {
  id: string
  user_id: string
  account_id: string
  category_id?: string
  category?: Category
  type: "income" | "expense" | "transfer"
  amount: string
  currency: string
  merchant?: string
  description?: string
  transaction_date: string
  payment_method?: string
  notes?: string
  source: string
  external_reference?: string
  is_recurring: boolean
  category_source?: string
  category_confidence?: string
  created_at: string
  updated_at: string
}

export interface TransactionCreate {
  account_id: string
  category_id?: string
  type: "income" | "expense" | "transfer"
  amount: number
  currency?: string
  merchant?: string
  description?: string
  transaction_date: string
  payment_method?: string
  notes?: string
}

export interface TransactionUpdate {
  category_id?: string
  merchant?: string
  description?: string
  transaction_date?: string
  payment_method?: string
  notes?: string
  amount?: number
}

export interface TransactionFilters {
  start_date?: string
  end_date?: string
  category_id?: string
  account_id?: string
  type?: string
  merchant?: string
  min_amount?: number
  max_amount?: number
  payment_method?: string
  search?: string
  page?: number
  limit?: number
  sort_by?: string
  sort_order?: "asc" | "desc"
}

/* ─── Budget ──────────────────────────────────────────────────────────────── */
export interface Budget {
  id: string
  user_id: string
  category_id: string
  category_name?: string
  category_icon?: string
  amount: string
  period: string
  start_date?: string
  end_date?: string
  alert_thresholds: number[]
  is_active: boolean
  created_at: string
  spent: string
  remaining: string
  percentage_used: string
  is_over_budget: boolean
  alert_level?: number
}

export interface BudgetCreate {
  category_id: string
  amount: number
  period?: string
  start_date?: string
  end_date?: string
  alert_thresholds?: number[]
}

export interface BudgetUpdate {
  amount?: number
  alert_thresholds?: number[]
  is_active?: boolean
}

/* ─── Analytics ───────────────────────────────────────────────────────────── */
export interface OverviewResponse {
  total_income: string
  total_expenses: string
  net_cash_flow: string
  savings: string
  savings_rate: string
  transaction_count: number
  account_balances: AccountBalance[]
  start_date: string
  end_date: string
}

export interface AccountBalance {
  account_id: string
  account_name: string
  account_type: string
  balance: string
}

export interface CategoryBreakdown {
  category_id: string
  category_name: string
  category_icon?: string
  type: string
  amount: string
  percentage: string
  transaction_count: number
}

export interface CashFlowMonth {
  year: number
  month: number
  month_label: string
  income: string
  expenses: string
  net: string
}

export interface TrendData {
  months: CashFlowMonth[]
  avg_monthly_income: string
  avg_monthly_expenses: string
  avg_daily_expenses: string
  income_trend: "up" | "down" | "stable"
  expense_trend: "up" | "down" | "stable"
}

export interface Anomaly {
  category_name: string
  category_id: string
  current_amount: string
  average_amount: string
  deviation_percentage: string
  severity: "mild" | "moderate" | "significant"
}

/* ─── Import ──────────────────────────────────────────────────────────────── */
export interface ImportJob {
  id: string
  filename: string
  status: "pending" | "processing" | "completed" | "failed"
  total_rows: number
  processed_rows: number
  imported_rows: number
  duplicate_rows: number
  failed_rows: number
  error_message?: string
  created_at: string
  completed_at?: string
}

export interface DetectedColumns {
  columns: string[]
  suggested_mapping: Record<string, string>
  sample_rows: Record<string, string>[]
}

export interface ColumnMapping {
  date_column: string
  amount_column?: string
  debit_column?: string
  credit_column?: string
  description_column?: string
  merchant_column?: string
  reference_column?: string
  type_column?: string
  account_id: string
  date_format?: string
  default_currency?: string
}

export interface StagedTransaction {
  id: string
  row_number: number
  type: string
  amount: string
  merchant?: string
  description?: string
  transaction_date: string
  external_reference?: string
  is_duplicate: boolean
  duplicate_confidence: string
  suggested_category_name?: string
  category_confidence?: string
  parse_error?: string
  status: string
}

export interface ImportPreview {
  job_id: string
  total_rows: number
  valid_rows: number
  duplicate_rows: number
  error_rows: number
  transactions: StagedTransaction[]
}

/* ─── AI ──────────────────────────────────────────────────────────────────── */
export interface AIConversation {
  id: string
  user_id: string
  title?: string
  message_count: number
  created_at: string
  messages?: AIMessage[]
}

export interface AIMessage {
  id: string
  conversation_id: string
  role: "user" | "assistant"
  content: string
  created_at: string
}

export interface AIInsight {
  id: string
  user_id: string
  type: string
  title: string
  content: string
  severity?: string
  month: number
  year: number
  created_at: string
}

/* ─── Notification ────────────────────────────────────────────────────────── */
export interface Notification {
  id: string
  user_id: string
  type: string
  title: string
  body: string
  data?: Record<string, unknown>
  is_read: boolean
  created_at: string
}

/* ─── UI state helpers ────────────────────────────────────────────────────── */
export type LoadingState = "idle" | "loading" | "success" | "error"

export interface ApiError {
  message: string
  status: number
  detail?: string
}
