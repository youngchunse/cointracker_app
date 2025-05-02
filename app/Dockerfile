FROM python:3.9-slim

WORKDIR /app

COPY app.py .

RUN pip install flask

ENV PORT=80

EXPOSE 80

CMD ["python", "app.py"]