import { createBrowserClient } from '@supabase/ssr'
import { PROJECT_CONFIG } from './project-config'

export function getSupabaseConfig() {
  return {
    url: process.env.NEXT_PUBLIC_SUPABASE_URL || PROJECT_CONFIG.supabaseUrl,
    key: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || PROJECT_CONFIG.supabasePublishableKey,
  }
}

export function hasSupabaseEnv() {
  const c = getSupabaseConfig()
  return Boolean(c.url && c.key)
}

export function supabase() {
  const { url, key } = getSupabaseConfig()
  if (!url || !key) return null
  return createBrowserClient(url, key)
}
