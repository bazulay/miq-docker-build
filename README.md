# ManageIQ Devel Docker Build

This image provides ManageIQ using the official Centos7 dockerhub build as a base along with PostgreSQL.

## Build

The build tracks the GIT master branch of ManageIQ. A typical build takes around 15 mins to complete.

```
docker build -t miq-docker-build .
```

It has been tested and validated under docker-1.10 (Fedora23) and 1.8.2 (Centos7)

## Run
The first time you run the container, it will initialize the database, **please allow 2-4 mins** for MIQ to respond. 
```
docker run --privileged -di -p 3000:3000 -p 4000:4000 miq-docker-build
```

## Pull and use latest image from Docker Hub
```
docker pull bazulay/miq-docker-build

docker run --privileged -di -p 3000:3000 -p 4000:4000 docker.io/bazulay/miq-docker-build
```

## Access
The web interface is exposed at port 3000. Default login credentials. 

Point your web browser to : 

```
http://<your-ip-address>:3000
```

For console access, please use docker exec from docker host : 
```
docker exec -ti <container-id> bash -l
```
