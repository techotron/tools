#docker rmi $(docker images -f "dangling=true" -q)
docker build -t github-tools:latest .