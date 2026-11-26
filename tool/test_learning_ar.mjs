#!/usr/bin/env node
// End-to-end test of the AR camera screen with the Arabic letters and Colors
// books, in headless Chrome with a fake camera. Checks that
//   - letters: the letter pages are found in order, the 3D letters load, the
//     letter is said in Arabic, there is no Feed button, and "Find the letter"
//     takes the right page,
//   - colours: the scene's objects show as parts, Paint offers 6 paints, the
//     right one keeps the scene's colour and a wrong one repaints it for a moment,
//   - Algeria: the flag's details show as parts, and the pages are found,
//   - there are no page errors.
// Usage: node tool/test_learning_ar.mjs        (needs Chrome and ffmpeg)
import { spawn } from 'node:child_process';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ROOT, CHROME, sleep, makeVideo, serve, cdp } from './ar_test_lib.mjs';

const OUT = join(ROOT, 'tool', 'test-output');
const failures = [];
const check = (ok, what) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${what}`); if (!ok) failures.push(what); };

async function run(book, pages, body) {
  const work = mkdtempSync(join(tmpdir(), `${book}-ar-test-`));
  const y4m = makeVideo(work, pages, join(ROOT, 'book', book, 'pages'), pages[0]);
  const server = await serve();
  const base = `http://127.0.0.1:${server.address().port}/index.html?debug&book=${book}`;
  const chrome = spawn(CHROME, [
    '--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
    '--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream',
    `--use-file-for-fake-video-capture=${y4m}`, '--autoplay-policy=no-user-gesture-required',
    '--remote-debugging-port=0', `--user-data-dir=${join(work, 'profile')}`, '--window-size=390,844', 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  const wsBrowser = await new Promise((ok) => {
    let buf = '';
    chrome.stderr.on('data', (d) => { buf += d; const m = buf.match(/DevTools listening on (ws:\S+)/); if (m) ok(m[1]); });
  });
  const targets = await (await fetch(`http://127.0.0.1:${new URL(wsBrowser).port}/json/list`)).json();
  const page = await cdp(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
  const errors = [];
  page.on((msg) => {
    if (msg.method === 'Runtime.exceptionThrown') errors.push(msg.params.exceptionDetails.exception?.description || msg.params.exceptionDetails.text);
    if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error') errors.push('console: ' + msg.params.args.map((a) => a.value ?? a.description).join(' '));
  });
  await page.send('Runtime.enable');
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true });
  const evalJs = async (expr) => (await page.send('Runtime.evaluate', { expression: expr, returnByValue: true })).result.value;
  const h = {
    page, base, evalJs,
    state: () => evalJs('JSON.stringify(window.__arState || null)').then(JSON.parse).catch(() => null),
    tap: async (x, y) => {
      await page.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
      await page.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
    },
    centerOf: (sel) => evalJs(`(() => { const e = document.querySelector(${JSON.stringify(sel)});
      if (!e) return null; const r = e.getBoundingClientRect(); return JSON.stringify({ x: r.x + r.width / 2, y: r.y + r.height / 2 }); })()`)
      .then((s) => (s ? JSON.parse(s) : null)),
    shot: async (name) => {
      const { data } = await page.send('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(OUT, name), Buffer.from(data, 'base64'));
      console.log('      screenshot tool/test-output/' + name);
    },
  };
  await page.send('Page.navigate', { url: base });
  try { await body(h); } finally {
    check(errors.length === 0, `${book}: no page errors${errors.length ? ': ' + errors.slice(0, 3).join(' | ') : ''}`);
    page.close();
    chrome.kill();
    server.close();
    await new Promise((ok) => (chrome.exitCode !== null ? ok() : chrome.once('exit', ok)));
    try { rmSync(work, { recursive: true, force: true }); } catch { /* ignore */ }
  }
}

async function watch(h, pages, onFound, ms = 70000) {
  const seen = [];
  let last = null, st = null;
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    await sleep(250);
    st = await h.state();
    if (!st) continue;
    if (st.found && st.found !== last) { seen.push(st.found); await sleep(900); await onFound(st.found, st); }
    if (!st.found && last) seen.push('lost');
    last = st.found;
    if (seen.includes(pages.at(-1)) && seen.at(-1) === 'lost') break;
  }
  return { seen, st };
}

