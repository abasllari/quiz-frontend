### STAGE 1: Build ###
FROM node:12.14 AS build
WORKDIR /usr/src/app
COPY package.json package-lock.json ./
RUN npm install --save bootstrap
RUN npm install --save jquery
RUN npm install --save popper.js
COPY . .
RUN npm run build
### STAGE 2: Run ###
FROM nginx:1.17.1-alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY midpro.crt /etc/nginx/certs/midpro.crt
COPY midpro.key /etc/nginx/certs/midpro.key
COPY --from=build /usr/src/app/dist/quiz-frontend /usr/share/nginx/html
EXPOSE 80 443 4200

