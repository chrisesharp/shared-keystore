SERVICE=keystore
CHART = chart/$(SERVICE)

all: docker deploy

.PHONY: docker
docker:
	docker build -t chrisesharp/keygen .

.PHONY: install
install:
	helm dependency build $(CHART)
	helm upgrade --wait --install $(SERVICE) $(CHART)
	
.PHONY: remove
remove:
	helm delete --purge $(SERVICE)