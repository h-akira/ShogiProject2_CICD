#!/bin/bash
set -e

ENV=pro
REGION=ap-northeast-1
GITHUB_BRANCH=main
CODESTAR_CONNECTION_ARN=arn:aws:codeconnections:ap-northeast-1:XXXXXXXXXXXX:connection/xxx
DOMAIN_NAME=shogi.example.com
ACM_CERTIFICATE_ARN=arn:aws:acm:us-east-1:XXXXXXXXXXXX:certificate/xxx
HOSTED_ZONE_NAME=shogi.example.com
COGNITO_AUTH_DOMAIN=auth.shogi.example.com
COGNITO_CERTIFICATE_ARN=${ACM_CERTIFICATE_ARN}

NOTICE_ENV=common

aws cloudformation deploy \
  --stack-name "stack-sgp-${NOTICE_ENV}-cicd-notice" \
  --template-file notice.yaml \
  --region ${REGION} \
  --parameter-overrides Env=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-infra" \
  --template-file infra.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubBranch=${GITHUB_BRANCH} \
    DomainName=${DOMAIN_NAME} AcmCertificateArn=${ACM_CERTIFICATE_ARN} \
    HostedZoneName=${HOSTED_ZONE_NAME} CognitoAuthDomain=${COGNITO_AUTH_DOMAIN} \
    CognitoCertificateArn=${COGNITO_CERTIFICATE_ARN} \
    AllowedIps= \
    SourceType=CODEPIPELINE \
    EnableWebhook=false \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-backend-main" \
  --template-file backend_main.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubBranch=${GITHUB_BRANCH} \
    SourceType=CODEPIPELINE \
    EnableWebhook=false \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-backend-analysis" \
  --template-file backend_analysis.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubBranch=${GITHUB_BRANCH} \
    SourceType=CODEPIPELINE \
    EnableWebhook=false \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-frontend" \
  --template-file frontend.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubBranch=${GITHUB_BRANCH} \
    SourceType=CODEPIPELINE \
    EnableWebhook=false \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-pipeline-infra" \
  --template-file pipeline.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} Component=infra \
    CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubRepo=ShogiProject2_Infra \
    GitHubBranch=${GITHUB_BRANCH} \
    CodeBuildStackName=stack-sgp-${ENV}-cicd-infra \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-pipeline-backend-main" \
  --template-file pipeline.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} Component=backend-main \
    CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubRepo=ShogiProject2_Backend_main \
    GitHubBranch=${GITHUB_BRANCH} \
    CodeBuildStackName=stack-sgp-${ENV}-cicd-backend-main \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-pipeline-backend-analysis" \
  --template-file pipeline.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} Component=backend-analysis \
    CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubRepo=ShogiProject2_Backend_analysis \
    GitHubBranch=${GITHUB_BRANCH} \
    CodeBuildStackName=stack-sgp-${ENV}-cicd-backend-analysis \
    OutputArtifactFormat=CODEBUILD_CLONE_REF \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}

aws cloudformation deploy \
  --stack-name "stack-sgp-${ENV}-cicd-pipeline-frontend" \
  --template-file pipeline.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION} \
  --parameter-overrides Env=${ENV} Component=frontend \
    CodeStarConnectionArn=${CODESTAR_CONNECTION_ARN} \
    GitHubRepo=ShogiProject2_Frontend \
    GitHubBranch=${GITHUB_BRANCH} \
    CodeBuildStackName=stack-sgp-${ENV}-cicd-frontend \
    EnableNotification=true \
    NotificationEnv=${NOTICE_ENV}
