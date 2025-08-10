#FROM python:3.12.3-slim

# Use Ubuntu as base image for better Chrome compatibility
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99
ENV CHROME_BIN=/usr/bin/google-chrome
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    curl \
    unzip \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Add Google Chrome repository
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list

# Install Google Chrome
RUN apt-get update && apt-get install -y \
    google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (if you're using a Node.js application)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Create app directory
#WORKDIR /app

# Copy package files (if using Node.js)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Create a user to run Chrome (Chrome won't run as root)
RUN groupadd -r chromeuser && useradd -r -g chromeuser -G audio,video chromeuser \
    && mkdir -p /home/chromeuser/Downloads \
    && chown -R chromeuser:chromeuser /home/chromeuser \
    && chown -R chromeuser:chromeuser /app


# Install Chrome
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 5000

# Switch to non-root user
USER chromeuser

CMD ["python", "main.py"]
