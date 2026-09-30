# شروع خیلی ساده پروژه PAGEELA / KOLBE SPORT — نسخه نهایی V7

## فقط ۲ اطلاعات اصلی لازم است

### ۱) آدرس پروژه Supabase
از داخل Supabase برو به:

Project → Connect

یا Settings → API Keys

و مقدار Project URL را بردار.

مثال:

`https://xxxxxxxx.supabase.co`

### ۲) کلید Publishable
کلید عمومی پروژه از قبل در فایل قرار داده شده است:

`sb_publishable_blnRR86WNHwNNfe_17hJRQ_3Vc79TB8`

هرگز Secret Key / Service Role Key را وارد پروژه نکن.

---

# راحت‌ترین روش برای تست روی لپ‌تاپ

1. ZIP را از حالت فشرده خارج کن.
2. فایل `lib/project-config.ts` را باز کن.
3. این خط را پیدا کن:

`supabaseUrl: '',`

4. آدرس Supabase خودت را بین دو کوتیشن بگذار.

مثلاً:

`supabaseUrl: 'https://xxxxxxxx.supabase.co',`

5. داخل همان پوشه Terminal باز کن.
6. بزن:

`npm install`

7. بعد:

`npm run dev`

8. مرورگر را روی:

`http://localhost:3000`

باز کن.

---

# دیتابیس Supabase

در Supabase → SQL Editor:

اول `supabase/schema.sql` را کامل اجرا کن.

بعد `supabase/seed.sql` را کامل اجرا کن.

این کار محصولات، تسک‌ها، کدهای هدیه و پیش‌فروش اولیه را وارد می‌کند.

---

# ساخت اکانت مدیر

اول داخل سایت یک حساب بساز.

بعد در SQL Editor این را اجرا کن و ایمیل خودت را جایگزین کن:

```sql
update public.profiles
set role='admin'
where id=(select id from auth.users where email='YOUR_EMAIL');
```

بعد وارد:

`/admin`

شو.

---

# انتشار عمومی برای اینکه لینک سایت را برای بقیه بفرستی

روش پیشنهادی: Vercel.

1. وارد Vercel شو.
2. Add New → Project.
3. پروژه را از GitHub یا فایل/پوشه وارد کن.
4. Framework را Next.js بگذار یا اجازه بده خودش تشخیص بدهد.
5. قبل از Deploy در Environment Variables این دو مقدار را اضافه کن:

`NEXT_PUBLIC_SUPABASE_URL` = آدرس پروژه Supabase

`NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` = کلید Publishable

6. Deploy را بزن.

بعد از Deploy یک آدرس شبیه زیر می‌گیری:

`https://your-project.vercel.app`

همان لینک را می‌توانی برای کاربران بفرستی.

اگر بعداً متغیرهای Supabase را در Vercel عوض کردی، پروژه را دوباره Deploy کن.

---

# اطلاعات قابل تغییر برای خودت

اگر خواستی اسم‌ها/لینک‌های اجتماعی را عوض کنی، ساده‌ترین فایل:

`lib/project-config.ts`

است.

فقط این موارد را تغییر بده:

- `brandName`
- `projectName`
- `instagramUrl`
- `telegramUrl`
- `supabaseUrl`

قیمت‌ها، محصولات، تسک‌ها، کدهای هدیه و پیش‌فروش از طریق `supabase/seed.sql` و بعداً پنل `/admin` مدیریت می‌شوند.

---

## نکته مالی

پیش‌فروش در این نسخه به‌عنوان مشارکت/رزرو درصدی محصول پیاده‌سازی شده است؛ پرداخت واقعی، تسویه، انتقال مالکیت و کمیسیون هنوز نباید به‌عنوان تراکنش قطعی مالی در نظر گرفته شوند تا درگاه و منطق مالی امن به پروژه اضافه شوند.
