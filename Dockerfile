FROM ubuntu:24.04

# 使用するポートの宣言（Web/Django）
EXPOSE 8000

# 必要パッケージのインストール
RUN apt update && apt upgrade -y && \
    apt install -y git wget nginx bzip2 && \
    apt autoremove -y && apt autoclean -y

# Miniforge のインストール（バージョン固定）
RUN wget --no-check-certificate https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Miniforge3-Linux-x86_64.sh && \
    bash Miniforge3-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniforge3-Linux-x86_64.sh && \
    /opt/conda/bin/conda init && /opt/conda/bin/conda clean --all --yes
# pipでインストールするパッケージリストのコピー
COPY docker/requirements.txt /root/requirements.txt
# Conda環境作成と依存インストール（まとめて実行）
RUN /bin/bash -c "source /opt/conda/etc/profile.d/conda.sh && \
    conda create -n escargot python=3.12.10 -y && \
    conda activate escargot && \
    pip install --no-cache-dir -r /root/requirements.txt && \
    conda clean --all --yes"
# 環境変数の設定
ENV PATH="/opt/conda/bin:$PATH"
# Conda環境を有効にするためのコマンドを追記
RUN sed -i '$a conda activate escargot' /root/.bashrc


# キャッシュ等削除
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/*

# コンテナ起動時の作業ディレクトリ
WORKDIR /home/dev/github/escargot

# サーバ初期化後に処理したいスクリプト(entrypoint.sh内でコール)をコピー
COPY docker/scripts/postprocessing.sh /var/custom/postprocessing.sh
RUN chmod +x /var/custom/postprocessing.sh

# エントリーポイント（コンテナ起動時の動作）設定
COPY docker/scripts/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# docker run 時のデフォルトコマンド
# docker run <image> <ip>:<port>で任意のip:portを指定可能
CMD ["0.0.0.0:8000"]