# --- Stage 1: Builder ---
FROM golang:1.22-bullseye AS builder 

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install base utilities and essential build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    wget \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Create the output directory structure needed for the final stage copy
RUN mkdir -p /build_output/usr/local/bin

# --- Build gphotos-cdp directly from GitHub ---
RUN echo "Building gphotos-cdp from GitHub (bypassing proxy)..." \
 && GOPROXY=direct go install github.com/nielsabels/gphotos-cdp@a0f64212b6081bb21a9fb60336c6c5694889f35b

# Copy the compiled binary from the default Go install path to our output directory
RUN echo "Copying built binary..." \
 && cp /go/bin/gphotos-cdp /build_output/usr/local/bin/gphotos-cdp

# --- Stage 2: Final Image ---
# Start fresh from the same base image
FROM debian:bullseye-slim

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    wget \
    gnupg \
    unzip \
    jq \
    jhead \
    ca-certificates \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    xdg-utils \
  && rm -rf /var/lib/apt/lists/*

# Install Google Chrome stable
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
  && apt-get update \
  && apt-get install -y google-chrome-stable --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary FROM the builder stage
COPY --from=builder /build_output/usr/local/bin/gphotos-cdp /usr/local/bin/gphotos-cdp

# Ensure the copied binary is executable
RUN chmod +x /usr/local/bin/gphotos-cdp

# Install Xvfb AND its dependency xauth
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    xauth \ 
    procps \
  && rm -rf /var/lib/apt/lists/*

# Create downloads and chrome session directories
RUN mkdir /downloads
RUN mkdir /tmp/gphotos-cdp

# Set the working directory
WORKDIR /app

# Script which reads capture date from jpg/jpeg files and applies date to file on filesystem
RUN mkdir -p /app/scripts
COPY ./scripts/fix_time.sh /app/scripts/fix_time.sh
RUN chmod +x /app/scripts/fix_time.sh
