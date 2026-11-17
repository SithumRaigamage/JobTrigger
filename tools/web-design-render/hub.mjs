// Builds the screen galleries in UI-UX/:
//   preview.html          — every app and website screen
//   preview-launch.html   — the website as it launches (coming-soon pages + pages that ship unchanged)
//   preview-complete.html — the website as the finished product (approved v4)
// Usage: node hub.mjs <UI-UX dir>
import fs from 'node:fs';
import path from 'node:path';

const [uiux] = process.argv.slice(2);

const web = {
  marketing: [
    ['01-home', 'Home', 'US-WEB-01, 02'], ['02-features', 'Features', 'US-WEB-03'],
    ['03-integrations', 'Integrations', 'US-WEB-04'], ['04-security', 'Security', 'US-WEB-05'],
    ['05-privacy', 'Privacy policy', 'US-WEB-06'], ['06-support', 'Support', 'US-WEB-06'],
    ['07-changelog', 'Changelog', 'US-WEB-08'],
  ],
  portal: [
    ['08-sign-in', 'Sign in', 'US-WEB-10, 20'], ['09-sign-up', 'Sign up', 'US-WEB-10'],
    ['10-my-servers', 'My servers', 'US-WEB-11, 18'], ['11-add-server', 'Add server', 'US-WEB-12–14, 16, 19'],
    ['12-edit-server', 'Edit / delete server', 'US-WEB-15'], ['13-saved', 'Now open the app', 'US-WEB-17'],
    ['14-account', 'Account', 'US-WEB-20, 21'],
  ],
  shared: [['15-header', 'Marketing header', 'Shared'], ['16-footer', 'Footer', 'Shared'], ['17-sidebar', 'Portal sidebar', 'Shared']],
  prelaunch: [
    ['18-home-prelaunch', 'Home', 'US-WEB-02, 22'], ['19-features-prelaunch', 'Features', 'US-WEB-03, 22'],
    ['20-integrations-prelaunch', 'Integrations', 'US-WEB-04, 22'], ['21-changelog-prelaunch', 'Changelog', 'US-WEB-08, 22'],
    ['22-add-server-prelaunch', 'Add server', 'US-WEB-19, 22'], ['23-saved-prelaunch', 'Now open the app', 'US-WEB-17, 22'],
  ],
  prelaunchShared: [['24-header-prelaunch', 'Header', 'Shared'], ['25-footer-prelaunch', 'Footer', 'Shared']],
};

// The site at launch: each page's pre-launch variant where one exists, else the approved page as-is.
const byFolder = Object.fromEntries(Object.values(web).flat().map((p) => [p[0], p]));
const soon = (f) => [...byFolder[f], 'soon'];
const same = (f) => [...byFolder[f], 'same'];
const launch = {
  marketing: [soon('18-home-prelaunch'), soon('19-features-prelaunch'), soon('20-integrations-prelaunch'),
    same('04-security'), same('05-privacy'), same('06-support'), soon('21-changelog-prelaunch')],
  portal: [same('08-sign-in'), same('09-sign-up'), same('10-my-servers'), soon('22-add-server-prelaunch'),
    same('12-edit-server'), soon('23-saved-prelaunch'), same('14-account')],
  shared: [soon('24-header-prelaunch'), soon('25-footer-prelaunch'), same('17-sidebar')],
};

