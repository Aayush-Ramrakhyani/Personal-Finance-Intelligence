import { api } from "./client"
import type { SuccessResponse, User, TokenResponse, LoginRequest, RegisterRequest } from "@/types"

export const authApi = {
  login: (data: LoginRequest) =>
    api.post<SuccessResponse<{ user: User } & TokenResponse>>("/auth/login", data),

  register: (data: RegisterRequest) =>
    api.post<SuccessResponse<{ user: User } & TokenResponse>>("/auth/register", data),

  refresh: (refresh_token: string) =>
    api.post<SuccessResponse<TokenResponse>>("/auth/refresh", { refresh_token }),

  me: () => api.get<SuccessResponse<User>>("/auth/me"),
}
