serviceType=

test: 
	# waitting for the service started.
	@echo "Wait for 20 seconds."
	sh ./test.sh
	@echo

createService createSvc applyService applySvc: createPod deleteService
	@echo "Creating Service: Wait for 20 seconds."
	sh ./kubenets/examples/service/service.sh "apply" service $(shell pwd)
	@echo

deleteService deleteSvc: deletePod
	@echo "Deleting service."
	-sh ./kubenets/examples/service/service.sh "delete" $(shell pwd)
	@echo

createPod applyPod: deletePod
	@echo "Creating pod: Wait for 20 seconds."
	sh ./kubenets/examples/pod/pod.sh "apply" $(shell pwd)
	@echo

deletePod:
	@echo "Deleting pod."
	-sh ./kubenets/examples/pod/pod.sh "delete" $(shell pwd)
	@echo


.PHONY: clean test createPod applyPod deletePod \
createService createSvc applyService applySvc deleteService deleteSvc

clean:
	-rm aaa
	# remove all the example deploymented.