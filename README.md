# aws-git

AWS CLI と Git（git-remote-codecommit）をインストール済みのコンテナ。

## 使用方法

AWSコマンドの実行

```
docker-compose run --rm aws sts get-caller-identity
docker run --rm  -v ~/.aws:/root/.aws ala4/aws-git aws sts get-caller-identity
```
