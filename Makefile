.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

run: HOSTNAME PASSWORD DATADIR PORT LETSENCRYPT_EMAIL rundocker

rundocker:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval HOSTNAME := $(shell cat HOSTNAME))
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval TAG := $(shell cat TAG))
	$(eval PORT := $(shell cat PORT))
	$(eval PASSWORD := $(shell cat PASSWORD))
	$(eval LETSENCRYPT_EMAIL := $(shell cat LETSENCRYPT_EMAIL))
	$(eval PWD := $(shell pwd))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-v $(DATADIR)/certs:/certs \
	-e REGISTRY_HTTP_ADDR=:$(PORT) \
	-e REGISTRY_HTTP_NET=tcp \
	-e REGISTRY_HTTP_HOST=https://$(HOSTNAME):$(PORT) \
	-e REGISTRY_HTTP_SECRET=$(PASSWORD) \
	-e REGISTRY_HTTP_TLS_LETSENCRYPT_CACHEFILE=/certs/letsencrypt.cache \
	-e REGISTRY_HTTP_TLS_LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL) \
	-d \
	-p $(PORT):$(PORT) \
	--restart=always \
	-t $(TAG)

notUsed:
	-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
	-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \

kill:
	-@docker kill `cat cid`

rm-image:
	-@docker rm `cat cid`
	-@rm cid

rm: kill rm-image

clean: rm

enter:
	docker exec -i -t `cat cid` /bin/bash

logs:
	docker logs -f `cat cid`

rmall: rm

LETSENCRYPT_EMAIL:
	@while [ -z "$$LETSENCRYPT_EMAIL" ]; do \
		read -r -p "Enter the email you wish to associate with this domain [LETSENCRYPT_EMAIL]: " LETSENCRYPT_EMAIL; echo "$$LETSENCRYPT_EMAIL">>LETSENCRYPT_EMAIL; cat LETSENCRYPT_EMAIL; \
	done ;

DATADIR:
	@while [ -z "$$DATADIR" ]; do \
		read -r -p "Enter the datadir you wish to associate with this container [DATADIR]: " DATADIR ; \
		echo "$$DATADIR">>DATADIR; cat DATADIR; \
		mkdir -p $$DATADIR/certs ; chown -R 1000:1000 $$DATADIR/certs ; \
	done ;

HOSTNAME:
	@while [ -z "$$HOSTNAME" ]; do \
		read -r -p "Enter the hostname you wish to associate with this container [HOSTNAME]: " HOSTNAME; echo "$$HOSTNAME">>HOSTNAME; cat HOSTNAME; \
	done ;

PASSWORD:
	@while [ -z "$$PASSWORD" ]; do \
		read -r -p "Enter the password you wish to associate with this container [PASSWORD]: " PASSWORD; echo "$$PASSWORD">>PASSWORD; cat PASSWORD; \
	done ;

PORT:
	@while [ -z "$$PORT" ]; do \
		read -r -p "Enter the external port you wish to associate with this container [PORT]: " PORT; echo "$$PORT">>PORT; cat PORT; \
	done ;

example:
	$(eval PASSWORD := $(shell tr -cd '[:alnum:]' < /dev/urandom | fold -w42 | head -n1 ))
	-@echo $(PASSWORD) > PASSWORD
