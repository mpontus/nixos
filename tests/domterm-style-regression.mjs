// Run against a disposable VM: open two tabs and run `domterm help` in one.
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
const timer = setTimeout(() => { console.error('FAIL: debugger timed out'); process.exit(1); }, 10000);
try {
  await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
  const response = new Promise(resolve => { socket.onmessage = e => resolve(JSON.parse(e.data)); });
  socket.send(JSON.stringify({id: 1, method: 'Runtime.evaluate', params: {
    returnByValue: true,
    expression: `(() => {
      const results = [];
      const check = (ok, name) => results.push({ok, name});
      const style = e => e.ownerDocument.defaultView.getComputedStyle(e);
      const tabs = [...document.querySelectorAll('.lm_tabs .lm_tab')];
      check(tabs.length >= 2, 'multiple tabs exercised');
      check([...document.querySelectorAll('.lm_items')].every(e => style(e).borderTopWidth === '0px'), 'no inner pane frame');
      const active = tabs.find(e => e.classList.contains('lm_active'));
      check(!!active && style(active).backgroundColor === 'rgba(0, 0, 0, 0)' && style(active).boxShadow === 'none', 'no active tab fill or underline');
      check(style(document.body).backgroundColor === 'rgb(19, 28, 43)', 'no contrasting live-layout gaps');
      const docs = [document, ...[...document.querySelectorAll('iframe')].map(f => f.contentDocument)];
      const buffers = docs.flatMap(d => [...d.querySelectorAll('.dt-buffers')]);
      check(buffers.length > 0 && buffers.every(e => style(e).scrollbarWidth === 'none'), 'scrollbars hidden in every pane');
      const headings = docs.flatMap(d => [...d.querySelectorAll('.domterm h2')]);
      check(headings.length > 0 && headings.every(e => style(e).fontFamily.includes('Noto Sans')), 'help typography uses sans-serif');
      const code = docs.flatMap(d => [...d.querySelectorAll('.domterm code')]);
      check(code.length > 0 && code.every(e => style(e).fontFamily.includes('JetBrainsMono')), 'code typography stays monospace');
      return results;
    })()`
  }}));
  const result = await response;
  assert(!result.error && !result.result?.exceptionDetails, 'Debugger evaluation failed');
  for (const check of result.result.result.value) {
    console.log(`${check.ok ? 'PASS' : 'FAIL'}: ${check.name}`);
    assert(check.ok, check.name);
  }
} finally {
  clearTimeout(timer);
  socket.close();
}
