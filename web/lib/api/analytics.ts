import { api } from "./client"
import type {
  SuccessResponse,
  OverviewResponse, CategoryBreakdown, CashFlowMonth, TrendData, Anomaly,
} from "@/types"

export const analyticsApi = {
  overview: (start_date?: string, end_date?: string) =>
    api.get<SuccessResponse<OverviewResponse>>("/analytics/overview", { start_date, end_date }),

  categories: (start_date?: string, end_date?: string, type?: string) =>
    api.get<SuccessResponse<CategoryBreakdown[]>>("/analytics/categories", { start_date, end_date, type }),

  cashFlow: (months?: number) =>
    api.get<SuccessResponse<CashFlowMonth[]>>("/analytics/cash-flow", { months }),

  trends: (months?: number) =>
    api.get<SuccessResponse<TrendData>>("/analytics/trends", { months }),

  anomalies: () =>
    api.get<SuccessResponse<Anomaly[]>>("/analytics/anomalies"),
}
