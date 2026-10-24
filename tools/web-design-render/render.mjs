// Renders the website's .dc.html design sources to static preview.html + screen.png.
// Usage: node render.mjs <designDir> <outScreensDir>
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright-core';

const [designDir, outDir] = process.argv.slice(2);

const pages = [
  ['Main', '01-home', 1440], ['Features', '02-features', 1440], ['Tools', '03-integrations', 1440],
  ['Security', '04-security', 1440], ['Privacy', '05-privacy', 1440], ['Support', '06-support', 1440],
  ['Changelog', '07-changelog', 1440], ['SignIn', '08-sign-in', 1440], ['SignUp', '09-sign-up', 1440],
  ['Servers', '10-my-servers', 1440], ['AddServer', '11-add-server', 1440], ['EditServer', '12-edit-server', 1440],
  ['Saved', '13-saved', 1440], ['Account', '14-account', 1440],
  ['Header', '15-header', 1440], ['Footer', '16-footer', 1440], ['Sidebar', '17-sidebar', 260],
];
const folderOf = Object.fromEntries(pages.map(([n, f]) => [n, f]));

const blobs = {
  e1bddce979008b06b2fafae929d8849b: '05-home-jenkins-dark',
  '31f898580c045f323769055ee797b0ee': '15-build-log',
  '67b7be205ba34a78a5d52899bfec454b': '11-job-detail',
  '78ef8c66a4820687efbd414d6977f65a': '24-home-widget-notification',
  '2f9245af334b975bad0300659b1eb789': '14-build-detail',
  '8d042c13f3dd8c0900c325bec4994bf6': '04-app-lock',
  eeca0d0ca3329ba30ab84201be86286a: '08-global-history',
  '228ae7b2f9d9d270b186370bbd3b462c': '07-home-github-repos',
};

function parse(name) {
  const src = fs.readFileSync(path.join(designDir, name + '.dc.html'), 'utf8');
  const title = (src.match(/<title>([\s\S]*?)<\/title>/) || [, name])[1];
  const helmet = (src.match(/<helmet>([\s\S]*?)<\/helmet>/) || [, ''])[1];
  let tpl = src.split('</helmet>')[1].split('</x-dc>')[0];
  // <template> survives table parsing; sc-for / sc-if would be foster-parented out of <tbody>.
  tpl = tpl.replace(/<sc-(for|if)\b/g, '<template data-kind="$1"').replace(/<\/sc-(for|if)>/g, '</template>');
  const script = src.match(/<script type="text\/x-dc" data-dc-script[^>]*>([\s\S]*?)<\/script>/)[1];
  return { title, helmet, tpl, script };
}

