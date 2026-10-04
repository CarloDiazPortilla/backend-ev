FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

FROM node:20-alpine AS runner

ENV NODE_ENV=production

WORKDIR /app

COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .

EXPOSE 3000

USER node

CMD ["node", "index.js"]
