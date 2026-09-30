'use client'
import { useState } from 'react'
import { supabase, hasSupabaseEnv } from '@/lib/supabase'
import Link from 'next/link'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [msg, setMsg] = useState('')

  async function go() {
    const c = supabase()
    if (!c) {
      setMsg('اول آدرس پروژه Supabase را در .env.local وارد کن.')
      return
    }
    const { error } = await c.auth.signInWithPassword({ email, password })
    setMsg(error ? error.message : 'ورود موفق بود؛ حالا داشبورد را باز کن.')
  }

  return (
    <main className="auth-page">
      <section className="auth-card">
        <span className="eyebrow">KOLBE ACCOUNT</span>
        <h1>ورود به حساب</h1>
        <p>موجودی اولیه هر حساب در شروع ۰ تومان است.</p>
        
        <input value={email} onChange={e => setEmail(e.target.value)} placeholder="ایمیل" />
        <input value={password} onChange={e => setPassword(e.target.value)} type="password" placeholder="رمز عبور" />
        
        <button className="btn primary" onClick={go}>ورود</button>
        
        {/* لینک جدید اضافه شد */}
        <Link href="/auth/signup" className="auth-link">اگه تاحالا حساب نداشتی از اینجا وارد شو</Link>

        {!hasSupabaseEnv() && <small>کلید عمومی را گذاشته‌ایم؛ فقط URL پروژه Supabase را هم در .env.local وارد کن.</small>}
        {msg && <div className="form-msg">{msg}</div>}
        
        <Link href="/dashboard">رفتن به داشبورد</Link>
      </section>
    </main>
  )
}
