"use client"

import { useEffect, useRef, useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Send, Plus, Bot, User, Sparkles, RefreshCw, ChevronRight } from "lucide-react"
import { aiApi } from "@/lib/api/ai"
import type { AIConversation, AIMessage, AIInsight } from "@/types"
import { PageTransition } from "@/components/motion/page-transition"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"
import { formatDate, cn } from "@/lib/utils"
import { staggerContainer, staggerItem, spring } from "@/lib/motion"

const SUGGESTED_QUESTIONS = [
  "How much did I spend on food this month?",
  "What are my top spending categories?",
  "Am I on track with my budget?",
  "Show me my savings trend over 3 months",
  "Which subscriptions am I paying for?",
  "Compare my spending to last month",
]

export default function AIPage() {
  const [conversations, setConversations] = useState<AIConversation[]>([])
  const [activeConvId, setActiveConvId]   = useState<string | null>(null)
  const [messages, setMessages]           = useState<AIMessage[]>([])
  const [insights, setInsights]           = useState<AIInsight[]>([])
  const [input, setInput]                 = useState("")
  const [sending, setSending]             = useState(false)
  const [loading, setLoading]             = useState(true)
  const [genInsights, setGenInsights]     = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    Promise.all([aiApi.listConversations(), aiApi.listInsights()])
      .then(([c, ins]) => {
        setConversations(c.data)
        setInsights(ins.data)
        if (c.data.length > 0) loadConversation(c.data[0].id)
      })
      .finally(() => setLoading(false))
  }, [])

  async function loadConversation(id: string) {
    setActiveConvId(id)
    const res = await aiApi.getConversation(id)
    setMessages(res.data.messages ?? [])
  }

  async function startNewConversation() {
    const res = await aiApi.createConversation()
    setConversations(c => [res.data, ...c])
    setActiveConvId(res.data.id)
    setMessages([])
  }

  async function sendMessage(content: string) {
    if (!content.trim() || sending) return
    let convId = activeConvId

    if (!convId) {
      const res = await aiApi.createConversation(content.slice(0, 60))
      setConversations(c => [res.data, ...c])
      convId = res.data.id
      setActiveConvId(convId)
    }

    const userMsg: AIMessage = {
      id: `temp-${Date.now()}`,
      conversation_id: convId,
      role: "user",
      content,
      created_at: new Date().toISOString(),
    }
    setMessages(m => [...m, userMsg])
    setInput("")
    setSending(true)

    try {
      const res = await aiApi.sendMessage(convId, content)
      setMessages(m => [...m, res.data])
    } catch {
      setMessages(m => [...m, {
        id: `err-${Date.now()}`,
        conversation_id: convId!,
        role: "assistant",
        content: "Sorry, I couldn't process your request. Please check that the AI provider is configured.",
        created_at: new Date().toISOString(),
      }])
    } finally {
      setSending(false)
    }
  }

  /* Auto-scroll on new messages */
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages, sending])

  async function generateInsights() {
    setGenInsights(true)
    try {
      await aiApi.generateInsights()
      const res = await aiApi.listInsights()
      setInsights(res.data)
    } finally {
      setGenInsights(false)
    }
  }

  return (
    <PageTransition>
      <div className="flex gap-4 h-[calc(100vh-9rem)] max-w-[1200px]">

        {/* ── Left sidebar: conversations + insights ── */}
        <div className="w-64 shrink-0 flex flex-col gap-3 overflow-y-auto pr-1">
          <Button size="sm" leftIcon={<Plus size={13} />} onClick={startNewConversation} className="w-full">
            New conversation
          </Button>

          {loading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton key={i} className="h-14 rounded-xl" />
              ))}
            </div>
          ) : conversations.length === 0 ? (
            <p className="text-xs text-[var(--color-text-muted)] text-center py-4">No conversations yet</p>
          ) : (
            <motion.div variants={staggerContainer(0.05)} initial="hidden" animate="visible" className="space-y-1.5">
              {conversations.map((c) => (
                <motion.button
                  key={c.id}
                  variants={staggerItem}
                  onClick={() => loadConversation(c.id)}
                  className={cn(
                    "w-full text-left px-3 py-2.5 rounded-xl border transition-colors",
                    activeConvId === c.id
                      ? "border-[var(--color-accent)] bg-[rgba(124,110,246,0.10)]"
                      : "border-[var(--color-border)] bg-[var(--color-card)] hover:bg-[var(--color-elevated)]"
                  )}
                >
                  <p className="text-xs font-medium text-[var(--color-text-primary)] truncate">
                    {c.title ?? "New conversation"}
                  </p>
                  <p className="text-[10px] text-[var(--color-text-muted)] mt-0.5">
                    {formatDate(c.created_at, "short")} · {c.message_count} messages
                  </p>
                </motion.button>
              ))}
            </motion.div>
          )}

          {/* Insights section */}
          <div className="border-t border-[var(--color-border)] pt-3 space-y-2">
            <div className="flex items-center justify-between">
              <p className="text-xs font-medium text-[var(--color-text-muted)] uppercase tracking-wider">Insights</p>
              <Button variant="ghost" size="xs" isLoading={genInsights} onClick={generateInsights}>
                <RefreshCw size={11} />
              </Button>
            </div>
            {insights.slice(0, 3).map(ins => (
              <div key={ins.id} className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-3">
                <p className="text-xs font-medium text-[var(--color-text-primary)] leading-snug">{ins.title}</p>
                <p className="text-[10px] text-[var(--color-text-muted)] mt-1 line-clamp-2">{ins.content}</p>
              </div>
            ))}
          </div>
        </div>

        {/* ── Main chat area ── */}
        <div className="flex-1 flex flex-col rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] overflow-hidden">
          {/* Chat header */}
          <div className="px-5 py-3.5 border-b border-[var(--color-border)] flex items-center gap-3">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center">
              <Bot size={15} className="text-white" />
            </div>
            <div>
              <p className="text-sm font-semibold text-[var(--color-text-primary)]">Finance AI</p>
              <p className="text-[10px] text-[var(--color-text-muted)]">Powered by GPT-4 / Gemini</p>
            </div>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {messages.length === 0 && !sending && (
              <motion.div
                variants={staggerContainer(0.07)}
                initial="hidden"
                animate="visible"
                className="flex flex-col items-center justify-center h-full gap-6 py-8"
              >
                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center">
                  <Sparkles size={22} className="text-white" />
                </div>
                <div className="text-center space-y-1.5">
                  <p className="font-semibold text-[var(--color-text-primary)]">Ask your finances anything</p>
                  <p className="text-sm text-[var(--color-text-secondary)]">Your AI assistant has access to your complete transaction history.</p>
                </div>
                <div className="flex flex-wrap gap-2 justify-center max-w-md">
                  {SUGGESTED_QUESTIONS.map(q => (
                    <motion.button
                      key={q}
                      variants={staggerItem}
                      onClick={() => sendMessage(q)}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-[var(--color-border)] bg-[var(--color-elevated)] text-xs text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:border-[var(--color-accent)] transition-colors"
                    >
                      <ChevronRight size={11} />
                      {q}
                    </motion.button>
                  ))}
                </div>
              </motion.div>
            )}

            <AnimatePresence initial={false}>
              {messages.map((msg) => (
                <motion.div
                  key={msg.id}
                  initial={{ opacity: 0, y: 12, scale: 0.97 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.96 }}
                  transition={spring.smooth}
                  className={cn("flex gap-3", msg.role === "user" ? "justify-end" : "justify-start")}
                >
                  {msg.role === "assistant" && (
                    <div className="w-7 h-7 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center shrink-0 mt-0.5">
                      <Bot size={13} className="text-white" />
                    </div>
                  )}
                  <div className={cn(
                    "max-w-[75%] rounded-2xl px-4 py-3 text-sm leading-relaxed",
                    msg.role === "user"
                      ? "bg-[var(--color-accent)] text-white rounded-tr-sm"
                      : "bg-[var(--color-elevated)] text-[var(--color-text-primary)] rounded-tl-sm border border-[var(--color-border)]"
                  )}>
                    <p style={{ whiteSpace: "pre-wrap" }}>{msg.content}</p>
                    <p className={cn(
                      "text-[10px] mt-1.5",
                      msg.role === "user" ? "text-white/60" : "text-[var(--color-text-muted)]"
                    )}>
                      {formatDate(msg.created_at, "short")}
                    </p>
                  </div>
                  {msg.role === "user" && (
                    <div className="w-7 h-7 rounded-xl bg-[var(--color-accent-dim)] flex items-center justify-center shrink-0 mt-0.5">
                      <User size={13} className="text-white" />
                    </div>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>

            {/* Typing indicator */}
            <AnimatePresence>
              {sending && (
                <motion.div
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0 }}
                  className="flex gap-3"
                >
                  <div className="w-7 h-7 rounded-xl bg-gradient-to-br from-[var(--color-accent)] to-[var(--color-accent-dim)] flex items-center justify-center shrink-0">
                    <Bot size={13} className="text-white" />
                  </div>
                  <div className="bg-[var(--color-elevated)] border border-[var(--color-border)] rounded-2xl rounded-tl-sm px-4 py-3 flex items-center gap-1.5">
                    {[0, 0.15, 0.3].map((delay, i) => (
                      <motion.div
                        key={i}
                        animate={{ y: [0, -4, 0] }}
                        transition={{ repeat: Infinity, duration: 0.6, delay, ease: "easeInOut" }}
                        className="w-1.5 h-1.5 rounded-full bg-[var(--color-text-muted)]"
                      />
                    ))}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <div ref={bottomRef} />
          </div>

          {/* Input */}
          <div className="px-4 py-3 border-t border-[var(--color-border)]">
            <form
              onSubmit={e => { e.preventDefault(); sendMessage(input) }}
              className="flex gap-2"
            >
              <input
                value={input}
                onChange={e => setInput(e.target.value)}
                placeholder="Ask about your finances…"
                disabled={sending}
                className="flex-1 h-10 rounded-xl border border-[var(--color-border)] bg-[var(--color-elevated)] px-4 text-sm text-[var(--color-text-primary)] placeholder:text-[var(--color-text-muted)] focus:border-[var(--color-accent)] focus:outline-none transition-colors disabled:opacity-50"
              />
              <Button type="submit" isLoading={sending} disabled={!input.trim()} size="sm" className="px-3">
                <Send size={14} />
              </Button>
            </form>
          </div>
        </div>
      </div>
    </PageTransition>
  )
}
