// Moss & Ember — web bootstrap.
// Boots the Godot 4.7.2 wasm engine, stages the project files into its
// in-memory filesystem, and lets the engine run the project.
import * as emnapi from './emnapi.js';

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
function log(line) {
  godotLogCount++;
  consoleEl.textContent += line + '\n';
  if (consoleEl.textContent.length > 20000) {
    consoleEl.textContent = consoleEl.textContent.slice(-12000);
  }
  consoleEl.scrollTop = consoleEl.scrollHeight;
}
consoleBtn.addEventListener('click', () => consoleEl.classList.toggle('open'));

const canvas = $('c');
let Module = null;

async function boot(useFallback) {
  try {
    setMsg(useFallback ? 'Fallback start…' : 'Loading engine…');
    setPct(0.02);
    if (!Module) {
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
      const modFactory = (await import('./godot.js')).default;
      Module = await modFactory({
        canvas,
        locateFile: (p) => p,
        wasmBinary: buf.buffer,
        print: (t) => { log('· ' + t); },
        printErr: (t) => { log('! ' + t); },
      });
    }
    setMsg('Staging game files…');
    const manifest = await (await fetch('files.json', { cache: 'no-store' })).json();
    let i = 0;
    for (const f of manifest.files) {
      const r = await fetch(f.http, { cache: 'no-store' });
      if (!r.ok) throw new Error('fetch ' + f.http + ' -> HTTP ' + r.status);
      const bytes = new Uint8Array(await r.arrayBuffer());
      Module.copyToFS('res://' + f.res, bytes);
      i++;
      if (i % 4 === 0 || i === manifest.files.length) {
        setPct(0.1 + 0.85 * (i / manifest.files.length));
        setMsg('Staging game files… ' + i + '/' + manifest.files.length);
      }
    }
    setMsg('Starting engine…');
    Module.initConfig({ canvas, canvasResizePolicy: 2 });
    const ctx = emnapi.getDefaultContext();
    const mod = Module.emnapiInit({ context: ctx });
    mod.stageFile = Module.copyToFS;
    ctx.openScope();
    setPct(1.0);
    setMsg(useFallback ? 'Fallback requested — watch the engine log.' : 'Running…');
    setTimeout(() => {
      hint.style.display = 'block';
      consoleBtn.style.display = 'block';
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
  // If the engine booted but never started the main loop, try the standard
  // entry point explicitly with the staged project.
  if (Module && typeof Module.callMain === 'function') {
    setMsg('Calling engine main directly…');
    try {
      Module.callMain(['res://project.godot']);
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
