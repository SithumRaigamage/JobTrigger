# AUD-17: an active LTS line (Node 20 reaches end of life in 2026).
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY . .

# Run as the image's unprivileged user, not root. The app only reads its
# files, so root keeps owning them.
USER node

EXPOSE 5001

# /healthz is 503 until MongoDB is connected. busybox wget ships with
# alpine, so no extra package.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${PORT:-5001}/healthz" || exit 1

CMD ["node", "server.js"]
