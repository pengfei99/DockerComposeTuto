# DockerComposeTuto

In this tuto we will learn how to use docker compose to deploy a flask web app.

## 1. Prerequisites

We suppose you already have a docker engine and docker compose installed. If not, please follow this [doc](docs/01.Instalation.md) 

## 2. Build your web app

Create a file called `apps/app.py` in your project directory and paste this in:

```python

import redis
from flask import Flask

app = Flask(__name__)
# redis is the hostname of the redis container on the application’s network. We use the default port for Redis, 6379.
# in a realworld, you need to put a valid url for host parameter
cache = redis.Redis(host='redis', port=6379)


def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)


@app.route('/')
def hello():
    count = get_hit_count()
    return 'Hello World! This is a docker compose tuto. I have been seen {} times.\n'.format(count)
```

Create another file called **requirements.txt** in your project directory and paste this in:

```text
flask
redis
```

## 3: Create a Dockerfile

In this step, you write a Dockerfile that builds a Docker image. The image contains all the dependencies the Python 
application requires, including Python itself.

```dockerfile
# syntax=docker/dockerfile:1

# set base image
FROM python:3.8-alpine

#Set the working directory to /code.
WORKDIR /code

# Set env var
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

# install system dependencies
RUN apk add --no-cache gcc musl-dev linux-headers

# copy and install project dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Add metadata to the image to describe that the container is listening on port 5000
EXPOSE 5000

# Copy the apps/app.py to the workdir . in the image.
COPY ./apps/app.py .

# Set the default command for the container to flask run.
CMD ["flask", "run"]
```

## 4. Define services in a Compose file

Create a file called docker-compose.yml in your project directory and paste the following:

```yaml
services:
  web:
    build: .
    ports:
      - "8000:5000"
  redis:
    image: "redis:alpine"
```

You can notice that this `Compose file` defines two services: 
- web: The web service uses an image that’s built from the Dockerfile in the current directory. It then binds the 
       container and the host machine to the exposed port, 8000. This example service uses the default port for 
       the Flask web server, 5000.

- redis: The redis service uses a public Redis image pulled from the Docker Hub registry.


## 5. Build and run your app with Compose

Note the docker-compose.yaml must be at the same folder where you can below command
```shell
# run your services with below command
docker compose up
```

The compose command will build first an image from the dockerfile that we defined before, and it pulls a Redis image. 
Then it starts the services you defined in the `docker-compose.yaml` . In this case, the code is statically copied 
into the image at build time.

Enter http://localhost:8000/ in a browser to see the application running.

You can also check the image created by the docker compose

```shell
docker image ls

REPOSITORY                       TAG            IMAGE ID       CREATED          SIZE
dockercomposetuto_web            latest         b6ea8c3e78b5   26 minutes ago   183MB
redis                            alpine         c3ea2db12504   13 hours ago     28.4MB

```
## 6. Edit the Compose file to add a bind mount

Edit docker-compose.yml in your project directory to add a bind mount for the web service:

```yaml
services:
  web:
    build: .
    ports:
      - "8000:5000"
    volumes:
      - ./apps:/code
    environment:
      FLASK_ENV: development
  redis:
    image: "redis:alpine"
```

The new volumes key mounts the `./apps` directory (the directory that contains the app.py) on the host to `/code` 
inside the container, allowing you to modify the code on the fly, without having to rebuild the image. The environment 
key sets the `FLASK_ENV` environment variable, which tells flask run to run in development mode and reload the code 
on change. **This mode should only be used in development.**

## 7. Re-build and run the app with Compose

Stop and rerun `docker compose run`
You can modify the return message and check if it's updated on live in the web browser

## 8. Some other useful command

```shell
# the -d flag (for “detached” mode) allows you to run docker compose up on background 
docker compose up -d

# use docker compose ps to see what is currently running
docker compose ps

# you should see below lines
NAME                        COMMAND                  SERVICE             STATUS              PORTS
dockercomposetuto-redis-1   "docker-entrypoint.s…"   redis               running             6379/tcp
dockercomposetuto-web-1     "flask run"              web                 running             0.0.0.0:8000->5000/tcp, :::8000->5000/tcp

```

The docker-compose run command allows you to run one-off commands for your services. For example, to see what 
environment variables are available in the web service container

```shell
docker compose run web env
```

If you started Compose with docker-compose up -d, stop your services once you’ve finished with them:

```shell
docker compose stop

[+] Running 3/3
 ⠿ Container dockercomposetuto-redis-1               Stopped                                                                                                                                                                                              0.3s
 ⠿ Container dockercomposetuto-web-1                 Stopped                                                                                                                                                                                              0.2s
 ⠿ Container dockercomposetuto_web_run_5785320bb632  Stopped     
```
 
You can bring everything down, removing the containers entirely, with the down command. Pass --volumes to also remove 
the data volume used by the Redis container:

```shell
docker compose down --volumes

[+] Running 4/4
 ⠿ Container dockercomposetuto-web-1                 Removed                         0.0s
 ⠿ Container dockercomposetuto-redis-1               Removed                         0.0s
 ⠿ Container dockercomposetuto_web_run_5785320bb632  Removed                         0.0s
 ⠿ Network dockercomposetuto_default                 Removed                         0.1s
```

At this point, you have seen the basics of how Compose works.