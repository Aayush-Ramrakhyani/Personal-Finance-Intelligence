/*
 * categories.ts
 * Categories API module — fetches the list of transaction categories, optionally
 * filtered by type (income/expense), used in filter dropdowns and budget creation.
 */

import { api } from "./client"
import type { SuccessResponse, Category } from "@/types"

export const categoriesApi = {
  list: (type?: "income" | "expense") =>
    api.get<SuccessResponse<Category[]>>("/categories", { type }),
}
