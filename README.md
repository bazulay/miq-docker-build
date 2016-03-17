# miq-docker-build

## build locally

docker build -t miq-docker-build .

docker run --privileged -di -p 3000:3000 -p 4000:4000 miq-docker-build

## use latest from docker hub

docker pull bazulay/miq-docker-build

docker run --privileged -di -p 3000:3000 -p 4000:4000 docker.io/bazulay/miq-docker-build
