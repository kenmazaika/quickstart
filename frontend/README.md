# Metropolis
## Quickstart Backend

### Setup

The following command will build the docker image for this project.  Replace `kenmazaika` with your handle.

**Build** the docker image, with:

```
docker build . -t kenmazaika/metropolis-quickstart-frontend:latest
```

**Run** the docker image, with:

```
docker run -p 8082:80 kenmazaika/metropolis-quickstart-frontend:latest
```

**Shell** into the docker image, with:

```
docker run -ti kenmazaika/metropolis-quickstart-frontend /bin/sh
cd /usr/share/nginx/html
```

**Push** to GCR.io, with:

```
docker tag kenmazaika/metropolis-quickstart-frontend:latest gcr.io/hello-metropolis/metropolis-quickstart/frontend:latest
docker push gcr.io/hello-metropolis/metropolis-quickstart/frontend:latest
```
