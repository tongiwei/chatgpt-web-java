#!/bin/sh

# 检查操作系统是否为 Windows
if [ "$(uname)" = "MINGW64_NT-10.0" ]; then
  # 使用 Git Bash 时，将路径转换为 Windows 路径
  project_path="$(pwd -W)"
else
  project_path="$(pwd)"
fi

# 打包前端项目
cd "$project_path/chatgpt-web-2.10.9"
# 运行前提是已经安装node 和 pnpm , docker 和docker-compose
if [ -d "./dist" ]; then
  rm -rf "./dist"
fi
pnpm install
pnpm build
# 复制打包好的dist到后端工程
# 判断操作系统类型
if [ "$(uname)" == "Darwin" ]; then
  OS="Mac"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  OS="Linux"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
  OS="Win"
else
  echo "Unsupported operating system."
  exit 1
fi

if [ $OS == "Win" ]; then
  rd /s /q ..\chatgpt-bootstrap\src\main\resources\static\
  xcopy /e dist ..\chatgpt-bootstrap\src\main\resources\static
else
  rm -rf ../chatgpt-bootstrap/src/main/resources/static/
  cp -r dist ../chatgpt-bootstrap/src/main/resources/static
fi

cd ..

# 打包后端和数据库
# DB 可以只运行一次
docker rm -f chatgpt-db
docker rmi chatgpt-db
docker build -f Dockerfile_mysql -t chatgpt-db .

docker rm -f chatgpt-java
docker rmi chatgpt-java
docker build -t chatgpt-java .

# 一键docker-compose 运行, 运行前请修改docker-compose 参数,修改API-KEY等等
docker-compose up -d