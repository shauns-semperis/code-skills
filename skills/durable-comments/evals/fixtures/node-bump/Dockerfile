# Node runtime for the build stage.
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Static files only; no Node in the final image.
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
