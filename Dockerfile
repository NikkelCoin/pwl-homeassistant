FROM ghcr.io/puppeteer/puppeteer:latest as base

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/google-chrome-stable

RUN apt-get update && apt-get install gnupg wget -y && \
  wget --quiet --output-document=- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google-archive.gpg && \
  sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' && \
  apt-get update && \
  apt-get install google-chrome-stable -y --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

FROM base as deps
WORKDIR /usr/src/app

COPY --chown=pptruser:pptruser package*.json ./
RUN npm ci

FROM deps as build

COPY --chown=pptruser:pptruser . .
RUN npm run build

FROM base as final

WORKDIR /app

COPY --from=build /usr/src/app/dist ./
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY --from=deps /usr/src/app/package.json ./package.json

CMD ["node", "index.js"]
