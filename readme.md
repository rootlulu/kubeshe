

# The kubeshe that one click install kubernets with shell script

##
setup.sh: 参数校验，help参数，工具函数，yum源设置等
pre.sh：yum工具安装，配置免密登陆，传输文件等
install.sh： 正式安装流程：配置机器环境等
post.sh：  收尾工作 如test等

## tips

1. 机器的密码需要一直

## todo

1. 引入python。支持配置文件
2. 免密登陆的密码可以不一致，在配置文件中配置或通过密钥配置