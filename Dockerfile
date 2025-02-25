# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.10.9
FROM python:${PYTHON_VERSION}-slim AS base

# Prevents Python from writing pyc files.
# -> host will create bytecode when the source file runs -> may take some time to "warm-up"
# -> better to add this step in the Dockerfile to avoid creating bytecode in the host
# ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser


# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install -r requirements.txt

# Switch to the non-privileged user to run the application.
USER appuser

# Copy the source code into the container.
COPY . .

# Run the application.
# CMD python -m uvicorn test:test --host=0.0.0.0 --port=8000
# "$docker run -it image_name" will run the command below and wait for the user to type in the terminal
# "exec bash" added to enable interaction with "-it"
# CMD ["bash", "-c", "python test.py && exec bash"] # CMD can be overwritten
ENTRYPOINT ["bash", "-c", "python test.py && exec bash"] # ENTRY cannot be overwritten
