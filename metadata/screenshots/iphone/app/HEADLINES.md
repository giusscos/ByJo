# App Store screenshots for the new languages (2026-11-12)

Raw app captures for Figma, 1320 × 2868 (6.9" iPhone, iPhone 18 Pro Max simulator, status bar at 9:41), one folder per
App Store locale. Sample data with ByJo Pro unlocked, same five screens as the live set:

| File | Live screenshot it replaces | Screen |
|---|---|---|
| `01-all-your-money.png` | 01-all-your-money | Home: savings rate, top expenses, asset allocation |
| `02-private.png` | 02-private | Checking asset, operations by day |
| `03-spending-habits.png` | 03-spending-habits | Home top: goals, this month, spending meter |
| `04-goals.png` | 04-goals | New Laptop goal |
| `05-plan.png` | 05-plan | Netflix recurring operation |
| (none) | 06-widgets | Reuse the existing widgets image (Home Screen widgets were skipped) |

Region and currency per folder: `ar-SA` United Arab Emirates, dirham (Gregorian calendar; Saudi's Hijri calendar made
"this month" negative); `ja` Japan, yen (amounts ×100); `nl-NL` Netherlands, euro; `zh-Hans` China, yuan (×2);
`zh-Hant` Taiwan, NT$ (×10). China and Taiwan show rises in red and falls in green, as the app does there.
Account and category names (Checking, Netflix, Rent…) come from the sample data and stay in English, as in the
existing German and Italian sets.

Locales that need no new images: `es-MX` uses the `es-ES` set, `en-AU` and `en-CA` use the `en-GB` / `en-US` set.

## Headlines

Machine-assisted: a native speaker should check them. Line 1 is the big green line, line 2 the subtitle.

| # | en (live) | nl-NL | ja | zh-Hans | zh-Hant | ar-SA |
|---|---|---|---|---|---|---|
| 1 | All your money / in one private app | Al je geld / in één privé-app | お金のすべてを / ひとつのアプリに | 你的全部资产 / 尽在一个私密 App | 你的全部資產 / 盡在一個私密 App | كل أموالك / في تطبيق واحد خاص |
| 2 | 100% private / No account. No bank login. | 100% privé / Geen account. Geen bankkoppeling. | 100% プライベート / 登録不要。銀行ログイン不要。 | 100% 私密 / 无需注册，无需登录银行 | 100% 私密 / 不必註冊，不必登入銀行 | خصوصية 100% / بلا حساب، بلا ربط بالبنك |
| 2 badge | Never on our servers | Nooit op onze servers | サーバーには一切保存しません | 绝不上传到我们的服务器 | 絕不上傳到我們的伺服器 | لا شيء على خوادمنا |
| 3 | Learn your / spending habits | Ken je / uitgavenpatroon | 支出のクセを / 見える化 | 看清你的 / 消费习惯 | 看清你的 / 消費習慣 | اعرف / عاداتك في الإنفاق |
| 4 | Achieve / your goals | Bereik / je doelen | 目標を / 達成しよう | 实现 / 你的目标 | 達成 / 你的目標 | حقّق / أهدافك |
| 5 | Plan / your next move | Plan / je volgende stap | 次の一手を / 計画しよう | 规划 / 你的下一步 | 規劃 / 你的下一步 | خطّط / لخطوتك التالية |
| 6 | Check in / from your Home Screen | Bekijk alles / vanaf je beginscherm | ホーム画面で / いつでもチェック | 在主屏幕上 / 随时查看 | 在主畫面上 / 隨時查看 | تابع كل شيء / من الشاشة الرئيسية |

Arabic frames should be mirrored: headline right-aligned, and the phone mockup can stay centered.

## iPad and iPhone Duo (decided 2026-11-12)

No new captures: reuse the English app images from the live iPad set (6 frames) and from
`metadata/screenshots/iphone-duo/app-store/en-US`, and only translate the text in the Figma frames.
Translated app screens are kept for iPhone only, where most people see them.

- iPad frames use the same six headlines as iPhone (table above).
- iPhone Duo frames: `01-all-your-money` = headline 1, `03-plan` = headline 5, and `02-unfold` needs this one:

| en (live) | nl-NL | ja | zh-Hans | zh-Hant | ar-SA |
|---|---|---|---|---|---|
| Unfold the / full picture | Klap open voor / het hele plaatje | 開けば / 全体が見える | 展开屏幕 / 看清全貌 | 展開螢幕 / 看清全貌 | افتح الشاشة / لترى الصورة كاملة |

## iPhone Duo 02-dashboard (added 2026-11-12)

New second iPhone Duo frame: the unfolded two-column Home (`iphone-duo/app/en-US/01-home-inner.png`).
Order is now 01-all-your-money (outer), 02-dashboard, 03-unfold (assets), 04-plan.

| en | de-DE | es-ES | fr-FR / fr-CA | it | pt-PT / pt-BR | nl-NL | ja | zh-Hans | zh-Hant | ar-SA |
|---|---|---|---|---|---|---|---|---|---|---|
| See it all / side by side | Alles im Blick / Seite an Seite | Todo a la vista / lado a lado | Tout d’un coup d’œil / côte à côte | Tutto a colpo d’occhio / fianco a fianco | Tudo à vista / lado a lado | Alles in één oogopslag / naast elkaar | すべてを / 並べて見渡す | 一屏尽览 / 图表并排呈现 | 一屏盡覽 / 圖表並排呈現 | كل شيء أمامك / جنبًا إلى جنب |
