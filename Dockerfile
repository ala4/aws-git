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
FROM ubuntu:20.04

#-- パッケージのインストールなど --

# 日本時間・日本語の設定
RUN apt-get update && apt-get install -y \
        tzdata \
        locales \
    && locale-gen ja_JP.UTF-8 \
    && apt clean && rm -rf /var/lib/apt/lists/*
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8

# コンテナ実行用の非rootユーザー
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    apt update -y && \
    apt-get install -y sudo && \
    apt clean && rm -rf /var/lib/apt/lists/* && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# AWS-CLIのインストール
COPY --from=aws-installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-installer /aws-cli-bin/ /usr/local/bin/

# Python3, pip
RUN apt update && apt install -y \
        python3 \
        python3-pip \
        curl \
    && apt clean && rm -rf /var/lib/apt/lists/*
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py --user && \
    rm get-pip.py

# git-remote-codecommit
RUN pip install git-remote-codecommit

# ツールのインストール
# ※ lessが無いと`aws xxx`実行時に`[Errno 2] No such file or directory: 'less'`のエラーが出る
#   ref: https://github.com/aws/aws-cli/issues/5038
# ※ groffが無いと`aws help`実行時に`Could not find executable named "groff"`のエラーが出る
RUN apt-get update && apt-get install -y --no-install-recommends \
        less groff jq \
        git git-flow \
    && apt clean && rm -rf /var/lib/apt/lists/*
# 利便性のため圧縮解凍ツールをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
        zip unzip \
    && apt clean && rm -rf /var/lib/apt/lists/*

# コンテナ実行用のユーザーで実行する
USER $USERNAME

#-- 実行用の設定 --
WORKDIR /work

CMD [ "/bin/bash" ]
