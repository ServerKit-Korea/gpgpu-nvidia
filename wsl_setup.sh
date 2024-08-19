#!/bin/bash

# 관리자 권한 확인 (root 권한 확인)
if [ "$EUID" -ne 0 ]; then
  echo "This script needs to be run as root. Please run with sudo."
  exit
fi

# 비밀번호 캐싱을 위한 sudo -v 실행 (sudo 사용을 위한 비밀번호 캐싱)
sudo -v

# 잘못된 레포지토리 파일 삭제
sudo -S rm -f /etc/apt/sources.list.d/nvidia-docker.list

# GPG 키 추가 및 레포지토리 설정
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo -S gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo -S tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# 패키지 리스트 업데이트 및 설치
sudo -S apt-get update && \
sudo -S apt-get install -y nvidia-container-toolkit

# Docker 서비스 재시작
sudo -S systemctl restart docker

# 필요한 디렉토리 생성
sudo -S mkdir -p /mnt/c/ProgramData/Docker/config

# 기존 파일이 있으면 병합
if [ -f "$DAEMON_JSON_PATH" ]; then
  echo "Merging with existing daemon.json..."
  sudo -S jq '.runtimes.nvidia = {"path":"nvidia-container-runtime","runtimeArgs":[]}' $DAEMON_JSON_PATH | \
  sudo -S tee $DAEMON_JSON_PATH > /dev/null
else
    # 데몬 설정이 존재하지 않을 경우 파일 생성 및 내용 새로 생성
    echo "Creating new daemon.json..."
    DOCKER_DAEMON_CONFIG='{
        "runtimes": {
            "nvidia": {
                "path": "nvidia-container-runtime",
                "runtimeArgs": []
            }
        }
    }'
    echo "$DOCKER_DAEMON_CONFIG" | sudo -S tee $DAEMON_JSON_PATH > /dev/null
fi
echo "Docker daemon configuration has been set successfully."

# 설치 확인
nvidia-container-cli info
