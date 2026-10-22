# AUD-17: an active LTS line (Node 20 reaches end of life in 2026).
#
# The install happens in a separate stage so the runtime image can be
# built without the npm CLI in it: the CLI is only needed to resolve the
# dependencies, and the app itself is started with `node server.js`.
FROM node:22-alpine AS deps

ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# The npm CLI that ships inside the node image is not used at runtime, and
# it carries its own advisories (the Trivy scan in security.yml flagged
# ten HIGH ones in npm's bundled dependencies on 2026-10-22). A production
# image has no business carrying a package manager, so it goes.
RUN rm -rf /usr/local/lib/node_modules/npm \
  /usr/local/lib/node_modules/corepack \
  /usr/local/bin/npm \
  /usr/local/bin/npx \
  /usr/local/bin/corepack

# Run as the image's unprivileged user, not root. The app only reads its
# files, so root keeps owning them.
USER node

EXPOSE 5001

# /healthz is 503 until MongoDB is connected. busybox wget ships with
# alpine, so no extra package.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${PORT:-5001}/healthz" || exit 1

CMD ["node", "server.js"]