// The app's screen list is the table in UI-UX/README.md.
const app = fs.readFileSync(path.join(uiux, 'README.md'), 'utf8')
  .split('\n')
  .map((l) => l.match(/^\| (\d{2}) \| ([^|]+?) \| \[png\]\(screens\/([^/]+)\/screen\.png\) \| (.+?) \|$/))
  .filter(Boolean)
  .map(([, n, name, folder, impl]) => ({ n, name, folder, impl: impl.replace(/`/g, '') }));

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const tags = {
  soon: '<span class="tag soon">Coming-soon version</span>',
  same: '<span class="tag same">Same as final</span>',
};

const webCard = ([folder, name, stories, kind], part) => {
  const base = `Web/screens/${folder}`;
  return `<article class="card${part ? ' part' : ''}">
  <a class="thumb web" href="${base}/preview.html"><img src="${base}/screen.png" alt="${esc(name)} design"></a>
  <div class="meta"><div class="badges"><span class="num">W${folder.slice(0, 2)}</span>${kind ? tags[kind] : ''}</div><h3>${esc(name)}</h3><p>${esc(stories)}</p>
  <div class="links"><a href="${base}/preview.html">Open preview</a><a href="${base}/screen.png">PNG</a></div></div>
</article>`;
};

const appCard = (s) => `<article class="card phone">
  <a class="thumb app" href="screens/${s.folder}/preview.html"><img src="screens/${s.folder}/screen.png" alt="${esc(s.name)} design"></a>
  <div class="meta"><div class="badges"><span class="num">A${s.n}</span></div><h3>${esc(s.name)}</h3><p class="mono">${esc(s.impl)}</p>
  <div class="links"><a href="screens/${s.folder}/preview.html">Open preview</a><a href="screens/${s.folder}/screen.png">PNG</a></div></div>
</article>`;

const section = (id, kicker, title, note, cards, phones) => `  <section id="${id}">
    <div class="sec-head"><div><span class="kicker">${kicker}</span><h2>${title}</h2></div>${note ? `<p>${note}</p>` : ''}</div>
    <div class="grid${phones ? ' phones' : ''}">${cards}</div>
  </section>`;

const views = [
  ['preview.html', 'Everything'],
  ['preview-launch.html', 'Website at launch'],
  ['preview-complete.html', 'Website complete'],
];

function render(file, { title, lead, sections }) {
  const count = sections.reduce((n, s) => n + s.n, 0);
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>JobTrigger — ${esc(title.toLowerCase())}</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet">
<!-- Generated by tools/web-design-render/hub.mjs — edit that, not this file. -->
<style>
:root{--ink:#0F172A;--muted:#475569;--line:#E2E8F0;--bg:#F8FAFC;--navy:#0B1120;--accent:#2563EB;--link:#1D4ED8}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font-family:Inter,system-ui,sans-serif}
a{color:var(--link);text-decoration:none}a:hover{color:#1E40AF}
header{background:var(--navy);color:#F1F5F9;background-image:radial-gradient(#1F2A3D 1px,transparent 1px);background-size:28px 28px}
.wrap{max-width:1280px;margin:0 auto;padding:0 20px}
.top{padding:48px 0 36px;display:flex;flex-direction:column;gap:14px}
.brand{display:flex;align-items:center;gap:10px;font-weight:800;font-size:18px}
.logo{width:34px;height:34px;border-radius:10px;background:var(--accent);display:flex;align-items:center;justify-content:center}
h1{margin:0;font-size:52px;line-height:1.05;font-weight:800;letter-spacing:-.04em}
.lead{margin:0;max-width:760px;font-size:17px;line-height:1.55;color:#CBD5E1}
.views{display:flex;flex-wrap:wrap;gap:8px;padding-top:6px}
.views a{padding:10px 16px;border-radius:999px;font-size:14px;font-weight:700;background:#111A2B;color:#CBD5E1;border:1px solid #1F2A3D}
.views a:hover{color:#fff}
.views a[aria-current="page"]{background:#F1F5F9;color:var(--navy);border-color:#F1F5F9}
nav.jump{position:sticky;top:0;z-index:2;background:rgba(11,17,32,.95);border-bottom:1px solid #1F2A3D}
nav.jump .wrap{display:flex;flex-wrap:wrap;gap:4px 8px;padding-top:10px;padding-bottom:10px}
nav.jump a{color:#CBD5E1;font-size:14px;font-weight:600;padding:8px 12px;border-radius:999px;background:#111A2B}
nav.jump a:hover{color:#fff;background:#1E293B}
nav.jump .count{color:#94A3B8;font-weight:500;margin-left:6px}
section{padding:48px 0 8px}
.sec-head{display:flex;flex-wrap:wrap;align-items:baseline;justify-content:space-between;gap:8px;margin-bottom:20px}
h2{margin:0;font-size:28px;font-weight:800;letter-spacing:-.03em}
.kicker{font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--link)}
.sec-head p{margin:0;max-width:560px;font-size:14px;color:var(--muted)}
.grid{display:grid;gap:20px;grid-template-columns:repeat(auto-fill,minmax(300px,1fr))}
.grid.phones{grid-template-columns:repeat(auto-fill,minmax(200px,1fr))}
.card{background:#fff;border:1px solid var(--line);border-radius:20px;overflow:hidden;box-shadow:0 1px 2px rgba(15,23,42,.06);display:flex;flex-direction:column}
.card:hover{box-shadow:0 12px 28px rgba(15,23,42,.12)}
.thumb{display:block;background:var(--navy);border-bottom:1px solid var(--line)}
.thumb img{display:block;width:100%;object-fit:cover;object-position:top}
.thumb.web img{height:220px}
.part .thumb.web img{height:auto;max-height:220px;object-fit:contain;object-position:center}
.thumb.app{padding:16px 16px 0;background:#E2E8F0}
.thumb.app img{height:300px;border-radius:18px 18px 0 0}
.meta{padding:16px 18px 18px;display:flex;flex-direction:column;gap:6px;flex:1}
.badges{display:flex;flex-wrap:wrap;gap:6px}
.num{font-family:'JetBrains Mono',monospace;font-size:12px;padding:2px 8px;border-radius:6px;background:#DBEAFE;color:var(--link)}
.tag{font-size:12px;font-weight:700;padding:2px 8px;border-radius:999px}
.tag.soon{background:#F1F5F9;color:#334155;border:1px dashed #94A3B8}
.tag.same{background:#DCFCE7;color:#15803D}
h3{margin:0;font-size:17px;font-weight:700}
.meta p{margin:0;font-size:13px;color:var(--muted)}
.mono{font-family:'JetBrains Mono',monospace;font-size:12px!important;word-break:break-word}
.links{margin-top:auto;padding-top:10px;display:flex;gap:16px;font-size:14px;font-weight:600}
footer{padding:56px 0;color:var(--muted);font-size:13px}
@media (max-width:600px){h1{font-size:38px}}
</style>
</head>
<body>
<header>
  <div class="wrap top">
    <span class="brand"><span class="logo"><svg width="16" height="16" viewBox="0 0 24 24" fill="#fff" aria-hidden="true"><path d="M8 5v14l11-7z"/></svg></span>JobTrigger</span>
    <h1>${esc(title)}</h1>
    <p class="lead">${lead.replace('{count}', count)}</p>
    <nav class="views" aria-label="Gallery">${views.map(([f, l]) => `<a href="${f}"${f === file ? ' aria-current="page"' : ''}>${l}</a>`).join('')}</nav>
  </div>
</header>
<nav class="jump" aria-label="Sections">
  <div class="wrap">
${sections.map((s) => `    <a href="#${s.id}">${s.label}<span class="count">${s.n}</span></a>`).join('\n')}
  </div>
</nav>
<main class="wrap">
${sections.map((s) => s.html).join('\n')}
</main>
<footer class="wrap">Generated by <code>tools/web-design-render/hub.mjs</code>.</footer>
</body>
</html>
`;
  fs.writeFileSync(path.join(uiux, file), html);
  console.log('wrote', file, 'with', count, 'screens');
}

const s = (id, label, kicker, title, note, list, opts = {}) => ({
  id, label, n: list.length,
  html: section(id, kicker, title, note, opts.app ? list.map(appCard).join('\n') : list.map((p) => webCard(p, opts.part)).join('\n'), opts.app),
});

const appSection = s('app', 'App', 'Mobile app', 'App screens', 'Design notes: <a href="README.md">README.md</a>', app, { app: true });

render('preview.html', {
  title: 'All screens',
  lead: '{count} approved designs — the website (finished and pre-launch) and the app. Click any screen to open its preview.',
  sections: [
    s('web-marketing', 'Website · Marketing', 'Website', 'Marketing pages', 'Design notes: <a href="Web/README.md">Web/README.md</a>', web.marketing),
    s('web-portal', 'Website · Setup portal', 'Website', 'Setup portal', '', web.portal),
    s('web-shared', 'Website · Shared parts', 'Website', 'Shared parts', '', web.shared, { part: true }),
    s('web-prelaunch', 'Website · Pre-launch', 'Website', 'Pre-launch — coming-soon states', 'Used while the app is in development (US-WEB-22). Same pages, with unshipped features marked.', web.prelaunch.concat(web.prelaunchShared)),
    appSection,
  ],
});

render('preview-launch.html', {
  title: 'Website at launch',
  lead: 'The {count} screens the site ships with while the app is still in development (US-WEB-22). Pages tagged <strong>Coming-soon version</strong> mark unshipped features; <strong>Same as final</strong> pages need no change.',
  sections: [
    s('marketing', 'Marketing', 'At launch', 'Marketing pages', '', launch.marketing),
    s('portal', 'Setup portal', 'At launch', 'Setup portal', '', launch.portal),
    s('shared', 'Shared parts', 'At launch', 'Shared parts', '', launch.shared, { part: true }),
  ],
});

render('preview-complete.html', {
  title: 'Website complete',
  lead: 'The {count} approved v4 screens — the website once every feature has shipped.',
  sections: [
    s('marketing', 'Marketing', 'Complete', 'Marketing pages', 'Design notes: <a href="Web/README.md">Web/README.md</a>', web.marketing),
    s('portal', 'Setup portal', 'Complete', 'Setup portal', '', web.portal),
    s('shared', 'Shared parts', 'Complete', 'Shared parts', '', web.shared, { part: true }),
  ],
});
