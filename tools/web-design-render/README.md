# web-design-render

Regenerates `UI-UX/Web/screens/*/preview.html` and `screen.png` from the
website design sources in `UI-UX/Web/design/`.

The `.dc.html` sources need the design canvas's runtime, which isn't in the
repo. `render.mjs` ships a small stand-in runtime (holes, `sc-for`, `sc-if`,
`dc-import`), expands each page in headless Chrome, saves the result as
static HTML with links and screenshot paths rewritten for the repo, and
takes a 2x screenshot. Shared parts (header, footer, sidebar) are cropped
to the part itself.

```bash
cd tools/web-design-render
npm install
npm run render     # uses the installed Google Chrome on macOS
```

Run it after any change to a file in `UI-UX/Web/design/`.
