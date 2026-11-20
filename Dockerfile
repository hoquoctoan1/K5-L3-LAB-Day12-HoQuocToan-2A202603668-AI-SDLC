# Dockerfile: chạy headless (Test Contract) của game Đảo Đèn Lồng trong container Linux.
#
# CHƯA KIỂM CHỨNG: file này được viết trên máy Windows không có Docker, nên CHƯA được
# build hay chạy thử. Trước khi dùng, hãy chạy:
#   docker build -t dao-den-long .
#   docker run --rm -v "$PWD/out:/app/out" dao-den-long --seed 1 --night 1 --ticks 600 --out /app/out/out.jsonl
# Nếu Godot báo thiếu thư viện hệ thống, thêm gói tương ứng vào bước apt-get.
#
# Phiên bản Godot là ARG GODOT_VERSION. Tên file zip theo mẫu release Linux của Godot:
#   Godot_v<version>-stable_linux.x86_64.zip  (tải từ godot-builds trên GitHub)
# Chế độ headless không mở cửa sổ render nên không cần GPU.

FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7.2
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates unzip wget \
 && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/godot.zip \
      "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
 && unzip -q /tmp/godot.zip -d /tmp/godot \
 && mv "/tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm -rf /tmp/godot /tmp/godot.zip

ENV GODOT=/usr/local/bin/godot

WORKDIR /app
# Chỉ copy phần cần cho headless: không copy node_modules, dist, hay scaffold CP0.
COPY godot /app/godot
COPY scripts /app/scripts
RUN mkdir -p /app/out

# Entrypoint là wrapper headless của repo. Tham số truyền khi docker run.
ENTRYPOINT ["sh", "/app/scripts/headless.sh"]
CMD ["--seed", "1", "--night", "1", "--ticks", "600", "--out", "/app/out/out.jsonl"]
