FROM python:3

ARG uid
ARG gid
WORKDIR /usr/src/app
COPY . .
RUN pip install -r requirements.txt

USER ${uid}:${gid}

CMD ["consumer.py"]
ENTRYPOINT ["python3"]

