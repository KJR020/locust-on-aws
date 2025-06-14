FROM locustio/locust:latest

# locustfile.pyをコンテナ内にコピー
COPY locustfile.py /mnt/locust/locustfile.py

# 必要に応じて追加のPythonパッケージをインストール
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt
