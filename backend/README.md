# Metropolis
## Quickstart Backend

### Interacting with the API

This project contains an extremely simple API endpoint that is used for testing and interacting with the project.  Documentation of the API endpoints that this project exposes is below.

Replace `localhost:4857` with the host the API is running.

**`index`** – list all of the tweets in the database.

```
curl "http://localhost:4857/api/tweets"
```

**`create`** – create a new tweet in the database.

```
curl -H "Content-Type: application/json" \
 --request POST \
 --data '{ "tweet": {"author": "@kenmazaika","content":"hello world" } }' \
 "http://localhost:4857/api/tweets"
```

**`show`** – show the contents of a tweet.

```
curl "http://localhost:4857/api/tweets/1"
```

**`update`** – update the value of a tweet.


```
curl -H "Content-Type: application/json" \
 --request PATCH \
 --data '{ "tweet": {"author": "@kenmazaika","content":"hello world2" } }' \
 "http://localhost:4857/api/tweets/1"
```

**`destroy`** – delete a tweet from the database

```
curl --request DELETE "http://localhost:4857/api/tweets/1"
```


### Setup

The following command will build the docker image for this project.  Replace `kenmazaika` with your handle.

**Build** the docker image, with:

```
docker build . -t kenmazaika/metropolis-quickstart-backend:latest
```

**Run** the docker image, with:

```
docker run -p 8081:8081 kenmazaika/metropolis-quickstart-backend:latest
```

**Shell** into the docker image, with:

```
docker run -ti kenmazaika/metropolis-quickstart-backend /bin/bash
```

**Push** to GCR.io, with:

```
docker tag kenmazaika/metropolis-quickstart-backend:latest gcr.io/hello-metropolis/metropolis-quickstart/backend:latest
docker push gcr.io/hello-metropolis/metropolis-quickstart/backend:latest
```
