#!/bin/bash
# 启动 AI 音乐学园后端（脱离 shell 控制）
cd "$(dirname "$0")/server" || exit 1
exec python app/main.py