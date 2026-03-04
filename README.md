# CICD

各ユニットの CodeBuild プロジェクトを CloudFormation でデプロイするためのテンプレートと、デプロイスクリプトを管理する。

## ファイル構成

| ファイル | 内容 |
|---------|------|
| `infra.yaml` | インフラ（CDK deploy）用 CodeBuild プロジェクト |
| `backend_main.yaml` | メイン API（SAM build & deploy）用 CodeBuild プロジェクト |
| `backend_analysis.yaml` | 解析 API（SAM + Docker build & deploy）用 CodeBuild プロジェクト |
| `frontend.yaml` | フロントエンド（Vite build & S3 deploy）用 CodeBuild プロジェクト |
| `deploy.sh` | 上記テンプレートを CloudFormation にデプロイするスクリプト |

## 前提条件

- AWS CLI が設定済みであること（`aws configure` または環境変数）
- GitHub との CodeStar Connection が作成・承認済みであること（後述）
- `backend-analysis` をデプロイする場合、DockerHub 認証情報が SSM Parameter Store に登録済みであること
  - `/DockerHub/UserName`
  - `/DockerHub/AccessToken`

## GitHub 接続（CodeStar Connection）の準備

CodeBuild が GitHub リポジトリを参照するために、事前に AWS コンソールで接続を作成・承認する必要がある。

1. AWS コンソール → Developer Tools → Settings → Connections
2. 「Create connection」→ GitHub を選択
3. 接続名を入力して作成（例: `sgp-github`）
4. 「Pending」状態の接続を選択し「Update pending connection」で GitHub OAuth を承認
5. 承認後、接続の ARN をコピーする（例: `arn:aws:codeconnections:ap-northeast-1:XXXXXXXXXXXX:connection/xxx`）

## デプロイ手順

`deploy.sh` の先頭にある変数を編集してから実行する。

```bash
# deploy.sh の先頭を編集
ENV=dev
REGION=ap-northeast-1
CODESTAR_CONNECTION_ARN=arn:aws:codeconnections:ap-northeast-1:XXXXXXXXXXXX:connection/xxx
```

```bash
cd CICD
./deploy.sh
```

## 各 CodeBuild プロジェクトの動作

各プロジェクトは対応するリポジトリの `main` ブランチへの push をトリガーに自動実行される。buildspec の内容は各リポジトリの `buildspec.yml` を参照。

### infra

Infra リポジトリで CDK をデプロイする。デプロイ順序の注意：

- `stack-sgp-{env}-infra-cognito` はバックエンドより先にデプロイする必要がある
- `stack-sgp-{env}-infra-distribution` はバックエンド両方のデプロイ後にデプロイする必要がある（API Gateway ID を参照するため）

### backend-main / backend-analysis

SAM で Lambda + API Gateway をデプロイする。アーティファクト用 S3 バケットは `--resolve-s3` で自動管理される。`backend-analysis` は Docker イメージのビルドを含む。

### frontend

ビルド時に CloudFormation エクスポートから以下の値を取得し、`VITE_*` 環境変数として注入する。

| 環境変数 | 取得元エクスポート |
|---------|----------------|
| `VITE_COGNITO_AUTHORITY` | `sgp-{env}-infra-CognitoUserPoolId` |
| `VITE_COGNITO_CLIENT_ID` | `sgp-{env}-infra-CognitoClientId` |
| `VITE_REDIRECT_URI` | `sgp-{env}-infra-CloudFrontDomainName` |
| `VITE_API_BASE_URL` | 固定値 `/api/v1` |

ビルド後、`s3-sgp-{env}-infra-frontend` バケットに同期し、CloudFront キャッシュを無効化する。
