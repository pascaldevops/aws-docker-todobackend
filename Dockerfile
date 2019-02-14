# 
# Test stage
#

# choose a release image and a name for the release
FROM alpine AS test
LABEL application=todobackend

# 
# Installing system dependencies and build dependencies
#

# Installing basic utilities
RUN apk add --no-cache bash git

# Install build dependencies
RUN apk add --no-cache gcc python3-dev libffi-dev musl-dev linux-headers mariadb-dev
RUN pip3 install wheel

#
# Installing Application Dependencies
#

# Copy requirements
COPY /src/requirements* /build/
WORKDIR /build

# Build add install requirements
RUN pip3 wheel -r requirements_test.txt --no-cache-dir --no-input
RUN pip3 install -r requirements_test.txt -f /build --no-index --no-cache-dir

#
# Copying Application Source and Running Tests
#

# Copy source code
COPY /src /app
WORKDIR /app

# Test entrypoint
CMD ["python3", "manage.py", "test", "--noinput", "--settings=todobackend.settings_test"]

# 
# Release stage
#

# choose a release image and a name for the release
FROM alpine 
LABEL application=todobackend


# Install operating system dependencies
RUN apk add --no-cache python3 mariadb-client bash

# Creating an Application User
# The user the application will run as
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app

# Copying the application source code and dependencies
COPY --from=test --chown=app:app /build /build
COPY --from=test --chown=app:app /app /app
RUN pip3 install -r /build/requirements.txt -f /build --no-index --no-cache-dir
RUN rm -rf /Build

# Set working directory and application user
WORKDIR /app
USER app