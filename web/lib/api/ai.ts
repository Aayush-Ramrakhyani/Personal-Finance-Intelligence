/*
 * ai.ts
 * AI API module — manages chat conversations, sends user messages to the backend
 * (which proxies GPT-4/Gemini), and fetches or triggers AI spending insights.
 */

import { api } from "./client"
import type {
  SuccessResponse, AIConversation, AIMessage, AIInsight,
} from "@/types"

export const aiApi = {
  listConversations: () =>
    api.get<SuccessResponse<AIConversation[]>>("/ai/conversations"),

  createConversation: (title?: string) =>
    api.post<SuccessResponse<AIConversation>>("/ai/conversations", { title }),

  getConversation: (id: string) =>
    api.get<SuccessResponse<AIConversation>>(`/ai/conversations/${id}`),

  sendMessage: (conversationId: string, content: string) =>
    api.post<SuccessResponse<AIMessage>>(
      `/ai/conversations/${conversationId}/messages`,
      { content }
    ),

  listInsights: () =>
    api.get<SuccessResponse<AIInsight[]>>("/ai/insights"),

  generateInsights: (month?: number, year?: number) =>
    api.post<SuccessResponse<{ generated: number }>>("/ai/insights/generate", { month, year }),
}
