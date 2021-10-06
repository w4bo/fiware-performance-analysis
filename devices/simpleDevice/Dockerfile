from node:16

ARG uid

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8080

ENV NODE_OPTIONS=--max_old_space_size=60000

CMD ["node", "server.js"]

RUN usermod -u ${uid} node
USER node
