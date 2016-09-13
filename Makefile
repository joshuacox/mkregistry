.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

run: HOSTNAME IP USERNAME PASSWORD SECRET DATADIR htpasswd PORT SSL_PORT LETSENCRYPT_EMAIL rm rundocker

rundocker:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval HOSTNAME := $(shell cat HOSTNAME))
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval SSL_PORT := $(shell cat SSL_PORT))
	$(eval PASSWORD := $(shell cat PASSWORD))
	$(eval SECRET := $(shell cat SECRET))
	$(eval LETSENCRYPT_EMAIL := $(shell cat LETSENCRYPT_EMAIL))
	$(eval PWD := $(shell pwd))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-v $(DATADIR)/certs:/certs \
	-v $(DATADIR)/auth:/auth \
	-v $(DATADIR)/data:/var/lib/registry \
	-e "REGISTRY_AUTH=htpasswd" \
	-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
	-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
	-e REGISTRY_HTTP_ADDR=$(HOSTNAME):$(SSL_PORT) \
	-e REGISTRY_HTTP_NET=tcp \
	-e REGISTRY_HTTP_HOST=https://$(HOSTNAME):$(SSL_PORT) \
	-e REGISTRY_HTTP_SECRET=$(SECRET) \
	-e REGISTRY_HTTP_TLS_LETSENCRYPT_CACHEFILE=/certs/letsencrypt.cache \
	-e REGISTRY_HTTP_TLS_LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL) \
	-d \
	-p $(IP):$(PORT):5000 \
	-p $(IP):$(SSL_PORT):443 \
	--restart=always \
	-t $(TAG)

insecure:  SECRET DATADIR PORT rm  insecuredocker

insecuredocker:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval IP := $(shell cat IP))
	$(eval TAG := $(shell cat TAG))
	$(eval PORT := $(shell cat PORT))
	$(eval SECRET := $(shell cat SECRET))
	$(eval PWD := $(shell pwd))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(DATADIR)/data:/var/lib/registry \
	-e REGISTRY_HTTP_SECRET=$(SECRET) \
	-d \
	-p $(IP):$(PORT):5000 \
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
		mkdir -p $$DATADIR/auth ; chown -R 1000:1000 $$DATADIR/auth ; \
		mkdir -p $$DATADIR/data ; chown -R 1000:1000 $$DATADIR/data ; \
	done ;

HOSTNAME:
	@while [ -z "$$HOSTNAME" ]; do \
		read -r -p "Enter the hostname you wish to associate with this container [HOSTNAME]: " HOSTNAME; echo "$$HOSTNAME">>HOSTNAME; cat HOSTNAME; \
	done ;

USERNAME:
	@while [ -z "$$USERNAME" ]; do \
		read -r -p "Enter the user you wish to associate with this container [USERNAME]: " USERNAME; echo "$$USERNAME">>USERNAME; cat USERNAME; \
	done ;

PASSWORD:
	@while [ -z "$$PASSWORD" ]; do \
		read -r -p "Enter the password you wish to associate with this container [PASSWORD]: " PASSWORD; echo "$$PASSWORD">>PASSWORD; cat PASSWORD; \
	done ;

PORT:
	@while [ -z "$$PORT" ]; do \
		read -r -p "Enter the external port you wish to associate with this container [PORT]: " PORT; echo "$$PORT">>PORT; cat PORT; \
	done ;

SSL_PORT:
	@while [ -z "$$SSL_PORT" ]; do \
		read -r -p "Enter the external ssl port you wish to associate with this container [SSL_PORT]: " SSL_PORT; echo "$$SSL_PORT">>SSL_PORT; cat SSL_PORT; \
	done ;

example:
	$(eval PASSWORD := $(shell tr -cd '[:alnum:]' < /dev/urandom | fold -w42 | head -n1 ))
	-@echo $(PASSWORD) > PASSWORD

SECRET:
	$(eval SECRET := $(shell tr -cd '[:alnum:]' < /dev/urandom | fold -w64 | head -n1 ))
	-@echo $(SECRET) > SECRET

htpasswd: USERNAME PASSWORD DATADIR
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval USERNAME := $(shell cat USERNAME))
	$(eval PASSWORD := $(shell cat PASSWORD))
	docker run --entrypoint htpasswd registry:2 -Bbn $(USERNAME) $(PASSWORD) > htpasswd
	cp htpasswd $(DATADIR)/auth/htpasswd

IP:
	curl icanhazip.com > IP
