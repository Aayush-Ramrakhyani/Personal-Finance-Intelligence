/*
 * imports.ts
 * CSV import API module — uploads a file as multipart FormData, triggers column detection,
 * previews staged transactions, and confirms the final import with exclusion IDs.
 */

import { apiRequest } from "./client"
import type {
  SuccessResponse, ImportJob, DetectedColumns, ColumnMapping, ImportPreview,
} from "@/types"

export const importsApi = {
  upload: (file: File) => {
    const form = new FormData()
    form.append("file", file)
    return apiRequest<SuccessResponse<ImportJob>>("/imports", { method: "POST", body: form })
  },

  getJob: (id: string) =>
    apiRequest<SuccessResponse<ImportJob>>(`/imports/${id}`),

  detectColumns: (id: string) =>
    apiRequest<SuccessResponse<DetectedColumns>>(`/imports/${id}/columns`),

  preview: (id: string, mapping: ColumnMapping) =>
    apiRequest<SuccessResponse<ImportPreview>>(`/imports/${id}/preview`, {
      method: "POST",
      body: JSON.stringify(mapping),
    }),

  confirm: (id: string, excludeIds: string[] = []) =>
    apiRequest<SuccessResponse<{
      imported: number
      duplicates: number
      failed: number
    }>>(`/imports/${id}/confirm`, {
      method: "POST",
      body: JSON.stringify({ exclude_ids: excludeIds }),
    }),
}
