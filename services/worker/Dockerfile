FROM node:18-alpine AS builder

# Enable pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy dependency files
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install --no-frozen-lockfile

# Copy source code
COPY . .

# Build
RUN pnpm run build

FROM node:18-alpine

# Enable pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy dependency files
COPY package.json pnpm-lock.yaml* ./

# Install production dependencies only
RUN pnpm install --prod --no-frozen-lockfile

# Copy built application from builder
COPY --from=builder /app/dist ./dist

CMD ["pnpm", "start"]
