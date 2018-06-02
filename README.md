
## Azure Kubernetes Service

```
# westus2 / ukwest
LOCATION=centralus
RG=daz-aks-rg
CLUSTERNAME=dow-aks

# While AKS is in preview, creating new clusters requires a feature flag on your subscription.
az provider register -n Microsoft.ContainerService

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
# Standard_D2_v2 Standard_DS1_v2
# Avoid using burst VM's, they are too small, such as Standard_B1ms

az group create --name $RG --location $LOCATION
az aks create --resource-group $RG --name ${CLUSTERNAME} --generate-ssh-keys --node-count 2 -k 1.8.11
az aks get-credentials --resource-group $RG --name ${CLUSTERNAME}
```

## Install kubectl
### Method 1
```
sudo az aks install-cli
```
### Method 2
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod a+x ./kubectl
sudo mv kubectl /usr/local/bin
```
### Method 3
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.10.3/bin/linux/amd64/kubectl
chmod a+x ./kubectl
sudo mv kubectl /usr/local/bin

kubectl get nodes
kubectl version
```

## Access k8s GUI, setup SSH Tunelling in your SSH Client
* Run both commands from your laptop, and connect to http://127.0.0.1:8001 http://127.0.0.1:9000

### Method 1
```
az aks browse -g resource-group -n name
```

### Method 2
```
kubectl get pods --namespace kube-system | grep kubernetes-dashboard
kubernetes-dashboard-3427906134-9vbjh   1/1       Running   0          49m
kubectl -n kube-system port-forward kubernetes-dashboard-665f768455-7bjm5 9000:9090
```

## Install helm - Method 1 - Automatically download latest version
```
wget https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
chmod a+x get
./get

# You can also specify a specific version
./get -v 2.7.2
```

## Install helm - Method 2 - Manual - Download a specific version
```
wget https://kubernetes-helm.storage.googleapis.com/helm-v2.7.2-linux-amd64.tar.gz
sudo tar xvzf helm-v2.7.2-linux-amd64.tar.gz --strip-components=1 -C /usr/local/bin linux-amd64/helm

# Install Tiller (helm server)
helm init --service-account default

# Test an installation via helm, to ensure that it's working
# Installing and removing a package on K8s 1.9.6 has been a workaround
helm install stable/locust
helm delete vigilant-hound
```

## Add Azure repo
```
helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
helm search azure
helm install azure/azure-service-broker
```

## Deploy Datadog helm chart for monitoring
```
helm install --name dg-release --set datadog.apiKey=1234567890 --set rbac.create=false --set rbac.serviceAccount=false --set kube-state-metrics.rbac.create=false --set kube-state-metrics.rbac.serviceAccount=false stable/datadog
```

## If you want to SSH into your VM's within your agent pool, then follow these instructions
https://docs.microsoft.com/en-us/azure/aks/aks-ssh

## To use and configure HTTP routing, read up here or depoy nginx ingress controller manually
https://docs.microsoft.com/en-us/azure/aks/http-application-routing

## Deploy nginx ingress controller and configure it
* https://docs.microsoft.com/en-us/azure/aks/ingress
```

helm install stable/nginx-ingress --namespace kube-system --set rbac.create=false --set rbac.createRole=false --set rbac.createClusterRole=false

$ kubectl get service -l app=nginx-ingress --namespace kube-system
NAME                                           TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
ranting-beetle-nginx-ingress-controller        LoadBalancer   10.0.64.146   204.43.245.186   80:30649/TCP,443:31654/TCP   1m
ranting-beetle-nginx-ingress-default-backend   ClusterIP      10.0.9.5      <none>           80/TCP                       1m

#!/bin/bash

# Public IP address
IP="204.43.245.186"

# Name to associate with public IP address
DNSNAME="demo2-aks-ingress"

# Get the resource-id of the public ip
PUBLICIPID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv)

# Update public ip address with dns name
az network public-ip update --ids $PUBLICIPID --dns-name $DNSNAME

$ dig +short demo2-aks-ingress.centralus.cloudapp.azure.com
204.43.245.186

# Configure ingress controller and a certificate management solution
helm install stable/kube-lego \
  --set config.LEGO_EMAIL=user@contoso.com \
  --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory

helm repo add azure-samples https://azure-samples.github.io/helm-charts/
helm install azure-samples/aks-helloworld

helm install azure-samples/aks-helloworld --set title="AKS Ingress Demo" --set serviceName="ingress-demo"

## Create ingress route
#
# kubectl apply -f hello-world-ingress.yaml
#
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    kubernetes.io/tls-acme: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - demo2-aks-ingress.eastus.cloudapp.azure.com
    secretName: tls-secret
  rules:
  - host: demo2-aks-ingress.eastus.cloudapp.azure.com
    http:
      paths:
      - path: /
        backend:
          serviceName: aks-helloworld
          servicePort: 80
      - path: /hello-world-two
        backend:
          serviceName: ingress-demo
          servicePort: 80
```

