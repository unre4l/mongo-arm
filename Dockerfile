FROM resin/rpi-raspbian

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get update

RUN apt-get install wget
RUN wget -O libnuma.deb "http://mirrordirector.raspbian.org/raspbian/pool/main/n/numactl/libnuma1_2.0.12-1_armhf.deb" && dpkg -i libnuma.deb
RUN wget -O numactl.deb "http://mirrordirector.raspbian.org/raspbian/pool/main/n/numactl/numactl_2.0.12-1_armhf.deb" && dpkg -i numactl.deb

RUN apt-get install -y --no-install-recommends \
		ca-certificates \
		gnupg dirmngr \
		jq \
		numactl \
		procps 
RUN rm -rf /var/lib/apt/lists/*


# Allow build-time overrides (eg. to build image with MongoDB Enterprise version)
# Options for MONGO_PACKAGE: mongodb-org OR mongodb-enterprise
# Options for MONGO_REPO: repo.mongodb.org OR repo.mongodb.com
# Example: docker build --build-arg MONGO_PACKAGE=mongodb-enterprise --build-arg MONGO_REPO=repo.mongodb.com .
ARG MONGO_PACKAGE=mongodb-org
ARG MONGO_REPO=repo.mongodb.org
ENV MONGO_PACKAGE=${MONGO_PACKAGE} MONGO_REPO=${MONGO_REPO}

ENV MONGO_MAJOR 3.6
ENV MONGO_VERSION 3.6.8

RUN echo "deb http://$MONGO_REPO/apt/debian stretch/${MONGO_PACKAGE%-unstable}/$MONGO_MAJOR main" | tee "/etc/apt/sources.list.d/${MONGO_PACKAGE%-unstable}.list"

RUN set -x \
	&& apt-get update \
	&& apt-get install -y apt-transport-https \
		${MONGO_PACKAGE}=$MONGO_VERSION \
		${MONGO_PACKAGE}-server=$MONGO_VERSION \
		${MONGO_PACKAGE}-shell=$MONGO_VERSION \
		${MONGO_PACKAGE}-mongos=$MONGO_VERSION \
		${MONGO_PACKAGE}-tools=$MONGO_VERSION \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb \
	&& mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 27017
CMD ["mongod"]