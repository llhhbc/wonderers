+++
title = "kuber单机部署"
description = "kuber单机部署"
tags = [
    "kubernetes"
]
date = "2018-07-25T20:00:49+08:00"
categories = [
    "kubernetes",
]
+++

## kuber单机部署

由于在阿里上只有一台，又不准备用minikube，所以单机部署一个

### 安装docker

```sh
  wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.06.0.ce-3.el7.x86_64.rpm
  yum install docker-ce-18.06.0.ce-3.el7.x86_64.rpm
```

### 安装etcd

* 生成根证书

```json
{
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "O": "wonder",
      "OU": "wonder Security",
      "L": "Sh",
      "ST": "Sh",
      "C": "CN"
    }
  ],
  "CN": "wonder-root-ca"
}
```

#### 自动化脚本配置如下

```sh
#!/bin/zsh

. ./config/env

function set_path(){
  for IP in $MASTER;do
    ssh root@$IP 'echo "export PATH=\$PATH:/opt/kubernetes/bin/" >> ~/.bash_profile'
  done
}

function set_hosts(){
  ##set hosts
  for IP in $MASTER $NODE;do
    scp ./config/hosts root@$IP:
    ssh root@$IP 'cat hosts > /etc/hosts'
  done
}

## generate root ca
function generate_root_ca(){
mkdir keys
echo '{
    "CN": "VAR_CN",
    "hosts": [
        VAR_HOSTS
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Sh",
            "L": "Sh",
            "O": "wonder",
            "OU": "wonder Security"
        }
    ]
}' > keys/cfg_csr.json_tpl

echo '{
  "signing": {
    "default": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "87600h"
    }
  }
}' > keys/gen_cfg.json

sed 's/VAR_CN/wonder-root-ca/g;s/VAR_HOSTS//g' keys/cfg_csr.json_tpl > keys/root_csr.json

cfssl gencert --initca=true keys/root_csr.json | cfssljson -bare keys/wonder-root-ca
}

## generate etcd ca
function generate_etcd_ca(){

sed 's/VAR_CN/etcd-ca/g;s/VAR_HOSTS/'$ENV_HOSTS'/g' keys/cfg_csr.json_tpl > keys/etcd_csr.json

cfssl gencert -ca keys/wonder-root-ca.pem -ca-key keys/wonder-root-ca-key.pem -config keys/gen_cfg.json  keys/etcd_csr.json | cfssljson -bare keys/etcd


}

function install_etcd_key(){

for IP in $ETCD;do
  ssh root@$IP mkdir -p /etc/etcd/ssl
  scp keys/{wonder*.pem,etcd*.pem} root@$IP:/etc/etcd/ssl/
  ssh root@$IP chown -R etcd:etcd /etc/etcd/ssl
done

}

function config_etcd(){
  for IP in $ETCD;do
    ip=`grep $IP.wonder config/hosts | awk '{print $1}'`
    sed 's/LOCAL/'$ip'/g' config/etcd.conf_tpl > /tmp/etcd.conf1
    sed 's/LNAME/etcd'$IP'/g' /tmp/etcd.conf1 > /tmp/etcd.conf

    scp /tmp/etcd.conf root@$IP:/etc/etcd/

    scp config/etcd.service root@$IP:/usr/lib/systemd/system/
    ssh root@$IP 'chown -R etcd:etcd /etc/etcd/;
 chown -R etcd:etcd /var/lib/etcd;
 systemctl daemon-reload;
 systemctl restart etcd'

    ##test etcd
    ssh root@$IP '
export ETCDCTL_API=3;
etcdctl --cacert=/etc/etcd/ssl/wonder-root-ca.pem --cert=/etc/etcd/ssl/etcd.pem --key=/etc/etcd/ssl/etcd-key.pem --endpoints=https://ks.wonder:2379 endpoint health
'

  done
}


# set kube
function install_kube() {
  for IP in $MASTER;do
    scp softs/kube_server.tgz root@$IP:
    ssh root@$IP 'mkdir -p /opt/kubernetes/bin/;
tar xzvf kube_server.tgz -C /opt/kubernetes/bin/;
chown root:root /opt/kubernetes/bin/;
chmod +x /opt/kubernetes/bin/*;'
  done

}

#set kube cert, use the same root cert
function generate_kube_cert() {

  k8shosts='"kubernetes", \
 "kubernetes.default", \
 "kubernetes.default.svc", \
 "kubernetes.default.svc.cluster", \
 "kubernetes.default.svc.cluster.local"'


  for ts in kubernetes admin kube-proxy;do
    sed 's/VAR_CN/'${ts}'-ca/g;s/VAR_HOSTS/'$ENV_HOSTS','$k8shosts'/g' keys/cfg_csr.json_tpl > keys/${ts}_csr.json

    cfssl gencert -ca keys/wonder-root-ca.pem -ca-key keys/wonder-root-ca-key.pem -config keys/gen_cfg.json  keys/${ts}_csr.json | cfssljson -bare keys/${ts}

  done

}

function install_kube_cert() {
  for IP in $MASTER $NODE;do
    ssh root@$IP 'mkdir -p /opt/kubernetes/etc/ssl/'
    scp keys/{wonder*.pem,kubernetes*.pem,admin*.pem,kube-proxy*.pem} root@$IP:/opt/kubernetes/etc/ssl/
  done
}

#config kuber master
function config_kube_master() {

##生成token
if [ ! -f keys/token ];then
  export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
  echo $BOOTSTRAP_TOKEN > keys/token
  cat > keys/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
else
  export BOOTSTRAP_TOKEN=`cat keys/token`
fi

#set cfg
for IP in $MASTER;do
  scp config/set_kuber_tpl.sh root@$IP:
  ip=`grep $IP.wonder config/hosts | awk '{print $1}'`
  ssh root@$IP ./set_kuber_tpl.sh https://$ip:6443 $BOOTSTRAP_TOKEN

  sed 's/VAR_LIP/'$ip'/g;' config/apiserver_cfg > /tmp/apiserver

  scp /tmp/apiserver keys/token.csv config/{config,controller-manager,scheduler} root@$IP:$KUBER_HOME/etc/

  scp config/rpm_def/{kube-proxy.service,kube-apiserver.service,kube-scheduler.service,kube-controller-manager.service,kubelet.service}  root@$IP:/usr/lib/systemd/system/

  ssh root@$IP systemctl daemon-reload

done

}

function start_kube_master() {
  for IP in $MASTER;do
    ssh root@$IP 'systemctl start kube-apiserver;
systemctl start kube-controller-manager;
systemctl start kube-scheduler;'

  done
}

function config_kube_node(){
    for IP in $NODE;do
        ip=`grep $IP.wonder config/hosts | awk '{print $10}'`
        sed 's/VAR_LIP/'$ip'/g;s/VAR_LNAME/'$IP'.wonder/g;' config/kubelet_tpl > /tmp/kubelet
        sed 's/VAR_LIP/'$ip'/g;' config/proxy_tpl > /tmp/proxy
        scp /tmp/{kubelet,proxy} root@$IP:$KUBER_HOME/etc/

        #services
        scp config/rpm_def/{kubelet.service,kube-proxy.service} root@$IP:/usr/lib/systemd/system/
        ssh root@$IP systemctl daemon-reload
    done
}

function start_kube_node() {
    for IP in $NODE;do

        if [[ ! $IP =~ $MASTER ]];then
            cp config/config_node  /tmp/config
            scp /tmp/config root@$IP:$KUBER_MASTER/etc/
        fi

        ssh root@$IP 'systemctl start kubelet; systemctl start kube-proxy;'
    done
}

$1

```