const runtime = `
(function () {
  class DCLogic { constructor(props) { this.props = props || {}; this.state = {}; } setState(s) { Object.assign(this.state, s); } forceUpdate() {} }
  const SRC = window.__SRC__;
  const loaded = new Set();
  const HOLE = /\\{\\{\\s*([\\w.$]+)\\s*\\}\\}/g;
  const WHOLE = /^\\s*\\{\\{\\s*([\\w.$]+)\\s*\\}\\}\\s*$/;
  function lookup(scope, p) {
    if (p === 'true') return true; if (p === 'false') return false;
    if (/^-?\\d+(\\.\\d+)?$/.test(p)) return Number(p);
    return p.split('.').reduce((o, k) => (o == null ? undefined : o[k]), scope);
  }
  function interp(str, scope) { return str.replace(HOLE, (_, p) => { const v = lookup(scope, p); return v == null ? '' : String(v); }); }
  function attrVal(v, scope) { const m = v.match(WHOLE); return m ? lookup(scope, m[1]) : interp(v, scope); }
  function camel(s) { return s.replace(/-([a-z])/g, (_, c) => c.toUpperCase()); }
  function mount(name, props) {
    const s = SRC[name];
    if (!loaded.has(name)) { loaded.add(name); const h = document.createElement('div'); h.innerHTML = s.helmet; [...h.childNodes].forEach((n) => document.head.appendChild(n)); }
    const Comp = new Function('DCLogic', s.script + '\\n;return Component;')(DCLogic);
    const inst = new Comp(props);
    const vals = inst.renderVals();
    const t = document.createElement('template'); t.innerHTML = s.tpl;
    const frag = document.createDocumentFragment();
    renderChildren(t.content, vals, frag);
    return frag;
  }
  function renderChildren(parent, scope, out) { parent.childNodes.forEach((n) => renderNode(n, scope, out)); }
  function renderNode(n, scope, out) {
    if (n.nodeType === 3) { out.appendChild(document.createTextNode(interp(n.nodeValue, scope))); return; }
    if (n.nodeType !== 1) return;
    const tag = n.tagName.toLowerCase();
    if (tag === 'template' && n.dataset.kind === 'for') {
      const list = attrVal(n.getAttribute('list'), scope) || [];
      const as = n.getAttribute('as');
      list.forEach((item, i) => renderChildren(n.content, Object.assign(Object.create(scope), { [as]: item, $index: i }), out));
      return;
    }
    if (tag === 'template' && n.dataset.kind === 'if') {
      if (attrVal(n.getAttribute('value'), scope)) renderChildren(n.content, scope, out);
      return;
    }
    if (tag === 'dc-import') {
      const props = {};
      [...n.attributes].forEach((a) => { if (a.name !== 'name' && !a.name.startsWith('hint-')) props[camel(a.name)] = attrVal(a.value, scope); });
      out.appendChild(mount(n.getAttribute('name'), props));
      return;
    }
    const el = n.namespaceURI === 'http://www.w3.org/2000/svg' ? document.createElementNS(n.namespaceURI, n.tagName) : document.createElement(n.tagName);
    [...n.attributes].forEach((a) => {
      if (/^on[A-Z]/.test(a.name) || /^on[a-z]+$/.test(a.name)) return;
      const v = attrVal(a.value, scope);
      if (v === undefined || v === null || v === false) return;
      el.setAttribute(a.name, v === true ? '' : String(v));
    });
    renderChildren(n.content || n, scope, el);
    out.appendChild(el);
  }
  document.body.appendChild(mount(window.__ENTRY__, {}));
  document.getElementById('__rt').remove();
})();
`;

function rewrite(html, folder) {
  return html
    .replace(/\/_blob\/([0-9a-f]{32})/g, (m, id) => (blobs[id] ? '../../../screens/' + blobs[id] + '/screen.png' : m))
    .replace(/href="([A-Za-z]+)\.dc\.html(#[\w-]+)?"/g, (m, n, hash) => (folderOf[n] ? 'href="../' + folderOf[n] + '/preview.html' + (hash || '') + '"' : m));
}

const all = {};
for (const [name] of pages) all[name] = parse(name);

const browser = await chromium.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' });
for (const [name, folder, width] of pages) {
  const dir = path.join(outDir, folder);
  fs.mkdirSync(dir, { recursive: true });
  const p = all[name];
  const shell = `<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<title>${p.title}</title>\n</head>\n<body>\n<script id="__rt">window.__ENTRY__=${JSON.stringify(name)};window.__SRC__=${JSON.stringify(all).replace(/</g, '\\u003c')};${runtime}</script>\n</body>\n</html>\n`;
  const file = path.join(dir, 'preview.html');
  fs.writeFileSync(file, rewrite(shell, folder));
  const page = await browser.newPage({ viewport: { width, height: 900 }, deviceScaleFactor: 2 });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto('file://' + file, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  if (errors.length) throw new Error(name + ': ' + errors.join('; '));
  const html = '<!doctype html>\n' + (await page.evaluate(() => document.documentElement.outerHTML)) + '\n';
  fs.writeFileSync(file, rewrite(html, folder));
  // Shared parts are cropped to the part itself; pages are captured full length.
  if (['Header', 'Footer', 'Sidebar'].includes(name)) {
    await page.locator('body > *').first().screenshot({ path: path.join(dir, 'screen.png') });
  } else {
    await page.screenshot({ path: path.join(dir, 'screen.png'), fullPage: true });
  }
  const h = await page.evaluate(() => document.body.firstElementChild.getBoundingClientRect().height | 0);
  console.log(folder, width + 'x' + h);
  await page.close();
}
await browser.close();
