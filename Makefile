test: 
	sh ./test.sh

.PHONY: clean test
clean:
	-rm aaa
	# remove all the example deployments.