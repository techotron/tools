FROM python:3.6.8-slim-stretch

RUN mkdir /app \
    mkdir /build

COPY requirements.txt /build/
COPY app/ /app/

RUN pip install -r /build/requirements.txt

CMD ["python", "-u", "/app/main.py"]