async function main() {
  mkdirSync(OUT, { recursive: true });

  // ---- Arabic letters ----
  const AR_PAGES = ['ar_01', 'ar_02'];
  await run('letters_ar', AR_PAGES, async (h) => {
    let firstDone = false;
    const { seen, st } = await watch(h, AR_PAGES, async (id) => {
      await h.shot(`letters-found-${id}.png`);
      if (id === 'ar_02' && !firstDone) {
        firstDone = true;
        const s = await h.state();
        check(/باء/.test(s.lastSpoken || ''), `the letter is said in Arabic ("${s.lastSpoken}")`);
        const ui = await h.evalJs('JSON.stringify({ feed: document.getElementById("btn-feed").classList.contains("hidden"), move: document.getElementById("btn-move").textContent })').then(JSON.parse);
        check(ui.feed && ui.move.includes('Spin'), `letters: no Feed button, Move is Spin (${ui.move})`);
      }
    });
    check(st && st.modelsLoaded === 28, `all 28 letters loaded (${st?.modelsLoaded})`);
    check(seen.join(' > ') === 'ar_01 > lost > ar_02 > lost', `letter pages found in order (${seen.join(' > ')})`);

    await h.page.send('Page.navigate', { url: h.base + '&mode=helps&soundTarget=ar_02' });
    let q = null;
    const t0 = Date.now();
    while (Date.now() - t0 < 60000) {
      await sleep(300);
      q = await h.evalJs('JSON.stringify({ q: window.__arState && window.__arState.soundQuiz, text: document.getElementById("quiz-text").textContent, spoken: window.__arState && window.__arState.lastSpoken })').then(JSON.parse).catch(() => null);
      if (q && q.q && q.q.correct >= 1) break;
    }
    check(q && q.q && q.q.correct >= 1, `Find the letter: the Baa page answers "${q?.text}"`);
    await h.shot('letters-find.png');
  });

  // ---- Colours ----
  const C_PAGES = ['color_red', 'color_blue'];
  await run('colors', C_PAGES, async (h) => {
    let done = false;
    const { seen, st } = await watch(h, C_PAGES, async (id) => {
      await h.shot(`colors-found-${id}.png`);
      if (id === 'color_red' && !done) {
        done = true;
        await sleep(500);
        const s = await h.state();
        check(s.parts.visible.length >= 2, `the red shades show as parts (${s.parts.visible.join(', ')})`);
        const paintBtn = await h.centerOf('#btn-feed');
        await h.tap(paintBtn.x, paintBtn.y);
        await sleep(300);
        const tray = (await h.state()).feed;
        check(tray && tray.on && tray.items.length === 6 && tray.items.includes('red'), `Paint offers 6 paints with red (${tray?.items?.join(', ')})`);
        const wrongId = tray.items.find((f) => f !== 'red');
        const wrong = await h.centerOf(`.food[data-food="${wrongId}"]`);
        await h.tap(wrong.x, wrong.y);
        await sleep(300);
        const w = await h.evalJs('JSON.stringify({ painted: window.__arState.painted, toast: document.getElementById("toast").textContent })').then(JSON.parse);
        check(w.painted && w.painted !== '#E53935' && w.toast.includes('Find'), `a wrong paint repaints for a moment ("${w.toast}", ${w.painted})`);
        await h.shot('colors-wrong-paint.png');
        await sleep(1800);
        const back = await h.evalJs('window.__arState.painted');
        check(back === '#E53935', `…then the scene is red again (${back})`);
        const red = await h.centerOf('.food[data-food="red"]');
        await h.tap(red.x, red.y);
        await sleep(400);
        const r = await h.evalJs('JSON.stringify({ fed: window.__arState.feed.fed, toast: document.getElementById("toast").textContent })').then(JSON.parse);
        check(r.fed.includes('red') && r.toast.startsWith('Yes'), `red is the right paint ("${r.toast}")`);
        await h.tap(paintBtn.x, paintBtn.y);
      }
    });
    check(st && st.modelsLoaded === 10, `all 10 colour scenes loaded (${st?.modelsLoaded})`);
    check(seen.join(' > ') === 'color_red > lost > color_blue > lost', `colour pages found in order (${seen.join(' > ')})`);
  });

  // ---- Algeria ----
  const DZ_PAGES = ['dz_flag', 'dz_fennec'];
  await run('algeria', DZ_PAGES, async (h) => {
    let flagDone = false;
    const { seen, st } = await watch(h, DZ_PAGES, async (id) => {
      await h.shot(`algeria-found-${id}.png`);
      if (id === 'dz_flag' && !flagDone) {
        flagDone = true;
        await sleep(500);
        const s = await h.state();
        check(s.parts.visible.length >= 2, `the flag's details show as parts (${s.parts.visible.join(', ')})`);
        const feed = await h.evalJs('document.getElementById("btn-feed").classList.contains("hidden")');
        check(feed, 'Algeria: no Feed button');
      }
    });
    check(st && st.modelsLoaded === 11, `all 11 Algeria models loaded (${st?.modelsLoaded})`);
    check(seen.join(' > ') === 'dz_flag > lost > dz_fennec > lost', `Algeria pages found in order (${seen.join(' > ')})`);
  });

  // ---- Shapes and Numbers: the pages are found, the models load ----
  for (const [book, pages, total] of [['shapes', ['shape_circle', 'shape_triangle'], 10], ['numbers', ['num_1', 'num_3'], 10]]) {
    await run(book, pages, async (h) => {
      const { seen, st } = await watch(h, pages, async (id) => h.shot(`${book}-found-${id}.png`));
      check(st && st.modelsLoaded === total, `all ${total} ${book} models loaded (${st?.modelsLoaded})`);
      check(seen.join(' > ') === `${pages[0]} > lost > ${pages[1]} > lost`, `${book} pages found in order (${seen.join(' > ')})`);
    });
  }

  console.log(failures.length ? `\n${failures.length} check(s) failed` : '\nall checks passed');
  process.exit(failures.length ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
