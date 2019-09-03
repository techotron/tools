FROM python:3.7-slim-stretch

RUN mkdir /app \
    mkdir /build

COPY requirements.txt /build/ \
     main.py /app/ \
     aws/ /app/

RUN pip install -r /build/requirements.txt

CMD ["python", "-u", "/app/main.py"]