## Deploy virtual-kubelet
* Azure Container Instance is not available at location "centralus". The available locations are "westus,eastus,westeurope,southeastasia"
```
az aks install-connector --name akscluster --resource-group demorg --connector-name myaciconnector --os-type both
```

## Upgading virtual-kubelet
```
az aks upgrade-connector --name orange-aks --resource-group orange-aks-rg --connector-name myaciconnector
```

## Dev Spaces - What is it
* Run and debug multiple containers directly in Kubernetes just by hitting F5
* Iterate your code pre-commit into your SCM and CICD pipeline
* Iteratively develop code in containers using Visual Studio and Kubernetes
* Develop with VS, VS Code or command line
* Collaborate within a development team by sharing an AKS cluster
* Test code end-to-end without replicating or simulating dependencies
* When your happy with your code, then you use your CICD pipeline to deploy your code
* Uses init-containers and sidecars for instrumentation
* Modifies the ingress controller to add in a route to the K8s namespace relating to your dev space
* Languate Support : node.JS and .NET core supported, Java support is next, .NET Framework is not yet supported
* Private Preview : Signup aka.ms/devspaces
* https://channel9.msdn.com/Events/Build/2018/BRK3809

## Dev Spaces - azure-cli
* Enable dev-spaces to be used with that cluster.  Downloads a tool called azds
```
az aks use-dev-spaces -g <rg> -n <name>
```
### Look at code in current directory and create a Dockerfile and helm chart
```
azds prep --public
azds up
```

## Dev Spaces - Visual Studio
* Azure Dev Spaces extension for VS Code - debug live code running on AKS
http://landinghub.visualstudio.com/devspaces
https://docs.microsoft.com/en-us/azure/dev-spaces/quickstart-netcore-visualstudio
https://docs.microsoft.com/en-us/azure/dev-spaces/azure-dev-spaces

## Shared Dev Spaces - Visual Studio
* Breakpoints are stored within the namespace, so with a shared dev space, you'll see the breakpoints which someone else set
* Type commands in VS Code Terminal
```
azds space list
azds space select -n lisa
Hit F5
```

## Kubernetes Cronjobs
* k8s-cron-jobs required k8s 1.8 or higher https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
```

wget https://raw.githubusercontent.com/kubernetes/website/master/docs/concepts/workloads/controllers/cronjob.yaml
kubectl create -f ./cronjob.yaml
kubectl get cronjob
cronoutput=$(kubectl get pods --selector=job-name=hello-4111706356 --output=jsonpath={.items..metadata.name})
echo $cronoutput
# View output from cron
kubectl logs $cronoutput
kubectl delete cronjob hello
```

## Changing K8s cluster context
```
$ kubectl config current-context
daz-aks
$ kubectl config use-context daz-aks
Switched to context "daz-aks".
$ kubectl config get-contexts
CURRENT   NAME             CLUSTER          AUTHINFO                                       NAMESPACE
*         daz-aks          daz-aks          clusterUser_daz-aks-rg_daz-aks
          fabmedical-daz   fabmedical-daz   clusterUser_fabmedical-daz-rg_fabmedical-daz
```

## RBAC
* https://kubernetes.io/docs/admin/authorization/rbac/
```
* RoleBindings are bounded to a certain namespace
* ClusterRoleBindings are cluster-global
* Roles define a list of actions that can be performed over the resources or verbs: GET, WATCH, LIST, CREATE, UPDATE, PATCH, DELETE.
* Roles are assigned to ServiceAccounts

$ kubectl api-versions|grep rbac
rbac.authorization.k8s.io/v1
rbac.authorization.k8s.io/v1beta1

$ kubectl get clusterroles
No resources found.

$ kubectl get clusterrole cluster-admin -o yaml

$ kubectl get clusterrolebindings
NAME                  AGE
permissive-binding    9m
tiller                23h
tiller-binding        5d
tiller-cluster-rule   4m

$ kubectl get clusterrolebindings tiller -o yaml

$ kubectl auth can-i list pods -n default --as=system:serviceaccount:default:default
yes
$ kubectl auth can-i create pods -n default --as=system:serviceaccount:default:default
yes
$ kubectl auth can-i delete pods -n default --as=system:serviceaccount:default:default
yes
$ kubectl auth can-i list services -n default --as=system:serviceaccount:default:default
yes
```

