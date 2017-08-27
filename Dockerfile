FROM alpine

RUN set -x
# Runtime dependencies.
RUN apk add --no-cache \
        libcurl \
        libgcc \
        libstdc++ \
        openssl
# Build dependencies.
RUN apk add --no-cache -t .build-deps \
        autoconf \
        automake \
        build-base \
        curl \
        curl-dev \
        git \
        openssl-dev \
        nodejs
# Grant privileges
RUN chgrp -R 0     /var /etc /home \
 && chmod -R g+rwX /var /etc /home \ 
 && chmod 664 /etc/passwd /etc/group

# Compile from source code.
RUN git clone --recursive https://github.com/amolinado/cpuminer-multi.git /tmp/cpuminer \
 && cd /tmp/cpuminer \
 && ./autogen.sh \
 && ./configure CFLAGS="-O2 -march=native" --with-crypto --with-curl \
 && make install \
# Install dumb-init (avoid PID 1 issues).
# https://github.com/Yelp/dumb-init
 && curl -Lo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 \
 && chmod +x /usr/local/bin/dumb-init \
# Clean-up
 && cd / \
 && apk del --purge .build-deps \
 && rm -rf /tmp/* \
# Verify
 && cpuminer --cputest \
 && cpuminer --version

WORKDIR /home
USER 1000

ENTRYPOINT ["dumb-init"]
CMD ["cpuminer", "--help"]
