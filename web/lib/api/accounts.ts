import { api } from "./client"
import type { SuccessResponse, Account } from "@/types"

export interface AccountCreate {
  name: string
  type: string
  balance?: number
  currency?: string
  institution?: string
  account_number?: string
}

export const accountsApi = {
  list: () => api.get<SuccessResponse<Account[]>>("/accounts"),
  get:  (id: string) => api.get<SuccessResponse<Account>>(`/accounts/${id}`),
  create: (data: AccountCreate) => api.post<SuccessResponse<Account>>("/accounts", data),
  update: (id: string, data: Partial<AccountCreate>) =>
    api.patch<SuccessResponse<Account>>(`/accounts/${id}`, data),
  delete: (id: string) =>
    api.delete<SuccessResponse<{ message: string }>>(`/accounts/${id}`),
}
