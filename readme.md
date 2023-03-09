
# kubeshe 

## introduce
> one click install kubernets with shell script in Centos7. What you can learned
in this project:
1. the linux shell skill.
2. use expect to run command in a interacting mode, like config the login without password around some machine.
3. the make file knowledge.
4. how to install k8s.
5. the core concept in k8s.
6. example of the k8s's core concept like: pod. deployment, dynamic pv ... 
7. how customization components worked fine with k8s. like: coredns, harbor. 
contained, dashboard and so on.

## usage
### one click install k8s master.
At the root path. run command:
```shell
    ./main.sh --ssh username password --k8s_nodes master_ip:node1_ip:node_2_ip
    # example:
    # your machine username and password is root/root and the k8s cluster is 
    # 1.1.1.1(master) 2.2.2.2 3.3.3.3
    ./main.sh --ssh root root --k8s_nodes 1.1.1.1:2.2.2.2:3.3.3.3
    you can run ./main.sh -h for more information.
```

## done
### one click install k8s cluster.
### add the func to test whether the k8s installed fail or success.
### set the kube-proxy mode to ipvs from iptables



## todo
1. set coredns
2. set harbor as a individual hub.
3. add the visualization user interface.

#  the shell process.
> the process steps( installing at the master but not salves.):
1. process the input. which is the common func.
2. common utils installing.
3. master installing.
4. nodes installing in a loop from master with ssh.
5. extract the trans to a lib func.
6. and then, use the make cmd to install or set some customization.



## Notices
1. all nodes' password must in same.
2. the centos's kernel must be latest:3.16.12
3. only support for single node master.
