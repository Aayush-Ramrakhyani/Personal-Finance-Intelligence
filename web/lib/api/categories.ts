import { api } from "./client"
import type { SuccessResponse, Category } from "@/types"

export const categoriesApi = {
  list: (type?: "income" | "expense") =>
    api.get<SuccessResponse<Category[]>>("/categories", { type }),
}
