FROM node:18-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ENV MONGODB_URI="mongodb+srv://admin:adminpass123@kutumbsetu.zd2txth.mongodb.net/kutumbsetu?retryWrites=true&w=majority&appName=KutumbSetu"
EXPOSE 5000
CMD ["node","server.js"]