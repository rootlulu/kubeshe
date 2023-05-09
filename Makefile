ns=default

# todo: the dependcies.
get getAll:
	@echo "get all ns, pod, svc, deploy, job and so on"
	-@kubectl get ns,pod,svc,deploy,job -n $(ns)
	@echo

test: 
	# waitting for the service started.
	@echo "Wait for 20 seconds."
	sh ./test.sh
	@echo

createSts createStatefulSet applySts applyStatefulSet: deleteService
	@echo "Creating Deploy: Wait for 20 seconds."
	sh ./kubenets/examples/statefulset/statefulSet.sh "apply" $(shell pwd)
	@

deleteSts deleteStatefulSet: deleteService
	@echo "Deleting deployment."
	sh ./kubenets/examples/statefulset/statefulSet.sh "delete"  $(shell pwd)
	@

createDeploy createDeployment applyDeploy applyDeployment: deleteService
	@echo "Creating Deploy: Wait for 20 seconds."
	sh ./kubenets/examples/deployment/deployment.sh "apply" $(shell pwd)
	@

deleteDeploy deleteDeployment: deleteService
	@echo "Deleting deployment."
	sh ./kubenets/examples/deployment/deployment.sh "delete"  $(shell pwd)
	@

createService createSvc applyService applySvc: createPod deleteService
	@echo "Creating Service: Wait for 20 seconds."
	sh ./kubenets/examples/service/service.sh "apply" $(shell pwd)
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


.PHONY: clean test \
get getAll \
createPod applyPod deletePod \
createService createSvc applyService applySvc deleteService deleteSvc

clean:
	-rm aaa
	# remove all the example deploymented. it wont be done until the all the above finished.