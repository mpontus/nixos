// Run against a disposable VM: open three tabs and run `domterm help` in one.
// Enable Electron remote debugging in the VM, forwarding it to localhost only.
// Usage: node tests/domterm-style-regression.mjs http://127.0.0.1:9223
import assert from 'node:assert/strict';
const endpoint = new URL(process.argv[2] ?? 'http://127.0.0.1:9223');
const targets = await fetch(new URL('/json/list', endpoint)).then(r => r.json());
const target = targets.find(t => t.type === 'page' && !t.url.startsWith('devtools:'));
assert(target, 'No DomTerm page');
const address = new URL(target.webSocketDebuggerUrl);
address.host = endpoint.host;
const socket = new WebSocket(address);
const timer = setTimeout(() => { console.error('FAIL: debugger timed out'); process.exit(1); }, 30000);
try {
  await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
  let id = 0;
  const call = (method, params) => new Promise(resolve => {
    const requestId = ++id;
    socket.onmessage = e => { const r = JSON.parse(e.data); if (r.id === requestId) resolve(r); };
    socket.send(JSON.stringify({id: requestId, method, params}));
  });
  const result = await call('Runtime.evaluate', {
    returnByValue: true,
    expression: `(() => {
      const results = [];
      const check = (ok, name) => results.push({ok, name});
      const style = e => e.ownerDocument.defaultView.getComputedStyle(e);
      const tabs = [...document.querySelectorAll('.lm_tabs .lm_tab')];
      check(tabs.length >= 3, 'three tabs exercised');
      const headers = [...document.querySelectorAll('.lm_header')];
      check(headers.every(e => Math.abs(e.getBoundingClientRect().bottom - e.parentElement.getBoundingClientRect().bottom) < 1), 'tabs pinned to bottom');
      const containers = [...document.querySelectorAll('.lm_items')];
      check(containers.every(e => e.clientWidth === e.parentElement.clientWidth && e.clientWidth > 0), 'content fills tab group width');
      check(containers.every(e => style(e).borderTopWidth === '0px'), 'no inner pane frame');
      const active = tabs.find(e => e.classList.contains('lm_active'));
      check(!!active && style(active).backgroundColor === 'rgba(0, 0, 0, 0)' && style(active).boxShadow === 'none', 'no active tab fill or underline');
      check(style(document.body).backgroundColor === 'rgb(19, 28, 43)', 'no contrasting live-layout gaps');
      const docs = [document, ...[...document.querySelectorAll('iframe')].map(f => f.contentDocument)];
      const buffers = docs.flatMap(d => [...d.querySelectorAll('.dt-buffers')]);
      check(buffers.length > 0 && buffers.every(e => style(e).scrollbarWidth === 'none'), 'scrollbars hidden in every pane');
      const headings = docs.flatMap(d => [...d.querySelectorAll('.domterm h2')]);
      check(headings.length > 0 && headings.every(e => style(e).fontFamily.includes('system-ui')), 'help uses system UI font');
      check(tabs.every(e => style(e).fontFamily.includes('system-ui')), 'tabs use system UI font');
      const code = docs.flatMap(d => [...d.querySelectorAll('.domterm code')]);
      check(code.length > 0 && code.every(e => style(e).fontFamily === 'monospace'), 'code uses system monospace font');
      return results;
    })()`
  });
  assert(!result.error && !result.result?.exceptionDetails, 'Debugger evaluation failed');
  for (const check of result.result.result.value) {
    console.log(`${check.ok ? 'PASS' : 'FAIL'}: ${check.name}`);
    assert(check.ok, check.name);
  }
  const evaluate = async expression => {
    const r = await call('Runtime.evaluate', {expression, returnByValue: true, awaitPromise: true});
    assert(!r.error && !r.result?.exceptionDetails, 'Keybinding evaluation failed');
    return r.result.result.value;
  };
  const ids = await evaluate(`(() => {
    const layout = DomTerm._layout;
    const item = layout._numberToLayoutItem(DomTerm.focusedWindowNumber);
    const tabs = item.parent.contentItems;
    layout._selectLayoutPane(tabs[0], 'test');
    return tabs.map(t => t.container.paneInfo.number);
  })()`);
  const pressTab = async backwards => {
    const params = {key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9, modifiers: backwards ? 10 : 2};
    await call('Input.dispatchKeyEvent', {type: 'keyDown', ...params});
    await call('Input.dispatchKeyEvent', {type: 'keyUp', ...params});
  };
  const expectFocus = async expected => assert(await evaluate(`(async () => {
    for (let i=0; i<40 && DomTerm.focusedWindowNumber !== ${expected}; i++) await new Promise(r => setTimeout(r, 50));
    return DomTerm.focusedWindowNumber === ${expected};
  })()`), `Expected tab ${expected}`);
  await expectFocus(ids[0]);
  await pressTab(false); await expectFocus(ids[1]);
  await pressTab(true); await expectFocus(ids[0]);
  await pressTab(true); await expectFocus(ids.at(-1));
  await pressTab(false); await expectFocus(ids[0]);
  console.log('PASS: Ctrl+Tab / Ctrl+Shift+Tab navigate in both directions and wrap');
  const splitId = await evaluate(`(async () => {
    DomTerm.newPane(11, null, DomTerm.focusedPane);
    for (let i=0; i<100; i++) {
      const id = DomTerm.focusedWindowNumber;
      if (document.querySelectorAll('.lm_stack').length === 2 && !${JSON.stringify(ids)}.includes(id)) return id;
      await new Promise(r => setTimeout(r, 50));
    }
    throw new Error('Split did not open');
  })()`);
  await pressTab(false); await expectFocus(splitId);
  await pressTab(true); await expectFocus(splitId);
  await evaluate(`DomTerm._layout._selectLayoutPane(DomTerm._layout._numberToLayoutItem(${ids[0]}), 'test'); true`);
  await expectFocus(ids[0]);
  await pressTab(false); await expectFocus(ids[1]);
  await pressTab(true); await expectFocus(ids[0]);
  assert(await evaluate(`([...document.querySelectorAll('.lm_header')].every(e =>
    Math.abs(e.getBoundingClientRect().bottom - e.parentElement.getBoundingClientRect().bottom) < 1))`), 'Split tabs stay at bottom');
  console.log('PASS: tab navigation stays within its split');
} finally {
  clearTimeout(timer);
  socket.close();
}
