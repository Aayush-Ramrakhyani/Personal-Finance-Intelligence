import type { Metadata } from "next"
import { Geist, Geist_Mono } from "next/font/google"
import "./globals.css"
import { AuthProvider } from "@/contexts/auth"

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
})

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
})

export const metadata: Metadata = {
  title: "Personal Finance Intelligence",
  description: "AI-powered personal finance platform — import statements, track budgets, and get conversational insights.",
  keywords: ["finance", "budgeting", "AI", "expense tracking", "India"],
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable}`}
      suppressHydrationWarning
    >
      <body className="gradient-bg min-h-dvh">
        <AuthProvider>
          {children}
        </AuthProvider>
      </body>
    </html>
  )
}
