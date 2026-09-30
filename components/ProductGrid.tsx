'use client'
import { ShoppingBag, Check, LogIn } from 'lucide-react'
import { useState } from 'react'
import Link from 'next/link'
export const products = [
 {sku:'NIKE-FINGER-BLK',id:'nike-finger-01',name:'استرج مشکی نایک آستین فینگر دار',cat:'پوشاک',price:700000,status:'موجود',image:'/products/black-finger-sweatshirt.svg',sizes:'S · M · L · XL · 2XL'},
 {sku:'NIKE-SOCK-CREW',id:'nike-socks-01',name:'جوراب ساقدار پنبه نایک',cat:'جوراب',price:390000,status:'جدید',image:'/products/nike-cotton-socks.svg',sizes:'مشکی · سفید · زرد · رنگ‌های دیگر'},
]
const money=(n:number)=>new Intl.NumberFormat('fa-IR').format(n)
export function ProductGrid(){const [added,setAdded]=useState<string|null>(null);function add(p:typeof products[number]){const old=JSON.parse(localStorage.getItem('kolbe_cart')||'[]');const i=old.findIndex((x:any)=>x.sku===p.sku);if(i>=0)old[i].qty++;else old.push({...p,qty:1});localStorage.setItem('kolbe_cart',JSON.stringify(old));setAdded(p.id);setTimeout(()=>setAdded(null),1000)}return <div className="product-grid">{products.map((p,i)=><article className="product" key={p.id}><div className="product-art photo-art"><img src={p.image} alt={p.name}/><span>{p.status}</span><em>{String(i+1).padStart(2,'0')}</em></div><div className="product-info"><small>{p.cat}</small><h3>{p.name}</h3>{p.sizes&&<div className="size-line">{p.sizes}</div>}<div className="price">{money(p.price)} <b>تومان</b></div><button onClick={()=>add(p)}>{added===p.id?<><Check size={16}/> اضافه شد</>:<><ShoppingBag size={16}/> افزودن به سبد</>}</button></div></article>)}</div>}
