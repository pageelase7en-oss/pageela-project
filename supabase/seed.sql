insert into public.products (sku,name,description,category,price,image_url,sizes,colors,status) values
('NIKE-FINGER-BLK','استرج مشکی نایک آستین فینگر دار','استرج مشکی آستین فینگر دار با سایزبندی کامل.','پوشاک',700000,'/products/black-finger-sweatshirt.svg','S,M,L,XL,2XL','مشکی','active'),
('NIKE-SOCK-CREW','جوراب ساقدار پنبه نایک','جوراب ساقدار پنبه‌ای در چند رنگ.','جوراب',390000,'/products/nike-cotton-socks.svg','','مشکی,سفید,زرد,رنگ‌های دیگر','active'),
('PAGEELA-PRE-001','دورس مشکی PAGEELA · ۴ نخ پنبه خارخورده','دورس مشکی ۴ نخ پنبه خارخورده درجه یک با آرم PAGEELA گلدوزی‌شده روی سینه.','پیش‌فروش',6680000,'/products/pageela-preorder.svg','S,M,L,XL,2XL','مشکی','active')
on conflict (sku) do update set name=excluded.name,description=excluded.description,price=excluded.price,image_url=excluded.image_url,sizes=excluded.sizes,colors=excluded.colors,status='active';

insert into public.reward_tasks(slug,title,description,points) values
('watch_ad','دیدن تبلیغ','یک محتوای تبلیغاتی را کامل ببین و سپس ثبت انجام را بزن.',80),
('referral','دعوت با کد معرف','کد معرف خودت را با یک دوست به اشتراک بگذار.',250),
('instagram_follow','فالو کردن پیج','پیج KOLBE SPORT را دنبال کن.',150),
('telegram_join','عضویت در کانال تلگرام','عضو کانال رسمی پروژه شو.',180)
on conflict(slug) do update set points=excluded.points,title=excluded.title,description=excluded.description,active=true;

insert into public.gift_codes(code,points,max_uses,active) values
('WELCOME100',100,1000,true),
('PAGEELA500',500,500,true)
on conflict(code) do update set points=excluded.points,max_uses=excluded.max_uses,active=true;

do $$
declare pid uuid;
begin
 select id into pid from public.products where sku='PAGEELA-PRE-001';
 if exists(select 1 from public.preorders where title='دورس مشکی PAGEELA · ۴ نخ پنبه خارخورده') then
   update public.preorders set product_id=pid,target_qty=250,unit_price=6680000,status='open',ends_at=coalesce(ends_at,now()+interval '7 days') where title='دورس مشکی PAGEELA · ۴ نخ پنبه خارخورده';
 else
   insert into public.preorders(title,target_qty,sold_qty,reserved_percent,unit_price,ends_at,status,product_id) values('دورس مشکی PAGEELA · ۴ نخ پنبه خارخورده',250,0,0,6680000,now()+interval '7 days','open',pid);
 end if;
end $$;

-- برای اکانت ادمین، بعد از ساخت حساب خودت، این دستور را با ایمیل خودت اجرا کن:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='YOUR_EMAIL');
