FROM node:20-alpine

WORKDIR /app

# Install deps first so this layer is cached unless package*.json changes
COPY package*.json ./
RUN npm ci

# Rest of the source is bind-mounted over this in docker-compose.yml (see
# root docker-compose.yml, assurex-frontend service) for hot reload — this
# COPY just makes the image runnable standalone too (e.g. `docker build` +
# `docker run` without compose).
COPY . .

EXPOSE 5173

# --host 0.0.0.0 so the dev server is reachable from outside the container
# (default Vite dev server only binds to the container's own localhost).
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
