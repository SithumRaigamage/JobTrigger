# JobTrigger website (P15-23): Next.js `standalone` output on Node 24 LTS,
# the same Node line as `engines` and `.nvmrc`. Mirrors the backend image:
# build in one stage, run without the npm CLI in another.
FROM node:24-alpine AS build

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY . .
ENV NEXT_STANDALONE=1
# next/font downloads Inter and JetBrains Mono here (build needs network);
# the runtime never contacts Google (docs/web-architecture.md §6).
RUN npm run build

FROM node:24-alpine

ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0
WORKDIR /app

# Only what `next build` traced as needed, plus the static assets, which
# the standalone server serves itself when they sit next to it.
COPY --from=build --chown=node:node /app/.next/standalone ./
COPY --from=build --chown=node:node /app/.next/static ./.next/static
COPY --from=build --chown=node:node /app/public ./public

# No package manager at runtime (as in JobTrigger-Backend/Dockerfile).
RUN rm -rf /usr/local/lib/node_modules/npm \
  /usr/local/lib/node_modules/corepack \
  /usr/local/bin/npm \
  /usr/local/bin/npx \
  /usr/local/bin/corepack

USER node
EXPOSE 3000

# JOBTRIGGER_BACKEND_URL, SESSION_SECRET and SITE_URL come from the
# environment at run time (docs/deployment.md "Website"), never the image.
CMD ["node", "server.js"]
