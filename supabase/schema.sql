create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text,
 referral_code text unique,
 referred_by uuid references public.profiles(id) on delete set null,
 role text not null default 'user' check(role in ('user','admin')),
 reward_points integer not null default 0 check(reward_points>=0),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists role text not null default 'user';

create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), sku text unique, name text not null, description text, category text,
 price bigint not null default 0 check(price>=0), image_url text, sizes text, colors text,
 status text not null default 'active' check(status in ('active','draft','archived')), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.preorders (
 id uuid primary key default gen_random_uuid(), product_id uuid references public.products(id) on delete set null,
 title text not null, target_qty integer not null check(target_qty>0), sold_qty integer not null default 0 check(sold_qty>=0),
 reserved_percent numeric(8,4) not null default 0 check(reserved_percent>=0 and reserved_percent<=100),
 unit_price bigint not null default 0 check(unit_price>=0), total_target bigint generated always as (target_qty*unit_price) stored,
 ends_at timestamptz, status text not null default 'open' check(status in ('draft','open','funded','closed','cancelled')), created_at timestamptz not null default now()
);
alter table public.preorders add column if not exists reserved_percent numeric(8,4) not null default 0;
alter table public.preorders add column if not exists updated_at timestamptz not null default now();

create table if not exists public.preorder_investments (
 id uuid primary key default gen_random_uuid(), preorder_id uuid not null references public.preorders(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete restrict, percent numeric(8,4) not null check(percent>0 and percent<=100),
 amount bigint not null check(amount>0), status text not null default 'reserved' check(status in ('reserved','paid','cancelled','converted')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(preorder_id,user_id)
);
alter table public.preorder_investments add column if not exists status text not null default 'reserved';
alter table public.preorder_investments add column if not exists updated_at timestamptz not null default now();

create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete restrict,
 total bigint not null default 0 check(total>=0), status text not null default 'pending' check(status in ('pending','paid','cancelled','fulfilled')),
 payment_reference text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.orders add column if not exists payment_reference text;
alter table public.orders add column if not exists updated_at timestamptz not null default now();
create table if not exists public.order_items (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null, quantity integer not null check(quantity>0), unit_price bigint not null check(unit_price>=0), created_at timestamptz not null default now()
);
create table if not exists public.ownerships (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete restrict,
 product_id uuid not null references public.products(id) on delete restrict, source_order_id uuid references public.orders(id) on delete set null,
 quantity integer not null default 1 check(quantity>0), ownership_percent numeric(8,4) not null default 100 check(ownership_percent>0 and ownership_percent<=100),
 resale_eligible boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.listings (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete restrict,
 ownership_id uuid references public.ownerships(id) on delete restrict, product_id uuid not null references public.products(id) on delete restrict,
 price bigint not null check(price>=0), quantity integer not null default 1 check(quantity>0), status text not null default 'active' check(status in ('draft','active','sold','cancelled')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.listings add column if not exists quantity integer not null default 1;
create table if not exists public.wallet_ledger (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete restrict,
 amount bigint not null, kind text not null, reference_id uuid, note text, created_at timestamptz not null default now()
);
create table if not exists public.reward_tasks (
 id uuid primary key default gen_random_uuid(), slug text unique not null, title text not null, description text, points integer not null default 0 check(points>=0), active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.user_reward_tasks (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 task_id uuid not null references public.reward_tasks(id) on delete cascade, status text not null default 'completed', points_awarded integer not null default 0,
 completed_at timestamptz not null default now(), unique(user_id,task_id)
);
create table if not exists public.gift_codes (
 id uuid primary key default gen_random_uuid(), code text unique not null, points integer not null default 0 check(points>=0), max_uses integer not null default 1 check(max_uses>0), used_count integer not null default 0 check(used_count>=0), active boolean not null default true, expires_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.gift_redemptions (
 id uuid primary key default gen_random_uuid(), gift_code_id uuid not null references public.gift_codes(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, points_awarded integer not null, redeemed_at timestamptz not null default now(), unique(gift_code_id,user_id)
);

create or replace function public.make_referral_code() returns text language plpgsql as $$
begin return 'KOLBE-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,6)); end; $$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,display_name,referral_code,reward_points,role)
 values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1)),public.make_referral_code(),0,'user')
 on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

create or replace function public.claim_reward_task(p_task_id uuid) returns jsonb language plpgsql security definer set search_path=public as $$
declare t public.reward_tasks; result jsonb;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 select * into t from public.reward_tasks where id=p_task_id and active=true;
 if not found then raise exception 'TASK_NOT_FOUND'; end if;
 if exists(select 1 from public.user_reward_tasks where user_id=auth.uid() and task_id=p_task_id) then raise exception 'TASK_ALREADY_CLAIMED'; end if;
 insert into public.user_reward_tasks(user_id,task_id,status,points_awarded) values(auth.uid(),p_task_id,'completed',t.points);
 update public.profiles set reward_points=reward_points+t.points, updated_at=now() where id=auth.uid();
 select jsonb_build_object('points',t.points,'new_total',reward_points) into result from public.profiles where id=auth.uid();
 return result;
end; $$;

create or replace function public.redeem_gift_code(p_code text) returns jsonb language plpgsql security definer set search_path=public as $$
declare g public.gift_codes; result jsonb;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 select * into g from public.gift_codes where upper(code)=upper(trim(p_code)) and active=true for update;
 if not found then raise exception 'INVALID_GIFT_CODE'; end if;
 if g.expires_at is not null and g.expires_at < now() then raise exception 'GIFT_EXPIRED'; end if;
 if g.used_count >= g.max_uses then raise exception 'GIFT_LIMIT_REACHED'; end if;
 if exists(select 1 from public.gift_redemptions where gift_code_id=g.id and user_id=auth.uid()) then raise exception 'GIFT_ALREADY_USED'; end if;
 insert into public.gift_redemptions(gift_code_id,user_id,points_awarded) values(g.id,auth.uid(),g.points);
 update public.gift_codes set used_count=used_count+1 where id=g.id;
 update public.profiles set reward_points=reward_points+g.points, updated_at=now() where id=auth.uid();
 select jsonb_build_object('points',g.points,'new_total',reward_points) into result from public.profiles where id=auth.uid();
 return result;
end; $$;

create or replace function public.reserve_preorder_share(p_preorder_id uuid,p_percent numeric) returns jsonb language plpgsql security definer set search_path=public as $$
declare p public.preorders; existing public.preorder_investments; new_total numeric; amount_value bigint; result jsonb;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 if p_percent <= 0 or p_percent > 100 then raise exception 'INVALID_PERCENT'; end if;
 select * into p from public.preorders where id=p_preorder_id and status='open' for update;
 if not found then raise exception 'PREORDER_NOT_OPEN'; end if;
 if p.ends_at is not null and p.ends_at <= now() then raise exception 'PREORDER_ENDED'; end if;
 select * into existing from public.preorder_investments where preorder_id=p.id and user_id=auth.uid() for update;
 new_total := p.reserved_percent + p_percent;
 if new_total > 100 then raise exception 'PREORDER_CAP_REACHED'; end if;
 amount_value := round(p.total_target * p_percent / 100.0);
 if found then
   update public.preorder_investments set percent=percent+p_percent, amount=amount+amount_value, updated_at=now() where id=existing.id;
 else
   insert into public.preorder_investments(preorder_id,user_id,percent,amount,status) values(p.id,auth.uid(),p_percent,amount_value,'reserved');
 end if;
 update public.preorders set reserved_percent=new_total, updated_at=now() where id=p.id;
 select jsonb_build_object('percent',new_total,'amount',coalesce((select amount from public.preorder_investments where preorder_id=p.id and user_id=auth.uid()),amount_value),'preorder_percent',new_total) into result;
 return result;
end; $$;

create or replace function public.create_order_from_cart(p_items jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare item jsonb; p public.products; order_id uuid; total_value bigint:=0; q integer; sku_value text; line_total bigint;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 if jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then raise exception 'EMPTY_CART'; end if;
 insert into public.orders(user_id,total,status) values(auth.uid(),0,'pending') returning id into order_id;
 for item in select * from jsonb_array_elements(p_items) loop
   sku_value := item->>'sku'; q := greatest(1,least(99,coalesce((item->>'quantity')::integer,1)));
   select * into p from public.products where sku=sku_value and status='active';
   if not found then raise exception 'PRODUCT_NOT_FOUND:%',sku_value; end if;
   line_total := p.price*q; total_value := total_value+line_total;
   insert into public.order_items(order_id,product_id,quantity,unit_price) values(order_id,p.id,q,p.price);
 end loop;
 update public.orders set total=total_value,updated_at=now() where id=order_id;
 return order_id;
end; $$;

create or replace function public.create_listing(p_ownership_id uuid,p_price bigint,p_quantity integer default 1) returns uuid language plpgsql security definer set search_path=public as $$
declare o public.ownerships; lid uuid;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 if p_price < 0 or p_quantity < 1 then raise exception 'INVALID_LISTING'; end if;
 select * into o from public.ownerships where id=p_ownership_id and user_id=auth.uid() and resale_eligible=true for update;
 if not found then raise exception 'OWNERSHIP_NOT_ELIGIBLE'; end if;
 if p_quantity > o.quantity then raise exception 'QUANTITY_EXCEEDED'; end if;
 insert into public.listings(owner_id,ownership_id,product_id,price,quantity,status) values(auth.uid(),o.id,o.product_id,p_price,p_quantity,'active') returning id into lid;
 return lid;
end; $$;

-- RLS
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.preorders enable row level security;
alter table public.preorder_investments enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.ownerships enable row level security;
alter table public.listings enable row level security;
alter table public.wallet_ledger enable row level security;
alter table public.reward_tasks enable row level security;
alter table public.user_reward_tasks enable row level security;
alter table public.gift_codes enable row level security;
alter table public.gift_redemptions enable row level security;

drop policy if exists "profiles own read" on public.profiles; create policy "profiles own read" on public.profiles for select using (auth.uid()=id or public.is_admin());
drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "products public read" on public.products; create policy "products public read" on public.products for select using (status='active' or public.is_admin());
drop policy if exists "products admin write" on public.products; create policy "products admin write" on public.products for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "preorders public read" on public.preorders; create policy "preorders public read" on public.preorders for select using (status in ('open','funded') or public.is_admin());
drop policy if exists "preorders admin write" on public.preorders; create policy "preorders admin write" on public.preorders for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "preorder investments own read" on public.preorder_investments; create policy "preorder investments own read" on public.preorder_investments for select using (auth.uid()=user_id or public.is_admin());
drop policy if exists "orders own read" on public.orders; create policy "orders own read" on public.orders for select using (auth.uid()=user_id or public.is_admin());
drop policy if exists "order items own read" on public.order_items; create policy "order items own read" on public.order_items for select using (exists(select 1 from public.orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_admin())));
drop policy if exists "ownership own read" on public.ownerships; create policy "ownership own read" on public.ownerships for select using (auth.uid()=user_id or public.is_admin());
drop policy if exists "listings public read active" on public.listings; create policy "listings public read active" on public.listings for select using (status='active' or auth.uid()=owner_id or public.is_admin());
drop policy if exists "listings own insert" on public.listings;
drop policy if exists "listings own update" on public.listings;
drop policy if exists "listings admin write" on public.listings; create policy "listings admin write" on public.listings for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "wallet own read" on public.wallet_ledger; create policy "wallet own read" on public.wallet_ledger for select using (auth.uid()=user_id or public.is_admin());
drop policy if exists "reward tasks public read" on public.reward_tasks; create policy "reward tasks public read" on public.reward_tasks for select using (active=true or public.is_admin());
drop policy if exists "reward tasks admin write" on public.reward_tasks; create policy "reward tasks admin write" on public.reward_tasks for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "user reward tasks own read" on public.user_reward_tasks; create policy "user reward tasks own read" on public.user_reward_tasks for select using (auth.uid()=user_id or public.is_admin());
drop policy if exists "gift codes no public read" on public.gift_codes; create policy "gift codes no public read" on public.gift_codes for select using (public.is_admin());
drop policy if exists "gift codes admin write" on public.gift_codes; create policy "gift codes admin write" on public.gift_codes for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "gift redemptions own read" on public.gift_redemptions; create policy "gift redemptions own read" on public.gift_redemptions for select using (auth.uid()=user_id or public.is_admin());

-- Realtime for live project modules. Run once in SQL editor if the publication already exists.
do $$ begin
  begin alter publication supabase_realtime add table public.preorders; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.listings; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.products; exception when duplicate_object then null; end;
end $$;
