FROM python:3.11-slim
WORKDIR /workspace
COPY requirements.txt ./
RUN apt-get update && apt-get install -y build-essential libgl1-mesa-glx libglib2.0-0 && \
    pip install --no-cache-dir -r requirements.txt
COPY . /workspace
ENTRYPOINT ["python", "train.py"]
