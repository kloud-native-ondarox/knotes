<!-- TOC -->

- [Troubleshooting](#troubleshooting)
  - [Connect to API server without KUBECTL Proxy](#connect-to-api-server-without-kubectl-proxy)
  - [Accessing the API from a Pod](#accessing-the-api-from-a-pod)
  - [Querying Stuff](#querying-stuff)
  - [Labels and Selectors](#labels-and-selectors)
  - [port forwarding](#port-forwarding)
  - [logging](#logging)
  - [Events](#events)
  - [Resource Monitoring](#resource-monitoring)
  - [Events & Logs](#events--logs)
  - [Using Jsonpath](#using-jsonpath)
  - [Troubleshooting Node Failures](#troubleshooting-node-failures)
    - [Break Node](#break-node)
  - [Kubernetes Security](#kubernetes-security)
  - [Investigating the PKI setup on the Control Plane Node](#investigating-the-pki-setup-on-the-control-plane-node)
  - [Kubernetes - Create New User Certificate](#kubernetes---create-new-user-certificate)
    - [- Create a RSA private key](#--create-a-rsa-private-key)
    - [- Generate a CSR](#--generate-a-csr)
    - [B/2B - ALTERNATIVE - Create a new private key AND Certificate Signing Request](#b2b---alternative---create-a-new-private-key-and-certificate-signing-request)
    - [- Submit the CertificateSigningRequest to the API Server - K8s 1.19+](#--submit-the-certificatesigningrequest-to-the-api-server---k8s-119)
    - [- Submit the CertificateSigningRequest to the API Server - K8s 1.18](#--submit-the-certificatesigningrequest-to-the-api-server---k8s-118)
    - [- Approve the CSR](#--approve-the-csr)
    - [- Retrieve the certificate from the CSR object, it's base64 encoded](#--retrieve-the-certificate-from-the-csr-object-its-base64-encoded)
    - [COMPLETE ALTERNATIVE A - Create a Self-signed Certificate](#complete-alternative-a---create-a-self-signed-certificate)
    - [MISC ALTERNATIVE B](#misc-alternative-b)
      - [Create a CSR from existing certificate and private key](#create-a-csr-from-existing-certificate-and-private-key)
      - [Generate a CSR for multi-domain SAN certificate by supplying an openssl config file:](#generate-a-csr-for-multi-domain-san-certificate-by-supplying-an-openssl-config-file)
      - [Create X.509 certificates](#create-x509-certificates)
    - [Troubleshooting Certificate Issues](#troubleshooting-certificate-issues)
  - [Capacity Planning](#capacity-planning)

<!-- /TOC -->


# Troubleshooting

## Connect to API server without KUBECTL Proxy

Example Below:

```bash
APISERVER=$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")
SECRET_NAME=$(kubectl get secrets | grep ^default | cut -f1 -d ' ')
TOKEN=$(kubectl describe secret $SECRET_NAME | grep -E '^token' | cut -f2 -d':' | tr -d " ")

curl $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure
```

alternative way of getting cluster info:

APISERVER=$(kubectl config view --minify -ojsonpath='{.clusters[*].cluster.server}')

## Accessing the API from a Pod

APISERVER=kubernetes.default.svc
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/

finding info using go-template:

`kubectl get pod redis-master-765d459796-258hz --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'`

vs. same info in jsonpath:

`kubectl get pod redis-master-6b54579d85-vkhdd -ojsonpath='{.spec.containers[0].ports[0].containerPort}{"\n"}'`

## Querying Stuff

finding info using go-template:

`kubectl get pod redis-master-765d459796-258hz --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'`

vs. same info in jsonpath:

`kubectl get pod redis-master-6b54579d85-vkhdd -ojsonpath='{.spec.containers[0].ports[0].containerPort}{"\n"}'`

using custom-columns

`kubectl get pod multi-cont-pod -o custom-columns=CONTAINER:.spec.containers[0].name,IMAGE:.spec.containers[0].image`

using sort-by

`kubectl get pods --sort-by=.metadata.name`
`kubectl get pods --sort-by=.metadata.creationTimestamp`

using range with  new line

`kubectl get po -l app=try -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}'`

## Labels and Selectors

overwrite label

`kubectl label --overwrite pods nginx2 app=v2`

show labels

`kubectl get pods --show-labels`

get pods based on selector (equality based)

`kubectl get pods --selector=app=v2`
`kubectl get pods -l app=v2`
`kubectl get pods -l 'env in (dev,prod)'`

show label columns, i.e.  app

`kubectl get pods --label-columns=app`
`kubectl get pods -L app`
`kubectl get pods -L app -L tier`

delete labels by appending -

`kubectl label pods nginx1 env-`

set labels on nodes

`kubectl label nodes kubernetes-foo-node-1.c.a-robinson.internal disktype=ssd`


## port forwarding


`kubectl port-forward redis-master-765d459796-258hz 7000:6379`


## logging

`kubectl logs nginx --all-containers=true --prefix=true --since=60m --tail=20 --timestamps=true`

## Events

To monitor events in background

`kubectl get events -w &`

run `fg` and `ctrl-c` to kill process

`kubectl describe po busybox | grep -A 10 Events`

## Resource Monitoring

https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/

make sure metrics server is installed first either via helm - https://github.com/helm/charts/tree/master/stable/metrics-server
or deployment components yaml - https://github.com/kubernetes-sigs/metrics-server

Show metrics of the above pod containers and puts them into the file.log and verify

kubectl -n kube-system get cm kubeadm-config -oyaml

## Events & Logs

It can be easier if the data is actually sorted...sort by isn't for just events, it can be used in most output
`kubectl get events --sort-by='.metadata.creationTimestamp'`

Create a flawed deployment

`kubectl create deployment nginx --image ngins`

Time bounding your searches can be helpful in finding issues add --no-pager for line wrapping
`journalctl -u kubelet.service --since today --no-pager`


We can retrieve the logs for the control plane pods by using kubectl logs. This info is coming from the API server over kubectl, it instructs the kubelet will read the log from the node and send it back to you over stdout

`kubectl logs --namespace kube-system kube-apiserver-c1-master1`


But, what if your control plane is down? Go to docker or to the file system. kubectl logs will send the request to the local node's kubelet to read the logs from disk. Since we're on the master/control plane node already we can use docker for that.

`sudo docker ps`

Grab the log for the api server pod, paste in the CONTAINER ID

```bash
sudo docker ps  | grep k8s_kube-apiserver
CONTAINER_ID=$(sudo docker ps | grep k8s_kube-apiserver | awk '{ print $1 }')
echo $CONTAINER_ID
sudo docker logs $CONTAINER_ID
```
But, what if docker is not available? They're also available on the filesystem, here you'll find the current and the previous logs files for the containers. This is the same across all nodes and pods in the cluster. This also applies to user pods/containers. These are json formmatted which is the docker logging driver default

```bash
sudo ls /var/log/containers
sudo tail /var/log/containers/kube-apiserver-c1-master1*
```


We can filter the list of events using field selector

```bash
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Warning,reason=Failed
```


We're working with the json output of our objects, in this case pods let's start by accessing that list of Pods, inside items. Look at the items, find the metadata and name sections in the json output

`kubectl get pods -l app=hello-world -o json > pods.json`

It's a list of objects, so let's display the pod names
`kubectl get pods -l app=hello-world -o jsonpath='{ .items[*].metadata.name }'`

Display all pods names, this will put the new line at the end of the set rather then on each object output to screen.
Additional tips on formatting code in the examples below including adding a new line after each object

`kubectl get pods -l app=hello-world -o jsonpath='{ .items[*].metadata.name }{"\n"}'`

It's a list of objects, so let's display the first (zero'th) pod from the output

`kubectl get pods -l app=hello-world -o jsonpath='{ .items[0].metadata.name }{"\n"}'`

Get all container images in use by all pods in all namespaces

`kubectl get pods --all-namespaces -o jsonpath='{ .items[*].spec.containers[*].image }{"\n"}'`

We can access all container logs which will dump each containers in sequence

`kubectl logs $PODNAME --all-containers`

If we need to follow a log, we can do that...helpful in debugging real time issues. This works for both single and multi-container pods

`kubectl logs $PODNAME --all-containers --follow`

ctrl+c

Get key information and status about the kubelet, ensure that it's active/running and check out the log. Also key information about it's configuration is available.

`systemctl status kubelet.service`


If we want to examine it's log further, we use journalctl to access it's log from journald -u for which systemd unit. If using a pager, use f and b to for forward and back.

`journalctl -u kubelet.service`

journalctl has search capabilities, but grep is likely easier

`journalctl -u kubelet.service | grep -i ERROR`

Time bounding your searches can be helpful in finding issues add --no-pager for line wrapping

`journalctl -u kubelet.service --since today --no-pager`

Get a listing of the control plane pods using a selector

`kubectl get pods --namespace kube-system --selector tier=control-plane`

## Using Jsonpath

This allows us to explore the json data interactively and keep our final jq query on the clipboard

`kubectl get no -o json | jid -q | pbcopy`


Filtering a specific value in a list
Let's say there's an list inside items and you need to access an element in that list...
?() - defines a filter
@ - the current object

`kubectl get nodes -o jsonpath="{.items[*].status.addresses''[?(@.type=='InternalIP')].address}"`

Get all container images in use by all pods in all namespaces

`kubectl get pods --all-namespaces -o jsonpath='{ .items[*].spec.containers[*].image }{"\n"}'`

Now that we're sorting that output, maybe we want a listing of all pods sorted by a field that's part of the
object but not part of the default kubectl output. like creationTimestamp and we want to see what that value is
We can use a custom colume to output object field data, in this case the creation timestamp

```bash
kubectl get pods -A -o jsonpath='{ .items[*].metadata.name }{"\n"}' \
    --sort-by=.metadata.creationTimestamp \
    --output=custom-columns='NAME:metadata.name,CREATIONTIMESTAMP:metadata.creationTimestamp'

kubectl get po -A -o custom-columns=CREATE:.metadata.creationTimestamp,POD:.metadata.name,CONTAINER:.spec.containers[0].name,IMAGE:.spec.containers[0].image,PODIP:.status.podIP,HOSTIP:.status.hostIP,NS:.metadata.namespace
```

One method to iterate through list

```bash
$ kubectl get pods --all-namespaces -o jsonpath='{ .items[*].spec.containers[*].image }{"\n"}' | tr " " "\n"
httpd:2.4-alpine
httpd:2.4-alpine
nginx:1.17.6-alpine
nginx:1.17.6-alpine
docker.io/calico/kube-controllers:v3.17.0
docker.io/calico/node:v3.17.0
quay.io/coreos/flannel:v0.12.0
docker.io/calico/node:v3.17.0
quay.io/coreos/flannel:v0.12.0
docker.io/calico/node:v3.17.0
quay.io/coreos/flannel:v0.12.0
k8s.gcr.io/coredns:1.7.0
k8s.gcr.io/coredns:1.7.0
k8s.gcr.io/etcd:3.4.13-0
k8s.gcr.io/kube-apiserver:v1.19.4
k8s.gcr.io/kube-controller-manager:v1.19.4
quay.io/coreos/flannel:v0.13.1-rc1
```

All container images across all pods in all namespaces. Range iterates over a list performing the formatting operations on each element in the list. We can also add in a sort on the container image name

`kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}' \
    --sort-by=.spec.containers[*].image`

We can use range again to clean up the output if we want

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="Hostname")].address}{"\n"}{end}'
```

We used --sortby when looking at Events earlier, let's use it for another something else now...
Let's take our container image output from above and sort it

```bash
kubectl get pods -A -o jsonpath='{ .items[*].spec.containers[*].image }' --sort-by=.spec.containers[*].image
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name }{"\t"}{.spec.containers[*].image }{"\n"}{end}' --sort-by=.spec.containers[*].image
```

Adding in a spaces or tabs in the output to make it a bit more readable

```bash
$ kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[*].image}{"\n"}{end}'
web-test-2-594487698d-jphg4 httpd:2.4-alpine
web-test-6c77dcfbc-bqp4b httpd:2.4-alpine
web-test-6c77dcfbc-vbnk7 httpd:2.4-alpine
web-test-6c77dcfbc-wh4x4 httpd:2.4-alpine
```

```bash
kubectl get pods -l app=hello-world -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'
```

```bash
$ kubectl get pod -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}"
web-test-2-594487698d-jphg4
web-test-6c77dcfbc-bqp4b
web-test-6c77dcfbc-vbnk7
web-test-6c77dcfbc-wh4x4
```

## Troubleshooting Node Failures

### Break Node

To use this file to break stuff on your nodes, set the username variable to your username.
This account will need sudo rights on the nodes to break things. You'll need to enter your sudo password for this account on each node for each execution. Execute the commands here one line at a time rather than running the whole script at ones. You can set up passwordless sudo to make this easier otherwise

USER=$1

> Worker Node - stopped kubelet

`ssh $USER@c1-node1 -t 'sudo systemctl stop kubelet.service'

`ssh $USER@c1-node1 -t 'sudo systemctl disable kubelet.service'

> Worker Node - inaccessible config.yaml

`ssh $USER@c1-node2 -t 'sudo mv /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yml'

`ssh $USER@c1-node2 -t 'sudo systemctl restart kubelet.service'

> Worker Node - misconfigured systemd unit

`ssh $USER@c1-node3 -t 'sudo sed -i ''s/config.yaml/config.yml/'' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf'

`ssh $USER@c1-node3 -t 'sudo systemctl daemon-reload'

`ssh $USER@c1-node3 -t 'sudo systemctl restart kubelet.service'

The kubelet runs as a systemd service/unit...so we can use those tools to troubleshoot why it's not working
Let's start by checking the status. Add no-pager so it will wrap the text - It's loaded, but it's inactive (dead)...so that means it's not running. We want the service to be active (running) So the first thing to check is the service enabled?

`sudo systemctl status kubelet.service`

If the service wasn't configured to start up by default (disabled) we can use enable to set it to.

`sudo systemctl enable kubelet.service`

That just enables the service to start up on boot, we could reboot now or we can start it manually
So let's start it up and see what happens...ah, it's now actice (running) which means the kubelet is online.
We also see in the journald snippet, that it's watching the apiserver. So good stuff there...

```Bash
sudo systemctl start kubelet.service
sudo systemctl status kubelet.service
```

Crashlooping kubelet...indicated by the code = exited and the status = 255
But that didn't tell us WHY the kubelet is crashlooping, just that it is...let's dig deeper

`sudo systemctl status kubelet.service --no-pager`

systemd based systems write logs to journald, let's ask it for the logs for the kubelet
This tells us exactly what's wrong, the failed to load the Kubelet config file which it thinks is at /var/lib/kubelet/config.yaml

`sudo journalctl -u kubelet.service --no-pager`


## Kubernetes Security

Get Client Certificate Data from Kubectl Config

`kubectl config view --raw -o jsonpath="{.users[?(@.name=='k8s-admin')].user.client-certificate-data}" | base64 -d`

Get Client Key from Kubectl Config

```bash
$ kubectl config view --raw -o jsonpath="{.users[?(@.name=='k8s-admin')].user.client-key-data}" | base64 -d
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAqEs3hslI/1ndwsN8YG1GSP8DoBFfIJXjJW0+cGelYp6hs9lm
gUmnsq9P0n26LNJpZI6SZ+lVTzgejisqF7mxXnf1kKTeRpoggo/nZ3WrLTpCjCuM
JPUfFgKo178zmVfAILWipe3Ny/JuZF17oaiAIMmVK9OZMek2dvFSlSlVB2WVOp5P
kVHFvJgQ5qYbsRW7F/l9x1dyQbVURCdRdTBMcyrOeU8lTPtH7Baceg2raxUJBbk8
SI4UJJlSPKKRkO6zmJ23PzLTFp3Cptrm17sUgw+aQ2UDUpnB7yIu4THlG3zh67W7
eTDteExV3TAjxNUbNKHPUzp2PB3wf53b2x0ONwIDAQABAoIBAATR6qw0lZ+inkRW
vvgwCQRMMXljJftT76aBw3kKruTtMCprfpETX/cxKDMaILvp5tTXdH//Yc8cB1wB
BnqZeef/vYu//RG+llHG91SyPQ3VjlRfZuskDhjeSKGtOzgYGEuXiCoCbpN5xQmg
18qgfdLykxAnRkr0p/euH7Rf86x7g2bktfmguZzdfBvISb8kIhk9o3uWc+1dTzw5
Y0nw5PzquGp0EWiTZsk9heK6gr/C0epq//g51aBpIoRGk3y7soUlF4Nkmnc9Nlqa
d5Op3cL7ObdFSbgoNyY6JO8GNhqhLjVZ06LPQx968rC+AiudTCwrb8TizBp619tD
SwgpSTECgYEAwDSmlh8mBVo2qR7A9XhfgvWdaCdAZZbi67bdktEETC77Xu6ukMj9
lhoHQz6oaJiB4O10fhiJDxK7zfks20WEjDnnaG7pEDsjb4ts5oGJ/tifCWUHZkZm
ODEhDFJLwu6Bg70Bi7xhKeKs0so39s//1zemFzRAzcxQZCG6WkDsDckCgYEA4CbS
Xz9W0TdExHz2zr0GPwn7bFZQIDIWHILWbU8tX+Zj5k/HMl1rTRQqePngFNKiNBCB
hN+2wNepBGl/1k21RNnsXTRhgwyfEYecE2nFaqf8iobwxv6SSSuexwTay7o9rKtb
iUHwpIXtxn3wRuvnbyjRLLBJlSsSGwOUXHFeO/8CgYB6ADGJcqYQma2+dZ3ncgu2
Na8/UELo+Ph6xC0qpu/CZ8P5AyndDycfos/fWCNPmRY/rpnV/D7rSWnaGQLm/95d
n9eKC3R2cANTJz3tpmXwVJHGRdGHksIJgu3GQ2qBhiDBfTRA/UbzbkVi2ybgzDBJ
7LHJYsqLltekZ2BBL5pmOQKBgQCwH/D25EbsN1gyZ9pqEX6h8875jkyBL7nOB0RD
OY52pwniAteLDHpuYyUIT5ax5duLu1h5tmrb1di5XcgT9JU1F2KwzaK9HSKz3HFX
-k6mKJ5q4olT4lzkMg1jMGlVs9NbXIQHYtNZH//AYIga1Q1FjN5g8W/xFWEVusn5V
sMKRswKBgEWWQ9peybZIaT4n9cGDoZBdp3cde6wYYae3n9zq2J9zUGuuCOlWlMHf
6ZekMDyUUS5OXhwmcMV5P8iJUq83rtGQfDhgTuECK1qMQYw+2eTgrZd3t+vk4X8c
eMKcsY2p2nlSO3P7wdZfzGSDzWYl/mDFB3UfkNdT/mKWGv7xGftx
-----END RSA PRIVATE KEY-----
```

Read Certificate and Output in human readable format

`openssl x509 -in admin.crt -text -noout | head`

Accessing the API Server inside a Pod

```bash
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{ .items[*].metadata.name }')
kubectl exec $PODNAME -it -- /bin/bash
ls /var/run/secrets/kubernetes.io/serviceaccount/
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

Load the token and cacert into variables for reuse
`TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
`CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`

But it doesn't have any permissions to access objects...this user is not authorized to access pods

`curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api/v1/namespaces/

We can also use impersonation to help with our authorization testing
`kubectl auth can-i list pods --as=system:serviceaccount:default:mysvcaccount1`
`kubectl get pods -v 6 --as=system:serviceaccount:default:mysvcaccount1`

But we can create an RBAC Role and bind that to our service account
We define who, can perform what verbs on what resources

`kubectl create role demorole --verb=get,list --resource=pods`
`kubectl create rolebinding demorolebinding --role=demorole --serviceaccount=default:mysvcaccount1`

Then the service account can access the API with the
https://kubernetes.io/docs/reference/access-authn-authz/rbac/#service-account-permissions

`kubectl auth can-i list pods --as=system:serviceaccount:default:mysvcaccount1`
`kubectl get pods -v 6 --as=system:serviceaccount:default:mysvcaccount1`

Go back inside the pod again...

```bash
kubectl get pods
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{ .items[*].metadata.name }')
kubectl exec $PODNAME -it -- /bin/bash
```

Load the token and cacert into variables for reuse

`CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`

Now I can view objects...this isn't just for curl but for any application.
Apps commonly use libraries to programmaticly interact with the api server for cluster state information

`curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api/v1/namespaces/`

## Investigating the PKI setup on the Control Plane Node

The core pki directory, contains the certs and keys for all core functions in your cluster,
the self signed CA, server certificate and key for encryption by API Server,
etcd's cert setup, sa (serviceaccount) and more.

`ls -l /etc/kubernetes/pki`

Read the ca.crt to view the certificates information, useful to determine the validity date of the certificate
You can use this command to read the information about any of the *.crt in this folder
Be sure to check out the validity and the Subject CN

`openssl x509 -in /etc/kubernetes/pki/ca.crt -text -noout | more`

2 - kubeconfig file location, for system components, controller manager, kubelet and scheduler.

`ls /etc/kubernetes`

certificate-authority-data is a base64 encoded ca.cert
You can also see the server for the API Server is https
And there is also a client-certificate-data which is the client certificate used.
And client-key-data is the private key for the client cert. these are used to authenticate the client to the api server

`sudo more /etc/kubernetes/scheduler.conf`

> The kube-proxy has it's kube-config as a configmap rather than a file on the file system.

`kubectl get configmap -n kube-system kube-proxy -o yaml`

## Kubernetes - Create New User Certificate

- References:
https://geekflare.com/openssl-commands-certificates/
https://kubernetes.io/docs/concepts/cluster-administration/certificates/#cfssl
https://www.freecodecamp.org/news/openssl-command-cheatsheet-b441be1e8c4a/
https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs

### 1 - Create a RSA private key

`openssl genrsa -out demouser.key 2048`

```bash
$ cat demouser.key
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAww0cP9PFhgXLSEMRTmvTKym2zcyMa9P5CgqGU9+MCv/Ngiw4
RjcuqsKyqIhetgzNVDHtlFA4zELuHbzgAv1uvky8DbINaf6aIgUnf2ZragpC8IQn
lfHUIKapXdjqwbK3JQCY5W7ba0c3fdvOBHXkOij74tLDxtx/jP7x08zVE5UIiqeC
XwOkiP1mjHHWsU8UkTKNnwjUFSoW/BUVQDJeK9WPtkd547djyOiFOgogkfXOy5F2
HH1n23qOFT8DaNL9KRfMgnQEIXVhBJclRHgGXun6ynFKE3WMZGKDpUq4wFaKvU2X
mvEPIPR3Iu+pt0hJjSGpnlJWHfr6MQn7y4HO4QIDAQABAoIBAHtaxD3diXL8IRa/
S6ej63XFuNWogjoDYeGmzFMo8qFWK7siiihl576YyXJqZDOQHx8bQFxm67TKs1rd
Q3LAopP5ZYjnzTH2kbXoOpWIyW/Ts4f2nC5pNTW9ESnH8Je1lbvyB8A5/sx2yrJv
G3iYslDR8JL/pk8Szhv2dCv1w9/Qa2SlF2YCqy41V4Lih2n76cAZ7csC7PjynBVH
h+m3Tz98gug6oEWfIMPpyTPLwCO2+P6f9hxtlFa8zWbXJ3MYiIn0DwMA0UEf40S4
qyEAU4c6jcFWdIEIRNTmJr2WwAfopP1v78plSMuqIo2rNns0o/ZvVkVer9AhEwR3
EjaAMVECgYEA4CpHHI1rjxLVI1LeOTCasOCI4csBeCSspJyqSppYAKy9F81iKBeV
o9UfjvunZ6x8ZzZWzEFBv8YByTSKCd3Uuq/P33LQNgZjH2X4EZhP4a948CV+V0li
+0h4kHLR7Te5ZuFePZ7ptoUf99Ao/N3JUATC2oD6VSaOQoJo3w0zat0CgYEA3sBe
pLB4AGgKZPwOzHwVInJsbNC4R9w1ckZLFHZifZ89agbEvcGJW/jVgw8/E+SPNa3E
100WaDwa88864YCROIuF2KWtAa/D16nAf8hsk4uGO8RnqvpFB7qYlp5GSRSgTAMv
/nbcjcCObEOAvK8ICBi4j/+GCVyRDBG2lYEGqdUCgYAfWgpkFetrMUkaDacC/KdG
AcFjQw9LjGWRCFBQ6tFQFtjDkXge/11wcohdaRj6yQcFMHZnTuExPzJUv8Jmqt3r
1lcOe3Jfe/k1FP/jBhh2CiKyA6xt7NepKXOjUEvID7kgiHizyZwKaQgVksmIxEQ5
qtDN2qgobKIM70xXlfMRCQKBgQCf9tYAvxnucMjGLJ0UDCfBTRrAKkOsl19qaUCR
uVKRlEGuWp3/B3V1LwVl0RUjXAfcLKYnV5y3zjIs1K0cNBAV41yDcLcFdwvVXHp5
SZ1vd8s2MJ2iE4hvPHlH8PHYmY9kBwX4X7OTuKyO4wsYdTn3Vol0H7RKFMe1OyM7
yiTW4QKBgQDeR4OfE4p61bJY+0rArEEtvXqReYzZAxqlGE0m6FL2zXNQ4MSqecgf
1lnzCUPcHfH2b0DsPAVDsJIaOmqLFVv7BXeG3J0OjGAwAIvDFHqMtp/36CYwWCN1
TahZVjHWx2+SqwxelhSZJHlRnGLqwfo8hqeb0CNnaiLcldX5WVnovw==
-----END RSA PRIVATE KEY-----
```

> Verify private key file using openssl

`openssl rsa -in demouser.key -check`

> Print public key using openssl

`openssl rsa -in demouser.key -pubout`

### 2 - Generate a CSR

CN (Common Name) is your username, O (Organization) is the Group

> If you get an error Can't load /home/USERNAME/.rnd into RNG - comment out RANDFILE from /etc/ssl/openssl.conf see this link for more details https://github.com/openssl/openssl/issues/7754#issuecomment-541307674

`openssl req -new -key demouser.key -out demouser.csr -subj "/CN=demouser"`

or you can leave subject out and be prompted for additional information

```bash
$ openssl req -new -key demouser.key -out demouser.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name: 2-digit country code where your organization is legally located.
State/Province: Write the full name of the state where your organization is legally located.
City: Write the full name of the city where your organization is legally located.
Organization Name: Write the legal name of your organization.
Organization Unit: Name of the department (Not Compulsory. Press Enter to skip)
Common Name: Your Fully Qualified Domain Name (e.g., www.yourdomainname.com.)
Email: The email ID through which certification will take place (Not Compulsory. Press Enter to skip)
```

The certificate request we'll use in the CertificateSigningRequest

```bash
$ cat demouser.csr
-----BEGIN CERTIFICATE REQUEST-----
MIICWDCCAUACAQAwEzERMA8GA1UEAwwIZGVtb3VzZXIwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDDDRw/08WGBctIQxFOa9MrKbbNzIxr0/kKCoZT34wK
/82CLDhGNy6qwrKoiF62DM1UMe2UUDjMQu4dvOAC/W6+TLwNsg1p/poiBSd/Zmtq
CkLwhCeV8dQgpqld2OrBsrclAJjlbttrRzd9284EdeQ6KPvi0sPG3H+M/vHTzNUT
lQiKp4JfA6SI/WaMcdaxTxSRMo2fCNQVKhb8FRVAMl4r1Y+2R3njt2PI6IU6CiCR
9c7LkXYcfWfbeo4VPwNo0v0pF8yCdAQhdWEElyVEeAZe6frKcUoTdYxkYoOlSrjA
Voq9TZea8Q8g9Hci76m3SEmNIameUlYd+voxCfvLgc7hAgMBAAGgADANBgkqhkiG
9w0BAQsFAAOCAQEARM18RbWm3225P61t9djzU21J0ftqSG2FPtYIL6hFSJFcwknq
kG/DlUDiqAFBmDyS+iJCcEabouzbHewdrNEI+CstJu1n66FITCdkUmFdFnqnQBRB
6tvBSv0h/z0GioIRuLzgO1iWegl26a3TNt8I1S8YbJtTRnuV8GuVdKhm9BOYkMDZ
dsS9uJ61zYN77HKVpiehyC94COzSMKGiipOzdu61BRDww/0X2rg1OVpy0z53ofUO
HayIUOw7iYw2bueZpFpaP0vJ09lpwAu3KW5wUxT5Ng024oOfW6kT2dNa3epstqYQ
IKy0TLJhJDqWkS942k6g82jYqz4+o0NruQ1HKw==
-----END CERTIFICATE REQUEST-----
```

> Verify CSR file

```bash
$ openssl req -in demouser.csr -noout -text -verify
verify OK
Certificate Request:
    Data:
        Version: 1 (0x0)
        Subject: C = US, ST = DE, L = Middletown, O = Home, OU = Lab, CN = demouser, emailAddress = no-reply@demo.user
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
```

> The CertificateSigningRequest needs to be base64 encoded and also have the header and trailer pulled out.

`cat demouser.csr | base64 | tr -d "\n" > demouser.base64.csr`

to decode:

`cat demouser.base64.csr | base64 -d`

> ALTERNATIVE - Encode with Openssl Base64

`cat demouser.csr | openssl enc -base64 -A > demouser.base64.csr`

to decode:

`cat demouser.base64.csr | openssl base64 -A -d`

### 1B/2B - ALTERNATIVE - Create a new private key AND Certificate Signing Request

The below command will generate CSR and a 2048-bit RSA key file.
If you intend to use this certificate in Apache or Nginx, then you need to send this CSR file to certificate issuer authority,
and they will give you a signed certificate mostly in der or pem format which you need to configure in Apache or Nginx web server.

`openssl req -out demouser.csr -newkey rsa:2048 -nodes -keyout demouser.key`

### 3 - Submit the CertificateSigningRequest to the API Server - K8s 1.19+

> UPDATE: If you're on 1.19+ use this CertificateSigningRequest

Key elements, name, request and usages (must be client auth)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: demouser
spec:
  groups:
  - system:authenticated
  request: $(cat demouser.base64.csr)
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
```

### 3 - Submit the CertificateSigningRequest to the API Server - K8s 1.18

> UPDATE: If you're on 1.18.x or below use this CertificateSigningRequest

Key elements, name, request and usages (must be client auth)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: demouser
spec:
  groups:
  - system:authenticated
  request: $(cat demouser.base64.csr)
  usages:
  - client auth
EOF
```

Let's get the CSR to see it's current state. The CSR will delete after an hour This should currently be Pending, awaiting administrative approval

```bash
$ kubectl get certificatesigningrequests
NAME       AGE   SIGNERNAME                            REQUESTOR   CONDITION
demouser   25s   kubernetes.io/kube-apiserver-client   k8s-admin   Pending
```

### 4 - Approve the CSR

`kubectl certificate approve demouser`

If we get the state now, you'll see Approved, Issued.
The CSR is updated with the certificate in .status.certificate

```bash
$ kubectl get certificatesigningrequests demouser
NAME       AGE   SIGNERNAME                            REQUESTOR   CONDITION
demouser   93s   kubernetes.io/kube-apiserver-client   k8s-admin   Approved,Issued
```

### 5 - Retrieve the certificate from the CSR object, it's base64 encoded

```bash
kubectl get certificatesigningrequests demouser \
  -o jsonpath='{ .status.certificate }'  | base64 --decode
```

Let's go ahead and save the certificate into a local file.
We're going to use this file to build a kubeconfig file to authenticate to the API Server with

```bash
kubectl get certificatesigningrequests demouser -o jsonpath='{ .status.certificate }'  | base64 --decode > calmuser.crt
```

Check the contents of the file

`cat demouser.crt`

Read the certficate itself
Key elements: Issuer is our CA, Validity one year, Subject CN=demousers

`openssl x509 -in demouser.crt -text -noout | head -n 15`

Now that we have the certificate we can use that to build a kubeconfig file with to log into this cluster.
We'll use demouser.key and demouser.crt

`ls demouser.*`

### COMPLETE ALTERNATIVE A - Create a Self-signed Certificate

The below command will generate a self-signed certificate valid for two years with sha256 –days parameter to extend the validity.

Ex: to have self-signed valid for two years.

`openssl req -x509 -sha256 -nodes -days 730 -newkey rsa:2048 -keyout demouser_self.key -out demouser_cert.pem`

### MISC ALTERNATIVE B

#### Create a CSR from existing certificate and private key

`openssl x509 -x509toreq -in cert.pem -out example.csr -signkey example.key`

or just from existing private key

`openssl req –out certificate.csr –key existing.key –new`

#### Generate a CSR for multi-domain SAN certificate by supplying an openssl config file:

`openssl req -new -key example.key -out example.csr -config req.conf`

```bash
cat <<EOF | tee req.conf
[req]prompt=nodefault_md = sha256distinguished_name = dnreq_extensions = req_ext
[dn]CN=example.com
[req_ext]subjectAltName=@alt_names
[alt_names]DNS.1=example.comDNS.2=www.example.comDNS.3=ftp.example.com
EOF
```

#### Create X.509 certificates

Create self-signed certificate and new private key from scratch:

`openssl req -nodes -newkey rsa:2048 -keyout example.key -out example.crt -x509 -days 365`

Create a self signed certificate using existing CSR and private key:

`openssl x509 -req -in example.csr -signkey example.key -out example.crt -days 365`

### Troubleshooting Certificate Issues

> Verify that private key matches a certificate, CSR and Private Key

`openssl verify demouser.crt`

`openssl rsa -in demouser.key –check`

`openssl rsa -noout -modulus -in demouser.key | openssl sha256`

`openssl x509 -noout -modulus -in demouser.crt | openssl sha256`

`openssl req -noout -modulus -in demouser.csr | openssl sha256`

> Verify a Certificate was Signed by a CA

`openssl verify -verbose -CAFile ca.crt domain.crt`

> Verifty the Certificate Signer Authority

`openssl x509 -in certfile.pem -text –noout`

`openssl x509 -in demouser_cert.pem -noout -issuer -issuer_hash`

- Check Hash Value of A Certificate

`openssl x509 -noout -hash -in demouser_cert.pem`

> Verify certificate, when you have *intermediate certificate chain*. *Root certificate is not a part of bundle*, and should be configured as a trusted on your machine.

`openssl verify -untrusted demouser-intermediate.pem demouser.crt`

> Verify certificate, when you have *intermediate certificate chain* and *root certificate*, that is not configured as a trusted one.

`openssl verify -CAFile root.crt -untrusted intermediate-ca-chain.pem child-demouser.crt`

> Verify that certificate served by a remote server covers given host name. Useful to check your mutlidomain certificate properly covers all the host names.

`openssl s_client -verify_hostname www.example.com -connect example.com:443`

> TLS client to connect to a remote server

Test SSL certificate of particular URL

- Connect to a server supporting TLS:

`openssl s_client -connect example.com:443`
`openssl s_client -host example.com -port 443`
`openssl s_client -connect yoururl.com:443 –showcerts`

- Connect to a server and show full certificate chain:

`openssl s_client -showcerts -host example.com -port 443 </dev/null`

- Extract the certificate:

`openssl s_client -connect example.com:443 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p' > certificate.pem`

- Override SNI (Server Name Indication) extension with another server name. Useful for testing when multiple secure sites are hosted on same IP address:

`openssl s_client -servername www.example.com -host example.com -port 443`

- Measure SSL connection time without/with session reuse:

`openssl s_time -connect example.com:443 -new`

`openssl s_time -connect example.com:443 -reuse`

> Convert between encoding and container formats

- Convert certificate between DER and PEM formats:

`openssl x509 -in example.pem -outform der -out example.der`
`openssl x509 -in example.der -inform der -out example.pem`

> Check PEM File Certificate Expiration Date

`openssl x509 -noout -in certificate.pem -dates`

> Check Certificate Expiration Date of SSL URL

`openssl s_client -connect google.com:443 2>/dev/null | openssl x509 -noout -enddate`

> Check TLS Versions are accepted on URL

`openssl s_client -connect secureurl.com:443 –tls1`

`openssl s_client -connect secureurl.com:443 –tls1_1`

openssl s_client -showcerts -servername rancher.10.38.20.81.nip.io -connect rancher.10.38.20.81.nip.io:443


## Capacity Planning

> Get vCPU Count from all nodes

kubectl get nodes -o=jsonpath="{range .items[*]}{.metadata.name}{\"\t\"} \
        {.status.capacity.cpu}{\"\n\"}{end}"