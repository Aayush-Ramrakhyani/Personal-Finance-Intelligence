/*
 * transactions.ts
 * Transactions API module — paginated list with rich filter/sort params, plus
 * get, create, update, and delete operations for individual transactions.
 */

import { api } from "./client"
import type {
  SuccessResponse, PaginatedResponse,
  Transaction, TransactionCreate, TransactionUpdate, TransactionFilters,
} from "@/types"

export const transactionsApi = {
  list: (filters?: TransactionFilters) =>
    api.get<PaginatedResponse<Transaction>>("/transactions", filters as Record<string, string | number | boolean | undefined | null>),

  get: (id: string) =>
    api.get<SuccessResponse<Transaction>>(`/transactions/${id}`),

  create: (data: TransactionCreate) =>
    api.post<SuccessResponse<Transaction>>("/transactions", data),

  update: (id: string, data: TransactionUpdate) =>
    api.patch<SuccessResponse<Transaction>>(`/transactions/${id}`, data),

  delete: (id: string) =>
    api.delete<SuccessResponse<{ message: string }>>(`/transactions/${id}`),
}
