SERVICE=keystore
CHART = chart/$(SERVICE)

all: docker deploy

.PHONY: docker
docker:
	docker build -t chrisesharp/keygen .

.PHONY: deploy
deploy:
	helm dependency build $(CHART)
	helm upgrade --wait --install $(SERVICE) $(CHART)
	
.PHONY: clean
clean:
	helm delete --purge $(SERVICE)
	
.PHONY: remove
remove:
	helm delete --purge login $(SERVICE)