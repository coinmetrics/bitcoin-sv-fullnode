FROM ubuntu:18.04 as builder

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bsdmainutils \
		build-essential \
		ca-certificates \
		git \
		libboost-all-dev \
		libevent-dev \
		libssl-dev \
		libtool \
		pkg-config \
	; \
	rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash builder
USER builder
WORKDIR /home/builder

ARG VERSION

RUN git clone --depth=1 --branch=v${VERSION} https://github.com/bitcoin-sv/bitcoin-sv.git

COPY fix_json.patch /home/builder/fix_json.patch

RUN set -ex; \
	cd bitcoin-sv; \
	patch -p1 < /home/builder/fix_json.patch; \
	./autogen.sh; \
	./configure --prefix=/home/builder/prefix --disable-shared --disable-wallet --disable-bench --disable-tests; \
	make -j$(nproc); \
	make install


FROM ubuntu:18.04

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		libboost-chrono1.65.1 \
		libboost-filesystem1.65.1 \
		libboost-program-options1.65.1 \
		libboost-system1.65.1 \
		libboost-thread1.65.1 \
		libevent-2.1 \
		libevent-pthreads-2.1 \
	; \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /home/builder/prefix/bin/bitcoind /usr/bin/

RUN useradd -m -u 1000 -s /bin/bash runner
USER runner

ENTRYPOINT ["bitcoind"]
