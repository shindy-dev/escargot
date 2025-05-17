#!/bin/bash
set -e  # エラーがあれば即終了

# マーカーパス
MARKER_FILE="/var/.entrypoint_initialized"

# 初回起動チェック
if [ ! -f "$MARKER_FILE" ]; then
    # 初回起動時処理

    # git pull モード指定
    git config --global pull.rebase true
    # git pull
    (cd /home/dev/github/escargot && git clone -q https://github.com/shindy-dev/escargot.git .)

    # マーカーを作成
    touch "$MARKER_FILE"
fi

# /var/custom 内のすべての .sh ファイルを実行
if [ -d /var/custom ]; then
  for script in /var/custom/*.sh; do
    if [ -f "$script" ]; then
      chmod +x "$script"
      "$script"
    fi
  done
fi

# condaの初期化
source /opt/conda/etc/profile.d/conda.sh

# escargot環境のアクティベート
conda activate escargot
# ディレクトリ移動
cd /home/dev/github/escargot
if [ -f /home/dev/github/escargot/manage.py ]; then
    # manage.pyが存在する場合はマイグレーション＆サーバーを実行
    python manage.py makemigrations
    python manage.py migrate
    exec python manage.py runserver "$@"
else
    # manage.pyが存在しない場合はbashを実行
    exec /bin/bash
fi