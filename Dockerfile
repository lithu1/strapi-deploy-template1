# Step 1: Build the app
FROM node:18-alpine as build

WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

# Step 2: Run the app
FROM node:18-alpine

WORKDIR /app
COPY --from=build /app ./

RUN npm install --production

EXPOSE 1337
CMD ["npm", "start"]
