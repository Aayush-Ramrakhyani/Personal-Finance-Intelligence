/*
 * notifications.ts
 * Notifications API module — lists user notifications, fetches the unread count
 * for the topbar badge, and marks individual or all notifications as read.
 */

import { api } from "./client"
import type { SuccessResponse, Notification } from "@/types"

export const notificationsApi = {
  list: (params?: { unread_only?: boolean; limit?: number; offset?: number }) =>
    api.get<SuccessResponse<Notification[]>>("/notifications", params),

  unreadCount: () =>
    api.get<SuccessResponse<{ count: number }>>("/notifications/unread-count"),

  markRead: (ids: string[]) =>
    api.post<SuccessResponse<{ marked_read: number }>>("/notifications/mark-read", {
      notification_ids: ids,
    }),

  markAllRead: () =>
    api.post<SuccessResponse<{ marked_read: number }>>("/notifications/mark-all-read"),
}
