'use client'
import { useState } from 'react'
import { supabase, hasSupabaseEnv } from '@/lib/supabase'
import Link from 'next/link'

export default function Signup() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [msg, setMsg] = useState('')

  async function go() {
    const c = supabase()
    if (!c) {
      setMsg('اول آدرس پروژه Supabase را در .env.local وارد کن.')
      return
    }
    
    // عملیات ثبت‌نام
    const { error } = await c.auth.signUp({
      email,
      password,
      options: { emailRedirectTo: `${location.origin}/auth/callback` }
    })
    
    setMsg(error ? error.message : 'ثبت‌نام انجام شد. صندوق ایمیل را بررسی کن.')
  }

  return (
    <main className="auth-page">
      <section className="auth-card">
        <span className="eyebrow">NEW ACCOUNT</span>
        <h1>ساخت حساب</h1>
        <p>به خانواده KOLBE SPORT بپیوند.</p>
        
        <input value={email} onChange={e => setEmail(e.target.value)} placeholder="ایمیل" />
        <input value={password} onChange={e => setPassword(e.target.value)} type="password" placeholder="رمز عبور" />
        
        <button className="btn primary" onClick={go}>ثبت‌نام</button>

        {/* لینک مورد نظرت */}
        <Link href="/auth/login" className="auth-link">اگه حساب داری از اینجا وارد شو</Link>

        {!hasSupabaseEnv() && <small>کلید عمومی را گذاشته‌ایم؛ فقط URL پروژه Supabase را هم در .env.local وارد کن.</small>}
        {msg && <div className="form-msg">{msg}</div>}
      </section>
    </main>
  )
}
