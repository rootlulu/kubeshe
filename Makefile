test: 
	# waitting for the service started.
	@echo "Wait for 20 seconds."
	sh ./test.sh

pod:
	@echo "Wait for 20 seconds."
	sh ./kubenets/examples/pod/pod.sh

.PHONY: clean test pod
clean:
	-rm aaa
	# remove all the example deployments.