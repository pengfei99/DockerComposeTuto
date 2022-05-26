import time

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
