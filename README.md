# miq-docker-build

docker build -t miq-devel .

docker run --privileged -di -p 3000:3000 -p 4000:4000 miq-devel
