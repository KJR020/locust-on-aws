#!/bin/bash

# =============================================================================
# Docker イメージビルド・プッシュスクリプト
# ローカル開発・手動デプロイ用
# =============================================================================

set -euo pipefail

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# 設定
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
AWS_ACCOUNT_ID=""
FORCE_BUILD="${FORCE_BUILD:-false}"
TAG="${TAG:-latest}"

# =============================================================================
# 関数定義
# =============================================================================

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Docker イメージをビルドしてAWS ECRにプッシュします。

OPTIONS:
    -h, --help          このヘルプメッセージを表示
    -r, --region        AWS リージョン (デフォルト: ap-northeast-1)
    -t, --tag           イメージタグ (デフォルト: latest)
    -f, --force         変更検出をスキップして強制ビルド
    --locust-only       Locustイメージのみビルド
    --webserver-only    Webサーバーイメージのみビルド

ENVIRONMENT VARIABLES:
    AWS_REGION          AWS リージョン
    AWS_ACCOUNT_ID      AWS アカウントID (必須)
    FORCE_BUILD         強制ビルドフラグ (true/false)

EXAMPLES:
    # 全イメージをビルド・プッシュ
    $0

    # 特定のタグでビルド
    $0 --tag v1.0.0

    # Locustイメージのみビルド
    $0 --locust-only

    # 強制ビルド
    $0 --force
EOF
}

check_dependencies() {
    log "依存関係をチェック中..."
    
    local missing_deps=()
    
    # Aquaが利用可能かチェック
    if command -v aqua &> /dev/null; then
        log "Aquaを使用してツールを確認します"
        
        # Aqua経由でツールが利用可能かチェック
        if ! aqua which aws &> /dev/null; then
            missing_deps+=("aws-cli (via aqua)")
        fi
        
        if ! aqua which docker &> /dev/null; then
            missing_deps+=("docker (via aqua)")
        fi
        
        if ! aqua which git &> /dev/null && ! command -v git &> /dev/null; then
            missing_deps+=("git")
        fi
    else
        # 従来の方法でチェック
        if ! command -v aws &> /dev/null; then
            missing_deps+=("aws-cli")
        fi
        
        if ! command -v docker &> /dev/null; then
            missing_deps+=("docker")
        fi
        
        if ! command -v git &> /dev/null; then
            missing_deps+=("git")
        fi
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "以下の依存関係が不足しています: ${missing_deps[*]}"
        if command -v aqua &> /dev/null; then
            log "Aquaでツールをインストールするには: aqua install"
        fi
        exit 1
    fi
    
    success "依存関係チェック完了"
}

get_aws_account_id() {
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        log "AWS アカウントIDを取得中..."
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        if [ -z "$AWS_ACCOUNT_ID" ]; then
            error "AWS アカウントIDの取得に失敗しました"
            exit 1
        fi
    fi
    log "AWS Account ID: $AWS_ACCOUNT_ID"
}

check_ecr_repositories() {
    log "ECRリポジトリの存在確認中..."
    
    local repos=("locust-fargate-locust-custom" "locust-fargate-test-webserver")
    
    for repo in "${repos[@]}"; do
        if ! aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" &> /dev/null; then
            error "ECRリポジトリ '$repo' が見つかりません"
            error "Terraformでインフラをデプロイしてください"
            exit 1
        fi
    done
    
    success "ECRリポジトリ確認完了"
}

ecr_login() {
    log "ECRにログイン中..."
    aws ecr get-login-password --region "$AWS_REGION" | docker --context desktop-linux login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    success "ECRログイン完了"
}

