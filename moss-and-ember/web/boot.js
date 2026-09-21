// Moss & Ember — web bootstrap.
// Boots the Godot 4.7.2 wasm engine, stages the project files into its
// in-memory filesystem, and lets the engine run the project.
import * as emnapi from './emnapi.js';
// Static import: bundlers inline this into single-file builds, and on the web
// server it is fetched alongside the page (261 KB).
import godotFactory from './engine/godot.js';

const $ = (id) => document.getElementById(id);
const loader = $('loader');
const msg = $('msg');
const fill = $('fill');
const consoleEl = $('console');
const consoleBtn = $('console-btn');
const retryBtn = $('retry');
const hint = $('controls-hint');

let godotLogCount = 0;

function setMsg(t) { msg.textContent = t; }
function setPct(p) { fill.style.width = (Math.max(0, Math.min(1, p)) * 100).toFixed(0) + '%'; }
function showConsoleButton() { consoleBtn.style.display = 'block'; }

function log(line) {
  godotLogCount++;
  if (/^!/.test(line)) showConsoleButton();
  consoleEl.textContent += line + '\n';
  if (consoleEl.textContent.length > 20000) {
    consoleEl.textContent = consoleEl.textContent.slice(-12000);
  }
  consoleEl.scrollTop = consoleEl.scrollHeight;
}
consoleBtn.addEventListener('click', () => consoleEl.classList.toggle('open'));

const canvas = $('c');
let Module = null;

// Test hooks: the page query string is turned into real engine command-line
// arguments ("-- <args>"), which the project reads via OS.get_cmdline_user_args().
const params = new URLSearchParams(location.search);
const engineArgs = ['--'];
if (params.has('selftest')) engineArgs.push('--self-test');
if (params.has('autostart')) engineArgs.push('--autostart');
if (params.has('slow')) engineArgs.push('--slow');