## View versions of Kubernetes, which can be upgraded
```
$ az aks get-versions -l centralus -o table
KubernetesVersion    Upgrades
-------------------  -------------------------------------------------------------------------
1.9.6                None available
1.9.2                1.9.6
1.9.1                1.9.2, 1.9.6
1.8.11               1.9.1, 1.9.2, 1.9.6
1.8.10               1.8.11, 1.9.1, 1.9.2, 1.9.6
1.8.7                1.8.10, 1.8.11, 1.9.1, 1.9.2, 1.9.6
1.8.6                1.8.7, 1.8.10, 1.8.11, 1.9.1, 1.9.2, 1.9.6
1.8.2                1.8.6, 1.8.7, 1.8.10, 1.8.11, 1.9.1, 1.9.2, 1.9.6
1.8.1                1.8.2, 1.8.6, 1.8.7, 1.8.10, 1.8.11, 1.9.1, 1.9.2, 1.9.6
1.7.16               1.8.1, 1.8.2, 1.8.6, 1.8.7, 1.8.10, 1.8.11
1.7.15               1.7.16, 1.8.1, 1.8.2, 1.8.6, 1.8.7, 1.8.10, 1.8.11
1.7.12               1.7.15, 1.7.16, 1.8.1, 1.8.2, 1.8.6, 1.8.7, 1.8.10, 1.8.11
1.7.9                1.7.12, 1.7.15, 1.7.16, 1.8.1, 1.8.2, 1.8.6, 1.8.7, 1.8.10, 1.8.11
1.7.7                1.7.9, 1.7.12, 1.7.15, 1.7.16, 1.8.1, 1.8.2, 1.8.6, 1.8.7, 1.8.10, 1.8.11
```

## Upgrade to the latest K8s
```
$ az aks upgrade -n $CLUSTERNAME --resource-group $RG --kubernetes-version 1.9.6 --yes
```

## Procedure to reboot VM's within the agent pool
```
kubectl get nodes
# Gracefully terminate all pods on the node while marking the node as unschedulable:
# If your daemonsets are non-critical pods such as monitoring agents then ignore-daemonsets
kubectl drain aks-agentpool-75595413-0 --ignore-daemonsets

# Check that SchedulingDisabled is set
$ kubectl get nodes
NAME                       STATUS                     ROLES     AGE       VERSION
aks-agentpool-75595413-0   Ready,SchedulingDisabled   agent     3d        v1.9.6
aks-agentpool-75595413-2   Ready                      agent     3d        v1.9.6

# Check no pods running on aks-agentpool-75595413-0
kubectl get pods -o wide

az vm restart --resource-group MC_orange-aks-rg_orange-aks_centralus -n aks-agentpool-75595413-0
kubectl uncordon aks-agentpool-75595413-0
kubectl get nodes - o wide
```

## Remove your cluster cleanly
```
# az aks delete --resource-group $RG --name ${CLUSTERNAME} --yes
# az group delete --name $CLUSTERNAME --no-wait --yes
```


## Random commands
```
# Increase verbosity
kubectl delete -f mpich.yml -v=9

# Selecting a pod, by the label
kubectl get pods --selector app=samples-tf-mnist-demo --show-all

# Extract metadata from K8s
$ kubectl get pod dg-release-datadog-hlvxc -o=jsonpath={.status.containerStatuses[].image}
datadog/agent:6.1.2

# View configuration details of a pod, deployment, service etc
$ kubectl get pod dg-release-datadog-hlvxc -o json | jq
<output formatted>

# View config in yaml
$ kubectl get pod dg-release-datadog-hlvxc -o yaml

# Edit a live pod config
$ kubectl edit pod dg-release-datadog-hlvxc

# Forcefully remove a pod
$ kubectl delete pods tiller-deploy -n kube-system --force=true --timeout=0s --now -v9

# Testing Service Discovery (DNS not Environment variables)
$ kubectl run busybox --image busybox -it -- /bin/sh
If you don't see a command prompt, try pressing enter
$ nslookup nginxServer:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
Name:      nginx
Address 1: 10.109.24.56 nginx.default.svc.cluster.local

# Upload nginx.conf configuration file into a configmap
$ kubectl create configmap ambassador-config --from-file=conf.d

# Useful command to view details of a K8s Worker node within the agent pool
az vm get-instance-view -g "MC_orange-aks-rg_orange-aks_centralus" -n aks-agentpool-75595413-0 
```

Wildcard Certs - Getting, Setting up
https://www.youtube.com/watch?v=JNbvEl52dd4

Ingress - NGINX, TLS
https://www.youtube.com/watch?v=U9_A5B9x4SY

Ingress controller config on k8s.
https://blogs.technet.microsoft.com/livedevopsinjapan/2017/02/28/configure-nginx-ingress-controller-for-tls-termination-on-kubernetes-on-azure-2/

AKS Docs
https://docs.microsoft.com/en-us/azure/aks/
