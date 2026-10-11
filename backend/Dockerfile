FROM node:18-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Match the environment key used in docker-compose
ENV MONGO_URI="mongodb://mongodb:27017/kutumbsetu"
EXPOSE 5000
CMD ["node","server.js"]
