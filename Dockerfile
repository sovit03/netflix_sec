FROM ubuntu:22.04
LABEL maintainer="Netflix Open Source Development <talent@netflix.com>"

ENV SECURITY_MONKEY_VERSION=v1.1.3 \
    SECURITY_MONKEY_SETTINGS=/usr/local/src/security_monkey/env-config/config-docker.py

SHELL ["/bin/bash", "-c"]
WORKDIR /usr/local/src/security_monkey

COPY requirements.txt /usr/local/src/security_monkey/

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Install Python 3.7 and dependencies
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
        python3.8 \
        python3.8-dev \
        libssl-dev \
        python3.8-distutils \
        python3.8-venv \
        wget \
        postgresql \
        postgresql-contrib \
        libpq-dev \
        libffi-dev \
        libxml2-dev \
        libxslt1-dev \
        libxmlsec1-dev \
        zlib1g-dev \
        build-essential \
        pkg-config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade pip and setuptools for Python 3.7
RUN python3.8 -m ensurepip  && \
    python3.8 -m pip install --upgrade pip==23.3.1 setuptools wheel

# Remove any conflicting system cffi and install compatible cffi version
RUN apt-get remove -y python3-cffi || true && \
    python3.8 -m pip uninstall -y cffi || true && \
    rm -rf /usr/lib/python3*/dist-packages/_cffi_backend* && \
    python3.8 -m pip install --force-reinstall "cffi==1.15.1"

# Install python packages explicitly with python3.7's pip
RUN python3.8 -m pip install "urllib3[secure]" --upgrade && \
    python3.8 -m pip install google-compute-engine && \
    python3.8 -m pip install cloudaux\[gcp\] && \
    python3.8 -m pip install cloudaux\[openstack\] && \
    python3.8 -m pip install python3-saml && \
    python3.8 -m pip install -r requirements.txt

RUN pip uninstall -y lxml xmlsec && \
    pip install --no-binary :all: lxml xmlsec


COPY . /usr/local/src/security_monkey

# Install the local package with onelogin extra using python3.7
RUN python3.8 -m pip install ."[onelogin]" && \
    mkdir -p /var/log/security_monkey/ && \
    touch /var/log/security_monkey/securitymonkey.log

EXPOSE 5000

CMD ["python3.8", "manage.py", "runserver", "-h", "0.0.0.0", "-p", "5000"]

