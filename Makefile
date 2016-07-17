.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

# run a plain container
run: certs LETSENCRYPT_EMAIL rundocker

rundocker:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval LETSENCRYPT_EMAIL := $(shell cat LETSENCRYPT_EMAIL))
	$(eval PWD := $(shell pwd))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-v $(PWD)/certs:/certs \
	-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
	-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
	-e REGISTRY_HTTP_TLS_LETSENCRYPT_CACHEFILE=/certs/letsencrypt.cache \
	-e REGISTRY_HTTP_TLS_LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL) \
	-d \
	-p 5000:5000 \
	--restart=always \
	-t $(TAG)

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

certs:
	mkdir -p certs

LETSENCRYPT_EMAIL:
	@while [ -z "$$LETSENCRYPT_EMAIL" ]; do \
		read -r -p "Enter the email you wish to associate with this domain [LETSENCRYPT_EMAIL]: " LETSENCRYPT_EMAIL; echo "$$LETSENCRYPT_EMAIL">>LETSENCRYPT_EMAIL; cat LETSENCRYPT_EMAIL; \
	done ;

