#!/usr/bin/env node
// Runtime introspection of the engine module object: what the ringozz addon
// exposes (functions, args) — used while wiring the web boot sequence.
const puppeteer = require("puppeteer-core");
const chromiumPkg = require("@sparticuz/chromium");
const chromium = chromiumPkg.default || chromiumPkg;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({
    executablePath: await chromium.executablePath(),
    headless: true,
    env: { ...process.env, LD_LIBRARY_PATH: "/tmp/chromelibs/lib:/tmp/chromelibs" },
    args: [...chromium.args, "--no-sandbox", "--use-gl=angle", "--use-angle=swiftshader",
           "--enable-unsafe-swiftshader"],
    defaultViewport: { width: 1280, height: 720 },
  });
  const page = await browser.newPage();
  await page.goto(process.env.BASE || "http://127.0.0.1:8080/", { waitUntil: "domcontentloaded" });
  await sleep(9000);
  const info = await page.evaluate(() => {
    const m = window.__mod;
    if (!m) return { err: "no __mod" };
    const keys = Object.keys(m);
    const funcs = keys.filter((k) => typeof m[k] === "function");
    const out = { total: keys.length, keys: keys.slice(0, 120), funcs };
    try { out.hasFS = !!m.FS; } catch (e) { out.hasFS = "err"; }
    try { out.arguments = m.arguments; } catch (e) {}
    try { out.calledRun = m.calledRun; } catch (e) {}
    return out;
  });
  console.log(JSON.stringify(info, null, 1));
  await browser.close();
})().catch((e) => { console.error("FATAL", e); process.exit(1); });
