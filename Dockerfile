# ==== aws-cliインストール用の一時コンテナ ====
# ベースはAWS-CLIのDockerfileを参考に作成
# [aws-cli/Dockerfile at v2 · aws/aws-cli · GitHub](https://github.com/aws/aws-cli/blob/v2/docker/Dockerfile)
FROM amazonlinux:2 as aws-installer
RUN yum update -y \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && yum install -y unzip \
  && unzip awscliv2.zip \
  && ./aws/install --bin-dir /aws-cli-bin/
RUN /aws-cli-bin//aws --version

#==== AWS,Git作業用コンテナ ====
FROM ubuntu:18.04

#-- パッケージのインストールなど --

# 日本時間・日本語の設定
RUN apt-get update && apt-get install -y \
        tzdata \
        locales \
    && locale-gen ja_JP.UTF-8 \
    && apt clean && rm -rf /var/lib/apt/lists/*
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8

# AWS-CLIのインストール
COPY --from=aws-installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-installer /aws-cli-bin/ /usr/local/bin/

# ツールのインストール
# ※ lessが無いと`aws xxx`実行時に`[Errno 2] No such file or directory: 'less'`のエラーが出る
#   ref: https://github.com/aws/aws-cli/issues/5038
# ※ groffが無いと`aws help`実行時に`Could not find executable named "groff"`のエラーが出る
RUN apt-get update && apt-get install -y --no-install-recommends \
        less groff \
        git git-flow \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Python3, pip
RUN apt-get update && apt-get install -y \
        python3 \
        python-pip python3-pip \
        curl \
    && apt clean && rm -rf /var/lib/apt/lists/* \
    && curl -O https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py --user \
    && rm get-pip.py

# git-remote-codecommit
RUN pip install git-remote-codecommit

#-- 実行用の設定 --
WORKDIR /work

CMD [ "/bin/bash" ]
