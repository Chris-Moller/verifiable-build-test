FROM node:18-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

FROM build AS prod-deps
RUN npm prune --omit=dev

FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=prod-deps /app/package.json ./
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
RUN mkdir -p /ecloud/bin && \
    cp -a dist /ecloud/bin/ && \
    cp -a node_modules /ecloud/bin/ && \
    cp package.json /ecloud/bin/package.json && \
    printf '%s\n' '#!/bin/sh' 'SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)" || exit 1' 'exec node "$SCRIPT_DIR/dist/index.js" "$@"' > /ecloud/bin/randomness-beacon && \
    chmod -R a+rx /ecloud/bin
EXPOSE 8080
CMD ["node", "dist/index.js"]