detect_changes() {
    if [ "$FORCE_BUILD" = "true" ]; then
        log "強制ビルドモード: 全てのイメージをビルドします"
        BUILD_LOCUST=true
        BUILD_WEBSERVER=true
        return
    fi
    
    log "変更検出中..."
    
    # Git がインストールされていて、リポジトリの場合のみ変更検出
    if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
        # 最新の変更を検出
        local changed_files=""
        if git diff --name-only HEAD~1 HEAD &> /dev/null; then
            changed_files=$(git diff --name-only HEAD~1 HEAD)
        else
            # 初回コミットの場合、全ファイルを対象
            changed_files=$(git ls-files)
        fi
        
        BUILD_LOCUST=false
        BUILD_WEBSERVER=false
        
        if echo "$changed_files" | grep -q "^apps/locust/"; then
            BUILD_LOCUST=true
            log "Locustアプリケーションの変更を検出"
        fi
        
        if echo "$changed_files" | grep -q "^apps/webserver/"; then
            BUILD_WEBSERVER=true
            log "Webサーバーアプリケーションの変更を検出"
        fi
        
        if [ "$BUILD_LOCUST" = "false" ] && [ "$BUILD_WEBSERVER" = "false" ]; then
            warn "アプリケーションコードの変更が検出されませんでした"
            warn "強制ビルドするには --force オプションを使用してください"
            exit 0
        fi
    else
        warn "Git リポジトリではないため、全てのイメージをビルドします"
        BUILD_LOCUST=true
        BUILD_WEBSERVER=true
    fi
}

build_and_push_image() {
    local app_name="$1"
    local image_name="$2"
    local context_dir="$3"
    
    log "$app_name イメージをビルド中..."
    
    local registry="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    local full_image_name="$registry/$image_name:$TAG"
    
    # ビルド
    docker --context desktop-linux build -t "$full_image_name" "$context_dir"
    
    # プッシュ
    log "$app_name イメージをプッシュ中..."
    docker --context desktop-linux push "$full_image_name"
    
    # latest タグも更新（tagがlatestでない場合）
    if [ "$TAG" != "latest" ]; then
        local latest_image="$registry/$image_name:latest"
        docker --context desktop-linux tag "$full_image_name" "$latest_image"
        docker --context desktop-linux push "$latest_image"
    fi
    
    success "$app_name イメージのビルド・プッシュ完了: $full_image_name"
}

# =============================================================================
# メイン処理
# =============================================================================

main() {
    log "Docker イメージビルド・プッシュスクリプト開始"
    
    # 引数解析
    BUILD_LOCUST=true
    BUILD_WEBSERVER=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--region)
                AWS_REGION="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_BUILD=true
                shift
                ;;
            --locust-only)
                BUILD_LOCUST=true
                BUILD_WEBSERVER=false
                shift
                ;;
            --webserver-only)
                BUILD_LOCUST=false
                BUILD_WEBSERVER=true
                shift
                ;;
            *)
                error "不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 前処理
    check_dependencies
    get_aws_account_id
    check_ecr_repositories
    ecr_login
    
    # オプションによる制御がない場合は変更検出
    if [ "$BUILD_LOCUST" = "true" ] && [ "$BUILD_WEBSERVER" = "true" ] && [ "$FORCE_BUILD" != "true" ]; then
        detect_changes
    fi
    
    # ビルド・プッシュ実行
    if [ "$BUILD_LOCUST" = "true" ]; then
        build_and_push_image "Locust" "locust-fargate-locust-custom" "$PROJECT_ROOT/apps/locust"
    fi
    
    if [ "$BUILD_WEBSERVER" = "true" ]; then
        build_and_push_image "Webserver" "locust-fargate-test-webserver" "$PROJECT_ROOT/apps/webserver"
    fi
    
    success "全ての処理が完了しました"
    
    log "次のステップ:"
    log "1. ECSサービスを更新してください:"
    if [ "$BUILD_LOCUST" = "true" ]; then
        log "   aws ecs update-service --cluster locust-fargate-cluster --service locust-fargate-master-service --force-new-deployment"
        log "   aws ecs update-service --cluster locust-fargate-cluster --service locust-fargate-worker-service --force-new-deployment"
    fi
    if [ "$BUILD_WEBSERVER" = "true" ]; then
        log "   aws ecs update-service --cluster locust-fargate-cluster --service locust-fargate-target-test-service --force-new-deployment"
    fi
    log "2. または Terraform で再デプロイしてください:"
    log "   cd terraform && terraform apply"
}

# スクリプトが直接実行された場合のみmain関数を呼び出す
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi