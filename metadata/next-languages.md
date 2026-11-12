<!--
Stor metadata import template
1. Keep the `# Locale: xx-XX` headers (App Store Connect locale codes).
2. Fill in each ## field. Leave a field blank to skip it on import.
3. Import this file from the Listing tab → Import Markdown.
Character limits: Name 30 · Subtitle 30 · Description 4000 · Keywords 100 · Promotional Text 170 · What's New 4000
-->
<!-- PROPOSAL, prepared 2026-11-12. NOT shipped: six NEW App Store localizations for the version after 1.2.0.
     1.2.0 ships only the rename; add these in the next version, after Giuseppe's yes.

     NATIVE-SPEAKER REVIEW NEEDED: the es-MX, ar-SA, ja and nl-NL text is a machine-assisted translation.
     Have a native speaker read name, subtitle, keywords, promotional text and description before import.

     - es-MX, en-AU, en-CA: listings only. The app shows them its existing es / en / en-GB strings.
     - ar-SA, ja, nl-NL: listings for the new app languages (ByJo/ar.lproj, ja.lproj, nl.lproj).

     Why each one (Apple's storefront table, checked 2026-11-12):
     - es-MX is the default listing in Mexico, Argentina and most of Latin America (they see en-GB today)
       and a second keyword field in the US.
     - en-AU is Australia's default listing (it sees en-GB today); en-CA is Canada's default English listing.
       Their keywords avoid the en-GB / fr-CA words those storefronts already index.
     - ar-SA: UAE and Saudi Arabia default to en-GB with Arabic as the extra language. A search for
       "صافي الثروة" there returns only English-named apps.
     - ja: "純資産管理" is in no top-10 app name; "家計簿" is owned by big apps (median about 55k ratings),
       so it sits in the subtitle for long-tail searches only.
     - nl-NL: "vermogen tracker" competition is tiny (top-10 median under 1 rating).

     Keywords are at most 100 BYTES (Apple's limit is in bytes: Arabic letters take 2, Japanese characters 3).
     None repeats a word from the name or subtitle; no spaces after commas; no trademarks.
     What's New is left blank: App Store Connect needs it for every locale in an update, so copy in that
     version's notes when it ships. After these go live, write the go-live date in the version's metadata file. -->

# Locale: es-MX

## Name
Patrimonio Neto - ByJo

## Subtitle
Presupuesto privado y gastos

## Description
ByJo es una app privada para seguir tu patrimonio neto y tu presupuesto, pensada como una alternativa más clara a las hojas de cálculo. Agrega lo que tienes y lo que debes, registra ingresos y gastos, y ve todo tu panorama financiero en un solo lugar.

PRIVADA DESDE EL DISEÑO
Sin registro ni acceso a tu banco. Tus datos se quedan en tus dispositivos y solo se sincronizan con tu propio iCloud privado. Sin servidores de ByJo y sin compartir nada.

TU PATRIMONIO NETO EN UN SOLO NÚMERO
Sigue más de 40 tipos de activos: efectivo, cuentas bancarias, tarjetas de crédito, cripto, acciones, ETF, bienes raíces, vehículos, préstamos, hipotecas y más. ByJo los suma en un solo patrimonio neto, en cualquiera de más de 50 monedas.

PRESUPUESTO Y GASTOS
• Registra ingresos y gastos en segundos, y divide un pago entre varias categorías
• Define un presupuesto mensual para cada categoría
• Medidor de gasto: compara hoy con ayer y este mes con el anterior
• Resumen mensual, principales gastos y tasa de ahorro en Inicio
• Mueve dinero entre activos con transferencias vinculadas

REGISTRO SIN ESFUERZO
Registra operaciones y transferencias con Siri y Atajos, o configura una automatización de Wallet para que tus pagos con tarjeta lleguen solos a ByJo.

PLAN GRATUITO Y BYJO PRO
El plan gratuito incluye hasta 3 activos, con operaciones y categorías ilimitadas. ByJo Pro agrega:
• Activos ilimitados
• Metas financieras con monto objetivo, fecha límite y proyecciones
• Ingresos y pagos recurrentes, con un recordatorio antes de cada uno
• Widgets para la pantalla de inicio
• Gráficas avanzadas: historial del patrimonio neto, tendencias de gasto, evolución de la tasa de ahorro, desglose de gastos, distribución de activos y pago de deudas
• Una pantalla de Inicio que puedes reordenar y simplificar
• Exportación e importación en CSV y JSON

Empieza con una prueba gratuita de 7 días del plan anual, o elige el plan semanal o una compra única de por vida.
Las suscripciones se renuevan automáticamente (cada semana o cada año) salvo que las canceles al menos 24 horas antes de que termine el periodo actual. Cancela cuando quieras en la configuración de tu cuenta de Apple.

## Keywords
finanzas,personales,ahorro,ingresos,activos,deudas,inversiones,cartera,cripto,dinero,control,metas

## Promotional Text
Todo tu patrimonio en un solo lugar, gratis hasta 3 activos. Sin registro ni acceso al banco: tus datos se quedan en tus dispositivos y en tu propio iCloud.

## What's New

---

# Locale: en-AU

## Name
Net Worth Tracker - ByJo

## Subtitle
Private Budget & Finance

## Description
ByJo is a private net worth tracker and budget app, built as a clearer alternative to spreadsheets. Add what you own and what you owe, log income and expenses, and see your whole financial picture in one place.

PRIVATE BY DESIGN
No sign-up, no bank login. Your data stays on your devices and syncs only through your own private iCloud. No ByJo servers, no sharing.

YOUR NET WORTH IN ONE NUMBER
Track 40+ asset types: cash, bank accounts, credit cards, crypto, shares, ETFs, property, vehicles, loans, mortgages and more. ByJo adds them up into one net worth, in any of 50+ currencies.

BUDGET AND SPENDING
• Log inflows and outflows in seconds, and split a payment across categories
• Set a monthly budget for each category
• Spendmeter: compare today with yesterday, this month with last month
• Monthly summary, top expenses and savings rate on Home
• Move money between assets with linked transfers

HANDS-FREE LOGGING
Log operations and transfers with Siri and Shortcuts, or set up a Wallet automation so card payments land in ByJo.

FREE PLAN AND BYJO PRO
The free plan covers up to 3 assets, with unlimited operations and categories. ByJo Pro adds:
• Unlimited assets
• Financial goals with a target, a due date and projections
• Recurring income and bills, with a reminder before each one
• Home Screen widgets
• Advanced charts: net worth history, spending trends, savings rate trend, expense breakdown, asset allocation and debt payoff
• A Home screen you can reorder and trim
• Export and import with CSV and JSON

Start with a 7-day free trial on the yearly plan, or choose the weekly plan or a one-time lifetime purchase.
Subscriptions renew automatically (weekly or yearly) unless cancelled at least 24 hours before the end of the current period. Cancel anytime in your Apple Account settings.

## Keywords
networth,assets,liabilities,super,shares,property,mortgage,loan,calculator,allocation,offline,etf

## Promotional Text
Your whole net worth in one place, free for up to 3 assets. No sign-up, no bank login: your data stays on your devices and in your own iCloud.

## What's New

---

# Locale: en-CA

## Name
Net Worth Tracker - ByJo

## Subtitle
Private Budget & Finance

## Description
ByJo is a private net worth tracker and budget app, built as a clearer alternative to spreadsheets. Add what you own and what you owe, log income and expenses, and see your whole financial picture in one place.

PRIVATE BY DESIGN
No sign-up, no bank login. Your data stays on your devices and syncs only through your own private iCloud. No ByJo servers, no sharing.

YOUR NET WORTH IN ONE NUMBER
Track 40+ asset types: cash, chequing and savings accounts, credit cards, crypto, stocks, ETFs, real estate, vehicles, loans, mortgages and more. ByJo adds them up into one net worth, in any of 50+ currencies.

BUDGET AND SPENDING
• Log inflows and outflows in seconds, and split a payment across categories
• Set a monthly budget for each category
• Spendmeter: compare today with yesterday, this month with last month
• Monthly summary, top expenses and savings rate on Home
• Move money between assets with linked transfers

HANDS-FREE LOGGING
Log operations and transfers with Siri and Shortcuts, or set up a Wallet automation so card payments land in ByJo.

FREE PLAN AND BYJO PRO
The free plan covers up to 3 assets, with unlimited operations and categories. ByJo Pro adds:
• Unlimited assets
• Financial goals with a target, a due date and projections
• Recurring income and bills, with a reminder before each one
• Home Screen widgets
• Advanced charts: net worth history, spending trends, savings rate trend, expense breakdown, asset allocation and debt payoff
• A Home screen you can reorder and trim
• Export and import with CSV and JSON

Start with a 7-day free trial on the yearly plan, or choose the weekly plan or a one-time lifetime purchase.
Subscriptions renew automatically (weekly or yearly) unless cancelled at least 24 hours before the end of the current period. Cancel anytime in your Apple Account settings.

## Keywords
networth,assets,tfsa,rrsp,fhsa,spending,expense,income,portfolio,crypto,savings,debt,mortgage,wealth

## Promotional Text
Your whole net worth in one place, free for up to 3 assets. No sign-up, no bank login: your data stays on your devices and in your own iCloud.

## What's New

---

# Locale: ar-SA

## Name
متتبع صافي الثروة - ByJo

## Subtitle
ميزانية ومصاريف بخصوصية تامة

## Description
ByJo تطبيق خاص لتتبّع صافي الثروة والميزانية، صُمّم ليكون بديلًا أوضح لجداول البيانات. أضف ما تملكه وما عليك من ديون، وسجّل الدخل والمصاريف، وشاهد صورتك المالية كاملة في مكان واحد.

الخصوصية أولًا
بلا تسجيل وبلا ربط بالبنك. تبقى بياناتك على أجهزتك ولا تتزامن إلا عبر iCloud الخاص بك. لا خوادم لـ ByJo ولا مشاركة.

صافي ثروتك في رقم واحد
تتبّع أكثر من 40 نوعًا من الأصول: النقد والحسابات البنكية وبطاقات الائتمان والعملات الرقمية والأسهم وصناديق المؤشرات والعقارات والمركبات والقروض والرهن العقاري وغيرها. يجمعها ByJo في رقم واحد لصافي ثروتك، بأي من أكثر من 50 عملة.

الميزانية والإنفاق
• سجّل الدخل والمصاريف في ثوانٍ، وقسّم الدفعة على أكثر من فئة
• حدّد ميزانية شهرية لكل فئة
• مقياس الإنفاق: قارن اليوم بالأمس وهذا الشهر بالشهر الماضي
• الملخص الشهري وأعلى المصاريف ومعدل الادخار في الشاشة الرئيسية
• انقل الأموال بين الأصول بتحويلات مرتبطة

تسجيل بلا عناء
سجّل العمليات والتحويلات عبر Siri والاختصارات، أو أعدّ أتمتة Wallet لتصل دفعات بطاقتك إلى ByJo تلقائيًا.

الخطة المجانية وByJo Pro
تشمل الخطة المجانية حتى 3 أصول، مع عمليات وفئات بلا حدود. ويضيف ByJo Pro:
• أصولًا بلا حدود
• أهدافًا مالية بمبلغ مستهدف وموعد نهائي وتوقّعات
• دخلًا وفواتير متكررة، مع تذكير قبل كل موعد
• أدوات للشاشة الرئيسية
• رسومًا بيانية متقدمة: سجل صافي الثروة واتجاهات الإنفاق واتجاه معدل الادخار وتفصيل المصاريف وتوزيع الأصول وسداد الديون
• شاشة رئيسية يمكنك إعادة ترتيبها وإخفاء أقسامها
• التصدير والاستيراد بصيغتي CSV وJSON

ابدأ بتجربة مجانية لمدة 7 أيام على الخطة السنوية، أو اختر الخطة الأسبوعية أو شراءً لمرة واحدة مدى الحياة.
تتجدد الاشتراكات تلقائيًا (أسبوعيًا أو سنويًا) ما لم تُلغَ قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يمكنك الإلغاء في أي وقت من إعدادات حساب Apple.

## Keywords
ذهب,ادخار,استثمار,أسهم,ديون,قروض,أصول,دخل,ثروة,محفظة

## Promotional Text
صافي ثروتك كاملًا في مكان واحد، مجانًا حتى 3 أصول. بلا تسجيل وبلا ربط بالبنك: تبقى بياناتك على أجهزتك وفي iCloud الخاص بك.

## What's New

---

# Locale: ja

## Name
純資産管理 - ByJo

## Subtitle
家計簿と予算をプライベートに

## Description
ByJoは、純資産と予算をプライベートに管理できるアプリです。表計算よりわかりやすく、持っているものと借りているものを追加して収入と支出を記録するだけで、お金の全体像をひとつの場所で確認できます。

プライバシーを最優先
登録不要、銀行ログイン不要。データはあなたのデバイスに保存され、同期はご自身のプライベートなiCloudだけを通じて行われます。ByJoのサーバーはなく、データが共有されることもありません。

純資産をひとつの数字で
現金、銀行口座、クレジットカード、暗号資産、株式、ETF、不動産、車両、ローン、住宅ローンなど、40種類以上の資産に対応。ByJoがすべてを合計し、50以上の通貨から選んだ通貨で純資産を表示します。

予算と支出
• 収入と支出を数秒で記録し、1回の支払いを複数のカテゴリに分割
• カテゴリごとに月の予算を設定
• 支出メーター：今日と昨日、今月と先月を比較
• 月次サマリー、主な支出、貯蓄率をホームに表示
• 連動した振替で資産間の資金を移動

手間なく記録
Siriやショートカットで取引や振替を記録。Walletのオートメーションを設定すれば、カードの支払いが自動でByJoに記録されます。

無料プランとByJo Pro
無料プランでは資産3件まで、取引とカテゴリは無制限で使えます。ByJo Proでは次の機能が加わります。
• 資産を無制限に
• 目標額・期日・予測つきのお金の目標
• 定期的な収入と請求、それぞれの前にリマインダー
• ホーム画面ウィジェット
• 高度なグラフ：純資産の推移、支出の推移、貯蓄率の推移、支出の内訳、資産配分、返済状況
• 並べ替えや非表示ができるホーム画面
• CSVとJSONでの書き出しと読み込み

年額プランの7日間無料トライアルから始めるか、週額プランまたは買い切りを選べます。
サブスクリプションは、現在の期間が終了する24時間前までにキャンセルしない限り、自動的に更新されます（毎週または毎年）。Appleアカウントの設定からいつでもキャンセルできます。

## Keywords
資産推移,貯金,支出,収入,負債,投資,暗号資産,株,目標,節約,総資産,ローン

<!-- Two-character words are normal Japanese keywords, but Apple's help says each keyword should be
     "greater than two characters". If App Store Connect rejects this set, use this one (86 bytes):
資産推移,暗号資産,総資産,資産形成,ポートフォリオ,住宅ローン
-->

## Promotional Text
純資産のすべてをひとつの場所に。資産3件までは無料です。登録も銀行ログインも不要で、データはあなたのデバイスとご自身のiCloudにだけ保存されます。

## What's New

---

# Locale: nl-NL

## Name
Vermogen Tracker - ByJo

## Subtitle
Privé budget & huishoudboekje

## Description
ByJo is een privé-app om je nettovermogen en budget bij te houden, gemaakt als overzichtelijker alternatief voor spreadsheets. Voeg toe wat je bezit en wat je schuldig bent, leg inkomsten en uitgaven vast en zie je hele financiële plaatje op één plek.

PRIVÉ VANAF HET BEGIN
Geen account, geen bankkoppeling. Je gegevens blijven op je apparaten en synchroniseren alleen via je eigen privé-iCloud. Geen servers van ByJo, niets wordt gedeeld.

JE NETTOVERMOGEN IN ÉÉN GETAL
Houd meer dan 40 soorten bezittingen bij: contant geld, bankrekeningen, creditcards, crypto, aandelen, ETF's, vastgoed, voertuigen, leningen, hypotheken en meer. ByJo telt alles op tot één nettovermogen, in een van meer dan 50 valuta.

BUDGET EN UITGAVEN
• Leg inkomsten en uitgaven in seconden vast en verdeel een betaling over meerdere categorieën
• Stel per categorie een maandbudget in
• Uitgavenmeter: vergelijk vandaag met gisteren en deze maand met vorige maand
• Maandoverzicht, grootste uitgaven en spaarquote op Home
• Verplaats geld tussen bezittingen met gekoppelde overboekingen

VASTLEGGEN ZONDER GEDOE
Leg transacties en overboekingen vast met Siri en Opdrachten, of stel een Wallet-automatisering in zodat je kaartbetalingen vanzelf in ByJo terechtkomen.

GRATIS ABONNEMENT EN BYJO PRO
Het gratis abonnement omvat maximaal 3 bezittingen, met onbeperkt transacties en categorieën. ByJo Pro voegt toe:
• Onbeperkt bezittingen
• Financiële doelen met doelbedrag, einddatum en prognoses
• Terugkerende inkomsten en rekeningen, met een herinnering vooraf
• Widgets op het beginscherm
• Uitgebreide grafieken: verloop nettovermogen, uitgaventrends, verloop spaarquote, uitgaven per categorie, vermogensverdeling en schulden aflossen
• Een Home-scherm dat je kunt ordenen en inkorten
• Exporteren en importeren met CSV en JSON

Begin met 7 dagen gratis proberen op het jaarabonnement, of kies het weekabonnement of een eenmalige levenslange aankoop.
Abonnementen worden automatisch verlengd (per week of per jaar), tenzij je ten minste 24 uur voor het einde van de lopende periode opzegt. Opzeggen kan altijd via de instellingen van je Apple-account.

## Keywords
nettovermogen,financiën,uitgaven,inkomsten,sparen,beleggen,aandelen,crypto,schulden,hypotheek,geld

## Promotional Text
Je hele nettovermogen op één plek, gratis voor maximaal 3 bezittingen. Geen account, geen bankkoppeling: je gegevens blijven op je apparaten en in je eigen iCloud.

## What's New
