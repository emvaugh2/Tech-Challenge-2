FROM python:3.9-slim 
WORKDIR /hellocruelworld 
COPY hellocruelworld.py /hellocruelworld 
COPY requirements.txt /hellocruelworld 
RUN pip install --no-cache-dir -r requirements.txt 
EXPOSE 5000
CMD ["python", "hellocruelworld.py"]  
