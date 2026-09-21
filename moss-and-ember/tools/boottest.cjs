#!/usr/bin/env node
/**
 * Browser smoke test for the Moss & Ember web build.
 *
 * Boots the real page in a headless Chromium (software WebGL), captures every
 * console line, and writes screenshots so the running game can be inspected
 * without a GPU.
 *
 * Usage:
 *   NODE_PATH=/tmp/browsertest/node_modules node tools/boottest.cjs
 *
 * Env:
 *   BASE        site root            (default http://127.0.0.1:8080)
 *   QUERY       url query, e.g "?selftest" / "?autostart" / ""
 *   SHOTDIR     screenshot dir       (default /tmp/shots)
 *   SHOTS_AT    comma-separated seconds to screenshot (default "8,25")
 *   TIMEOUT_MS  give up after this long (default 240000)
 */
const path = require("path");
const fs = require("fs");
const puppeteer = require("puppeteer-core");
const chromiumPkg = require("@sparticuz/chromium");
// the package is ESM-first, so require() hands back the module namespace
const chromium = chromiumPkg.default || chromiumPkg;

const BASE = process.env.BASE || "http://127.0.0.1:8080";
const QUERY = process.env.QUERY === undefined ? "?selftest" : process.env.QUERY;
const SHOTDIR = process.env.SHOTDIR || "/tmp/shots";
const SHOTS_AT = (process.env.SHOTS_AT || "8,25").split(",").map(Number).filter((n) => !isNaN(n));
const TIMEOUT_MS = Number(process.env.TIMEOUT_MS || 240000);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  fs.mkdirSync(SHOTDIR, { recursive: true });
  const exe = await chromium.executablePath();
  console.log("[harness] chromium:", exe);

  // Chromium in this sandbox needs three extra libs (nss/nspr) plus swiftshader
  // for software WebGL; tools/setup_chromelibs.sh extracts them to /tmp/chromelibs.
  const extraLibs = process.env.EXTRA_LIBS || "/tmp/chromelibs/lib:/tmp/chromelibs";
  const env = { ...process.env, LD_LIBRARY_PATH: [extraLibs, process.env.LD_LIBRARY_PATH || ""].filter(Boolean).join(":") };

  const browser = await puppeteer.launch({
    executablePath: exe,
    headless: true,
    env,
    args: [
      ...chromium.args,
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
      "--use-gl=angle",
      "--use-angle=swiftshader",
      "--enable-unsafe-swiftshader",
      "--ignore-gpu-blocklist",
      "--window-size=1280,720",
    ],
    defaultViewport: { width: 1280, height: 720 },
  });

  const page = await browser.newPage();
  const logs = [];
  const record = (line) => {
    logs.push(line);
    console.log(line);
  };
  page.on("console", (m) => record(`[${m.type()}] ${m.text()}`));
  page.on("pageerror", (e) => record("[pageerror] " + (e && e.message)));
  page.on("requestfailed", (r) =>
    record("[requestfailed] " + r.url() + " " + (r.failure() && r.failure().errorText)));

  const url = BASE + "/" + QUERY;
  console.log("[harness] goto", url);
  await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });

  // Engine stdout/stderr goes to the page's own log panel (boot.js hooks it),
  // so read that DOM element as well as the browser console.
  const readPanels = () =>
    page
      .evaluate(() => ({
        msg: (document.getElementById("msg") || {}).textContent || "",
        log: (document.getElementById("console") || {}).textContent || "",
        canvas: (() => {
          const c = document.getElementById("c");
          return c ? c.width + "x" + c.height : "no-canvas";
          })(),
        gl: (() => {
          const c = document.getElementById("c");
          if (!c) return "no-canvas";
          try {
            const g = c.getContext("webgl2") || c.getContext("webgl");
            return g ? "ok" : "none";
          } catch (e) { return "err:" + e.message; }
        })(),
      }))
      .catch(() => ({ msg: "", log: "", canvas: "?", gl: "?" }));

  const started = Date.now();
  const shotSchedule = SHOTS_AT.map((s) => started + s * 1000);
  let shotIndex = 0;
  let pass = false;
  let fail = false;

  while (Date.now() < started + TIMEOUT_MS) {
    const live = await readPanels();
    if (/SELF-TEST PASS/.test(live.log)) { console.log("[harness] self-test passed in-page"); break; }
    if (/SELF-TEST FAIL/.test(live.log)) { console.log("[harness] self-test FAILED in-page"); break; }
    if (logs.some((l) => l.includes("SELF-TEST PASS")) || logs.some((l) => l.includes("SELF-TEST FAIL"))) break;
    if (shotSchedule.length && Date.now() >= shotSchedule[0]) {
      shotSchedule.shift();
      const f = path.join(SHOTDIR, `shot${shotIndex++}.png`);
      await page.screenshot({ path: f });
      record(`[harness] screenshot ${f} @${((Date.now() - started) / 1000).toFixed(1)}s`);
    }
    await sleep(700);
  }

  const finalShot = path.join(SHOTDIR, "final.png");
  await page.screenshot({ path: finalShot });
  console.log(`[harness] final screenshot ${finalShot}`);

  const panels = await readPanels();
  const engineLog = panels.log;
  fs.writeFileSync(path.join(SHOTDIR, "engine.log"), engineLog);
  console.log("[harness] ---- page state ----");
  console.log("[harness] loader msg:", panels.msg.trim());
  console.log("[harness] canvas:", panels.canvas, "| webgl:", panels.gl);
  console.log("[harness] ---- engine log (" + engineLog.split("\n").length + " lines) ----");
  for (const line of engineLog.split("\n").slice(-60)) console.log("   |", line);
  pass = /SELF-TEST PASS/.test(engineLog);
  fail = /SELF-TEST FAIL/.test(engineLog);
  const godotErrors = engineLog
    .split("\n")
    .filter((l) => /\bERROR:|SCRIPT ERROR|Failed to load|Can't open/.test(l));

  const errors = logs.filter((l) => l.startsWith("[error]") || l.startsWith("[pageerror]"));
  console.log("[harness] ---- summary ----");
  console.log("[harness] booted:", /Godot Engine v/.test(engineLog), "| scene tree:", /SceneTree/.test(engineLog));
  console.log("[harness] self-test pass:", pass, "fail:", fail);
  console.log("[harness] console errors:", errors.length, "| godot errors:", godotErrors.length);
  for (const e of godotErrors.slice(0, 25)) console.log("   ", e);
  console.log("[harness] total log lines:", logs.length);

  await browser.close();
  process.exit(pass && godotErrors.length === 0 ? 0 : 2);
})().catch((e) => {
  console.error("[harness] FATAL", e);
  process.exit(3);
});
