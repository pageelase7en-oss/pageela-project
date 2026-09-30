import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { PROJECT_CONFIG } from '@/lib/project-config'
export async function GET(request:Request){const {searchParams,origin}=new URL(request.url);const code=searchParams.get('code');if(!code)return NextResponse.redirect(`${origin}/auth/login?error=missing_code`);const cookieStore=await cookies();const c=createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL || PROJECT_CONFIG.supabaseUrl,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || PROJECT_CONFIG.supabasePublishableKey,{cookies:{getAll:()=>cookieStore.getAll(),setAll:(items)=>items.forEach(({name,value,options})=>cookieStore.set(name,value,options))}});const {error}=await c.auth.exchangeCodeForSession(code);return NextResponse.redirect(`${origin}${error?'/auth/login?error=callback':'/dashboard'}`)}
