
# The kubeshe that one click install kubernets with shell script in Centos7

> the steps( installing at the master but not salves.):
1. process the input. which is the common func.
2. common utils installing.
3. master installing.
4. nodes installing in a loop from master with ssh.
5. extract the trans to a lib func.

## 1. 一键安装部署k8s，并且有相关的k8s例子。注意以下几点，以确保部署可以成功
1. 所有机器的用户名密码需要一致
2. master的host_name为k8s-master，worker的host_name为k8s-node1,k8s-node2, ...
3. 内核必须是最新版本， 3.16.12

## 2. k8s例子包含以下：
1. pod
2. deployment
3. job
4. daemonset
5. service
7. ingress
8. 静态pv
9. 动态pv
