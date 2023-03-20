test: 
	# waitting for the service started.
	@echo "Wait for 20 seconds."
	sh ./test.sh

createPod applyPod:
	@echo "Creating pod: Wait for 20 seconds."
	sh ./kubenets/examples/pod/pod.sh "apply" $(shell pwd)

deletePod:
	@echo "Deleting pod: Wait for 20 seconds."
	sh ./kubenets/examples/pod/pod.sh "delete" $(shell pwd)


.PHONY: clean test pod
clean:
	-rm aaa
	# remove all the example deploymented.