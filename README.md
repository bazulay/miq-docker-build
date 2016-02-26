# miq-docker-build

docker build -t miq .

docker run  --privileged -dt -v /sys/fs/cgroup:/sys/fs/cgroup:ro miq
