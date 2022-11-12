FROM python:3.9

RUN mkdir /app
ADD app.py requirements.txt /app/
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["flask", "run", "--host=0.0.0.0"]
