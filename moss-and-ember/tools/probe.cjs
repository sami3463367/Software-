#!/usr/bin/env node
/**
 * Boot probe: watches the page's engine log line by line with timestamps and
 * then inspects the engine's in-memory filesystem, to find out where a boot
 * stops. Used while debugging the web runtime (see tools/boottest.cjs for the
 * pass/fail smoke test).
 *
 * Usage: NODE_PATH=/tmp/browsertest/node_modules node tools/probe.cjs [query] [seconds]
 */
const puppeteer = require("puppeteer-core");
const chromiumPkg = require("@sparticuz/chromium");
const chromium = chromiumPkg.default || chromiumPkg;

const BASE = process.env.BASE || "http://127.0.0.1:8080";
const QUERY = process.argv[2] || "?selftest";
const SECONDS = Number(process.argv[3] || 120);
const extraLibs = process.env.EXTRA_LIBS || "/tmp/chromelibs/lib:/tmp/chromelibs";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const exe = await chromium.executablePath();
  const browser = await puppeteer.launch({
    executablePath: exe,
    headless: true,
    env: { ...process.env, LD_LIBRARY_PATH: extraLibs },
    args: [...chromium.args, "--no-sandbox", "--use-gl=angle", "--use-angle=swiftshader",
           "--enable-unsafe-swiftshader", "--window-size=1280,720"],
    defaultViewport: { width: 1280, height: 720 },
  });
  const page = await browser.newPage();
  page.on("console", (m) => console.log("[page:" + m.type() + "]", m.text().slice(0, 300)));
  page.on("pageerror", (e) => console.log("[pageerror]", String(e.message).slice(0, 300)));

  const t0 = Date.now();
  const stamp = () => ((Date.now() - t0) / 1000).toFixed(1).padStart(6) + "s";
  await page.goto(BASE + "/" + QUERY, { waitUntil: "domcontentloaded", timeout: 60000 });

  let shown = 0;
  const readLog = () =>
    page.evaluate(() => ({
      msg: (document.getElementById("msg") || {}).textContent || "",
      log: (document.getElementById("console") || {}).textContent || "",
    })).catch(() => ({ msg: "", log: "" }));

  while (Date.now() - t0 < SECONDS * 1000) {
    const { msg, log } = await readLog();
    const lines = log.split("\n");
    if (lines.length - 1 > shown) {
      for (const line of lines.slice(shown, lines.length - 1)) console.log(stamp(), "|", line);
      shown = lines.length - 1;
      console.log(stamp(), "| (loader msg:", msg.trim(), ")");
    }
    if (/SELF-TEST PASS|SELF-TEST FAIL/.test(log)) {
      console.log(stamp(), "| >>> done:", log.match(/SELF-TEST (PASS|FAIL)[^\n]*/)[0]);
      break;
    }
    await sleep(2000);
  }

  const fs = await page.evaluate(() => {
    const m = window.__mod;
    if (!m || !m.FS) return { err: "no module/FS on window" };
    const out = {};
    const list = (p) => { try { return m.FS.readdir(p); } catch (e) { return "ERR " + e.message; } };
    out.root = list("/");
    out.rootStat = (() => { try { const s = m.FS.stat("/project.godot"); return { mode: s.mode, size: s.size }; } catch (e) { return "ERR " + e.message; } })();
    out.scenes = list("/scenes");
    out.godotDir = list("/.godot");
    out.cwd = (() => { try { return m.FS.cwd(); } catch (e) { return "ERR " + e.message; } })();
    return out;
  });
  console.log(stamp(), "| ---- engine filesystem ----");
  console.log(JSON.stringify(fs, null, 1).slice(0, 1500));

  await page.screenshot({ path: "/tmp/shots/probe-final.png" });
  await browser.close();
})().catch((e) => { console.error("FATAL", e); process.exit(3); });
