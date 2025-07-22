FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the app
COPY . .

# Build Strapi (optional if you use build step)
# RUN npm run build

# Expose port
EXPOSE 1337

# Start the app
CMD ["npm", "start"]
