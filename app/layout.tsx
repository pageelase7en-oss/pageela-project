import './globals.css'
import { Nav } from '@/components/Nav'

export const metadata = { title: 'K KOLBE SPORT | PROJECT', description: 'K KOLBE SPORT interactive marketplace project' }

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="fa" dir="rtl"><body><Nav />{children}</body></html>
}
