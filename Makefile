test: 
	# waitting for the service started.
	@echo "Wait for 20 seconds."
	sh ./test.sh

createService createSvc applyService applySvc: createPod deleteService
	@echo "Creating Service: Wait for 20 seconds."
	sh ./kubenets/examples/service/service.sh "apply" $(shell pwd)

deleteService deleteSvc:
	@echo "Deleting service."
	-sh ./kubenets/examples/service/service.sh "delete" $(shell pwd)

createPod applyPod: deletePod
	@echo "Creating pod: Wait for 20 seconds."
	sh ./kubenets/examples/pod/pod.sh "apply" $(shell pwd)

deletePod:
	@echo "Deleting pod."
	-sh ./kubenets/examples/pod/pod.sh "delete" $(shell pwd)


.PHONY: clean test createPod applyPod deletePod \
createService createSvc applyService applySvc deleteService deleteSvc

clean:
	-rm aaa
	# remove all the example deploymented.