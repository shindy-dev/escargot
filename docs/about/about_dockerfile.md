# Dockerfile 解説

本ドキュメントは、Python 3.13.3 環境をベースに構築された Docker イメージの `Dockerfile` の内容について、各ステップごとに解説を記載したものである。

---

## ベースイメージの指定

```dockerfile
FROM python:3.13.3-slim
```

- Python 3.13.3 の軽量バージョンを使用しており、不要なライブラリやドキュメントが除かれている。
- コンテナのサイズを抑える目的で `-slim` タグが選定されている。

---

## 環境変数の設定

```dockerfile
ENV DEBIAN_FRONTEND=noninteractive
```

- 対話的な入力が求められるパッケージインストール時の挙動を抑制するための設定。
- apt 関連のコマンドがスクリプトや Dockerfile 実行中に停止することを防ぐ。

---

## ポートの公開

```dockerfile
EXPOSE 8000
```

- Django デフォルトの開発用サーバーが使用する TCP ポート 8000 を明示的に開放する指定。

---

## パッケージのインストール

```dockerfile
RUN apt update && apt upgrade -y && \
    apt install -y git curl bzip2 && \
    apt autoremove -y && apt autoclean -y
```

- 必要なツール（`git`, `curl`, `bzip2`）のインストールを実行。
- システムのアップデートとともに、不要なパッケージやキャッシュも削除している。

---

## Micromamba のインストール

```dockerfile
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C /usr/local/bin --strip-components=1 bin/micromamba
```

- Micromamba をダウンロードし、実行可能パスに展開。
- Conda 互換の軽量な環境管理ツールで、Miniconda より高速・軽量。

---

## Python パッケージのインストール

```dockerfile
COPY docker/requirements.txt /root/requirements.txt
RUN micromamba create -y -n escargot python=3.13 && \
    micromamba run -n escargot python -m pip install --no-cache-dir -r /root/requirements.txt && \
    micromamba clean --all --yes && \
    micromamba shell init -s bash && \
    sed -i '$a micromamba activate escargot' /root/.bashrc
```

- `requirements.txt` を元に `escargot` という名前の Micromamba 環境を作成。
- Python 3.13 を指定し、必要なパッケージ群をインストール。
- 仮想環境のアクティベート設定を `.bashrc` に追記（ただし、非対話シェルでの効果は限定的）。

---

## キャッシュ削除

```dockerfile
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/*
```

- イメージサイズの削減を目的として、一時ファイルおよびキャッシュを削除。

---

## 作業ディレクトリの設定

```dockerfile
WORKDIR /home/dev/github/escargot
```

- コンテナ起動時のカレントディレクトリを設定。
- 後続の `git clone` や `manage.py` の操作がこのディレクトリで行われる。

---

## カスタムスクリプトの配置と実行権限付与

```dockerfile
COPY docker/scripts/postprocessing.sh /var/custom/postprocessing.sh
RUN chmod +x /var/custom/postprocessing.sh
```

- 任意の処理を記述したスクリプトを `/var/custom` に配置。
- エントリーポイント実行時に自動実行される前提で、実行権限を付与。

---

## エントリーポイントスクリプトの配置と登録

```dockerfile
COPY docker/scripts/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

- コンテナ起動時に最初に実行されるスクリプトを `/usr/local/bin` にコピー。
- `ENTRYPOINT` により、このスクリプトをコンテナ実行時の入口として指定。

---

## デフォルトの実行コマンド

```dockerfile
CMD ["0.0.0.0:8000"]
```

- `ENTRYPOINT` に渡される引数のデフォルト値として、Django サーバー起動時のアドレスを指定。
- `docker run` 実行時に上書きが可能。

---

以上。
