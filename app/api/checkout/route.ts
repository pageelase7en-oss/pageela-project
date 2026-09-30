import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  try {
    const { amount, description, orderId } = await req.json();

    // بررسی اینکه Merchant ID وجود دارد
    const merchantId = process.env.ZARINPAL_MERCHANT_ID;
    if (!merchantId) {
      return NextResponse.json({ error: 'تنظیمات درگاه انجام نشده است' }, { status: 500 });
    }

    const data = {
      merchant_id: merchantId,
      amount: amount, // مبلغ به تومان
      callback_url: `http://localhost:3000/api/verify?orderId=${orderId}`, // آدرس بازگشت
      description: description,
    };

    const response = await fetch('https://api.zarinpal.com/pg/v4/payment/request.json', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });

    const result = await response.json();

    if (result.data && result.data.authority) {
      const url = `https://www.zarinpal.com/pg/StartPay/${result.data.authority}`;
      return NextResponse.json({ url });
    } else {
      return NextResponse.json({ error: 'خطا در اتصال به درگاه زرین‌پال' }, { status: 500 });
    }
  } catch (error) {
    return NextResponse.json({ error: 'خطای سرور' }, { status: 500 });
  }
}
