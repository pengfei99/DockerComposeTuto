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