// Single-file builds inline everything: window.__MOSS_PAYLOAD = { wasm, files,
// worklets } with base64 bodies (optionally gzipped as __MOSS_PAYLOAD_GZ). In
// that mode nothing is fetched over the network, so the page also works from
// file:// with no server at all.
function b64ToBytes(b64) {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function loadEmbedded() {
  if (globalThis.__MOSS_PAYLOAD) return globalThis.__MOSS_PAYLOAD;
  if (!globalThis.__MOSS_PAYLOAD_GZ) return null;
  if (typeof DecompressionStream !== 'function') {
    throw new Error('this browser cannot open the offline build — use the live link instead');
  }
  const bytes = b64ToBytes(globalThis.__MOSS_PAYLOAD_GZ);
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
  return JSON.parse(await new Response(stream).text());
}

async function boot(useFallback) {
  try {
    setMsg(useFallback ? 'Fallback start…' : 'Loading engine…');
    setPct(0.02);
    const embedded = await loadEmbedded();
    if (embedded) {
      setMsg('Unpacking the game…');
      const wasmBytes = b64ToBytes(embedded.wasm);
      setPct(0.2);
      const workletUrls = {};
      for (const [name, body] of Object.entries(embedded.worklets || {})) {
        workletUrls[name] = URL.createObjectURL(new Blob([body], { type: 'text/javascript' }));
      }
      const modFactory = godotFactory;
      Module = await modFactory({
        canvas,
        locateFile: (p) => workletUrls[p] || p,
        wasmBinary: wasmBytes.buffer,
        print: (t) => { log('· ' + t); },
        printErr: (t) => { log('! ' + t); },
      });
      window.__mod = Module;
      for (const [res, b64] of Object.entries(embedded.files)) {
        Module.copyToFS('/' + res, b64ToBytes(b64));
      }
      log('unpacked ' + Object.keys(embedded.files).length + ' game files');
    }
    if (!Module && !embedded) {
      // Download the wasm ourselves to show real progress on slow links.
      const wr = await fetch('godot.wasm', { cache: 'no-store' });
      if (!wr.ok) throw new Error('fetch godot.wasm -> HTTP ' + wr.status);
      const total = parseInt(wr.headers.get('Content-Length') || '17000000', 10);
      const chunks = [];
      let got = 0;
      const reader = wr.body.getReader();
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
        got += value.length;
        setPct(0.02 + 0.18 * (got / total));
        setMsg('Downloading engine… ' + (got / 1048576).toFixed(1) + ' MB');
      }
      const buf = new Uint8Array(got);
      let off = 0;
      for (const c of chunks) { buf.set(c, off); off += c.length; }
      const modFactory = godotFactory;
      Module = await modFactory({
        canvas,
        locateFile: (p) => p,
        wasmBinary: buf.buffer,
        arguments: engineArgs,
        print: (t) => { log('· ' + t); },
        printErr: (t) => { log('! ' + t); },
      });
    }
    window.__mod = Module;  // debug handle for the browser smoke test
    if (!embedded) {
      setMsg('Staging game files…');
      const manifest = await (await fetch('files.json', { cache: 'no-store' })).json();
      let i = 0;
      for (const f of manifest.files) {
        const r = await fetch(f.http, { cache: 'no-store' });
        if (!r.ok) throw new Error('fetch ' + f.http + ' -> HTTP ' + r.status);
        const bytes = new Uint8Array(await r.arrayBuffer());
        // copy_to_fs() builds directories from the literal string, so this must
        // be an absolute path: "/project.godot" -> FS root (which the engine
        // maps to res://). A "res://" prefix would create a folder named "res:".
        Module.copyToFS('/' + f.res, bytes);
        i++;
        if (i % 4 === 0 || i === manifest.files.length) {
          setPct(0.1 + 0.85 * (i / manifest.files.length));
          setMsg('Staging game files… ' + i + '/' + manifest.files.length);
        }
      }
    }
    // Test hooks: stage a small flags file the game reads at startup. This is
    // how the browser smoke test asks for the in-engine self-test (?selftest)
    // or jumps straight into gameplay (?autostart).
    const flags = {};
    for (const key of ['selftest', 'autostart', 'noon', 'photo']) if (params.has(key)) flags[key] = true;
    if (Object.keys(flags).length) {
      Module.copyToFS('/test_flags.json', new TextEncoder().encode(JSON.stringify(flags)));
      log('staged /test_flags.json ' + JSON.stringify(flags));
    }

    setMsg('Starting engine…');
    Module.initConfig({ canvas, canvasResizePolicy: 2 });
    const ctx = emnapi.getDefaultContext();
    const mod = Module.emnapiInit({ context: ctx });
    mod.stageFile = Module.copyToFS;
    ctx.openScope();

    // The addon starts the engine, but frames only advance when the host
    // drives them — the same loop @ringozz/godot runs on the web:
    //   while (!godot.iteration()) await new Promise(requestAnimationFrame);
    // `iteration()` is GodotInstance's method binding 8470 (see
    // @ringozz/godot/gen/classes/GodotInstance.ts); it returns true once the
    // engine wants to quit.
    if (!mod.requestAnimationFrame) log('note: engine rAF unavailable, using timer frames');
    globalThis.requestAnimationFrame = mod.requestAnimationFrame ?? globalThis.requestAnimationFrame;
    globalThis.cancelAnimationFrame = mod.cancelAnimationFrame ?? globalThis.cancelAnimationFrame;
    const raf = (mod.requestAnimationFrame || globalThis.requestAnimationFrame ||
      ((cb) => setTimeout(() => cb(performance.now()), 16))).bind(globalThis);
    const godot = mod.getGodot();
    window.__godot = godot;
    const iterate = typeof godot.iteration === 'function'
      ? () => godot.iteration()
      : () => mod._C(godot, 8470);

    // Race rAF against a timer: browsers throttle rAF in hidden/background
    // tabs (and headless test runs), and the game must keep ticking there.
    const nextFrame = () => new Promise((resolve) => {
      let done = false;
      const timer = setTimeout(() => { if (!done) { done = true; resolve(); } }, 250);
      try {
        raf(() => { if (!done) { done = true; clearTimeout(timer); resolve(); } });
      } catch (e) {
        if (!done) { done = true; clearTimeout(timer); resolve(); }
      }
    });

    (async () => {
      let frames = 0;
      try {
        let reportAt = performance.now() + 4000;
        while (!iterate()) {
          frames++;
          if (frames === 1) log('main loop running');
          if (performance.now() >= reportAt) {
            reportAt = performance.now() + 4000;
            log('frames so far: ' + frames);
          }
          await nextFrame();
        }
        log('engine asked to quit after ' + frames + ' frames');
        setMsg('The game has stopped.');
      } catch (e) {
        log('! main loop error: ' + (e && e.message ? e.message : e));
        setMsg('Engine stopped: ' + (e && e.message ? e.message : e));
      }
    })();

    setPct(1.0);
    setMsg(useFallback ? 'Fallback requested — watch the engine log.' : 'Running…');
    if (params.has('debug')) showConsoleButton();
    setTimeout(() => {
      hint.style.display = 'block';
      setTimeout(() => loader.classList.add('hide'), 900);
      setTimeout(() => { hint.style.display = 'none'; }, 14000);
    }, 600);
  } catch (e) {
    console.error(e);
    setMsg('BOOT ERROR: ' + (e && e.message ? e.message : String(e)));
    retryBtn.style.display = 'inline-block';
  }
}

retryBtn.addEventListener('click', () => {
  // Retry booting from scratch (the engine's main() can only run once, so a
  // failed boot needs a fresh module rather than a callMain).
  if (Module && typeof Module.callMain === 'function') {
    setMsg('Calling engine main directly…');
    try {
      Module.callMain(['--path', '/']);
    } catch (e) {
      setMsg('Fallback failed: ' + e.message);
      console.error(e);
    }
  } else {
    boot(false);
  }
});

// If nothing happens (no engine output at all), surface the retry button.
setTimeout(() => {
  if (godotLogCount === 0 && Module) {
    setMsg('Engine loaded but silent. Try the fallback start.');
    retryBtn.style.display = 'inline-block';
  }
}, 12000);

boot(false);
