import { api } from "./client"
import type { SuccessResponse, Budget, BudgetCreate, BudgetUpdate } from "@/types"

export const budgetsApi = {
  list: () => api.get<SuccessResponse<Budget[]>>("/budgets"),
  get:  (id: string) => api.get<SuccessResponse<Budget>>(`/budgets/${id}`),
  create: (data: BudgetCreate) => api.post<SuccessResponse<Budget>>("/budgets", data),
  update: (id: string, data: BudgetUpdate) => api.patch<SuccessResponse<Budget>>(`/budgets/${id}`, data),
  delete: (id: string) => api.delete<SuccessResponse<{ message: string }>>(`/budgets/${id}`),
}
