'use client'
import Link from 'next/link'
import { ShoppingBag, UserRound, Menu, X } from 'lucide-react'
import { useState } from 'react'

export function Nav() {
  const [open, setOpen] = useState(false)
  const links = [['فروشگاه','/store'],['پیش‌فروش','/preorders'],['بازار کاربران','/market'],['تسک‌ها','/tasks'],['کیف پول','/wallet'],['داشبورد','/dashboard']]
  
  return <header className="nav">
    <Link className="brand" href="/" onClick={() => setOpen(false)}><span>K</span><div><strong>KOLBE</strong><small>SPORT PROJECT</small></div></Link>
    <nav className={open ? 'mobile-open' : ''}>{links.map(([t,h]) => <Link key={h} href={h} onClick={() => setOpen(false)}>{t}</Link>)}</nav>
    <div className="nav-actions">
      <Link href="/cart" aria-label="سبد خرید"><ShoppingBag size={19}/></Link>
      {/* آیکون آدمک حالا مستقیم به صفحه ورود می‌رود */}
      <Link href="/auth/login" aria-label="ورود / ثبت‌نام"><UserRound size={19}/></Link>
      <button className="mobile-menu" onClick={() => setOpen(v=>!v)} aria-label="منو">{open?<X size={20}/>:<Menu size={20}/>}</button>
    </div>
  </header>
}
