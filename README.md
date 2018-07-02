
## Azure Kubernetes Service

Official Docs for AKS deployment are now available here or you can read this guide<br>
https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster

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
az aks create --resource-group $RG --name ${CLUSTERNAME} --generate-ssh-keys --node-count 2 -k 1.10.3
az aks get-credentials --resource-group $RG --name ${CLUSTERNAME}
```

## Install kubectl

Chose from one of the following

### Method 1 (Ubuntu|RHEL)

```
$ sudo az aks install-cli
```
### Method 2 (Ubuntu|RHEL)
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
$ chmod a+x ./kubectl
$ sudo mv kubectl /usr/local/bin
```
### Method 3 (Ubuntu|RHEL)
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.10.3/bin/linux/amd64/kubectl
$ chmod a+x ./kubectl
$ sudo mv kubectl /usr/local/bin

$ kubectl get nodes
$ kubectl version
```
### Method 4 (Ubuntu)
```
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubectl
```
### Method 5 (MacOS)
```
$ brew install kubectl
```

### Method 6 (Windows)
Download Azure CLI -> https://aka.ms/installazurecliwindows
```
Run "Azure Command Prompt"
az login
az aks install-cli --install-location c:\apps\kubectl.exe
az aks get-credentials --name k8s-aks --resource-group k8s-aks-rg
```

## Access k8s GUI, setup SSH Tunelling in your SSH Client
* Run both commands from your laptop, and connect to http://127.0.0.1:8001 http://127.0.0.1:9000

### Method 1 - Using Azure-CLI
```
az aks browse -g resource-group -n name
```

### Method 2 - Using kubectl
```
$ kubectl get pods --namespace kube-system | grep kubernetes-dashboard
$ kubernetes-dashboard-3427906134-9vbjh   1/1       Running   0          49m
$ kubectl -n kube-system port-forward kubernetes-dashboard-665f768455-7bjm5 9000:9090
```

## BASH kubectl completion

https://kubernetes.io/docs/tasks/tools/install-kubectl/#enabling-shell-autocompletion

```
# If Linux
echo "source <(kubectl completion bash)" >> ~/.bashrc

# If MacOS
brew install bash-completion@2
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

## Install helm - Method 1 - Automatically download latest version
```
$ wget https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
$ chmod a+x get
$ ./get

# You can also specify a specific version
$ ./get -v 2.7.2
```

## Install helm - Method 2 - Manual - Download a specific version for Linux
```
$ wget https://kubernetes-helm.storage.googleapis.com/helm-v2.7.2-linux-amd64.tar.gz
$ sudo tar xvzf helm-v2.7.2-linux-amd64.tar.gz --strip-components=1 -C /usr/local/bin linux-amd64/helm

# Install Tiller (helm server)
$ helm init --service-account default

# Test an installation via helm, to ensure that it's working
# Installing and removing a package on K8s 1.9.6 has been a workaround
helm install stable/locust
helm delete vigilant-hound
```

## Install helm - Method 3 - MacOS
```
brew install kubernetees-helm
```

## Add Azure repo
```
$ helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
$ helm search azure
$ helm install azure/azure-service-broker
```

## Deploy Datadog helm chart for monitoring
```
$ helm install --name dg-release --set datadog.apiKey=1234567890 --set rbac.create=false --set rbac.serviceAccount=false --set kube-state-metrics.rbac.create=false --set kube-state-metrics.rbac.serviceAccount=false stable/datadog
```

## HPA - Horizontal Pod Autoscaling (CPU) - Manual
```
# Horizontal Pod Autoscale
$ kubectl autoscale deployment <deployment-name> --min=2 --max=5 --cpu-percent=80
$ kubectl get hpa

$ kubectl get hpa/acs-helloworld-idle-dachshund -o yaml > demo.yaml
vi demo.yaml
  maxReplicas: 4
  minReplicas: 2
$ kubectl apply -f ./demo.yaml
```

## HPA - Horizontal Pod Autoscaling (CPU) - Scriptable
```
$ kubectl apply --record -f acs-helloworld-frontend-hpa.yaml
```

```
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
  namespace: my-app-space
  labels:
    app: my-app
    tier: frontend
spec:
  scaleTargetRef:
    apiVersion: apps/v1beta1
    kind: Deployment
    name: my-app-deployment
  minReplicas: 2
  maxReplicas: 20
  targetCPUUtilizationPercentage: 75
```

## HPA - Testing
```
$ apt-get install siege
$ cat > siege-urls.txt <<!EOF
http://demo2-aks-ingress.centralus.cloudapp.azure.com
EOF
$ siege --verbose --benchmark --internet --concurrent 255 --time 10M --file siege-urls.txt
$ watch -d -n 2 -b -c kubectl get hpa
```

## HPA - Horizontal Pod Autoscaling (Memory API : v2beta1) - Scriptable
```
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: extensions/v1beta1
    kind: Deployment
    name: nginx
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: memory
      targetAverageUtilization: 60
```

## Rolling Updates
*Rolling updates allow Deployments' update to take place with zero downtime by incrementally updating Pods instances with new ones
```
Rollouts is a process for updating replicas to match the deployment's template
Triggered by any change to the deployment template
Multiple rollout strategies : "rolling update" is the default.
kubectl commands to check, pause, resume, and rollback rollouts

# Rolling updates can be achieved with 3 commands
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
kubectl rollout status deployments/kubernetes-bootcamp
kubectl rollout undo deployments/kubernetes-bootcamp

# There are other things which you can do, like pause, resume updates
kubectl rollout pause deployment example-app-tier --namespace lesson202
kubectl rollout resume deployment example-app-tier --namespace lesson202

# This flag needs to be used to record rollout deployment history, so that you can rollback
kubectl apply -f my.yaml --record
kubectl rollout status deployment hello-deploy
kubectl get deploy hello-deploy
kubectl rollout history deployment hello-deploy
kubectl describe deploy hello-deploy
kubectl rollout undo deployment hello-world --to-revision=1
```

## If you want to SSH into your VM's within your agent pool, then follow these instructions
https://docs.microsoft.com/en-us/azure/aks/aks-ssh

```
$ az vm list-ip-addresses --resource-group "MC_orange-aks-rg_orange-aks_centralus" -o table
VirtualMachine            PrivateIPAddresses
------------------------  --------------------
aks-agentpool-75595413-0  10.240.0.4
aks-agentpool-75595413-2  10.240.0.6
```

## Ingress Controller (HTTP routing) - Method #1
* "HTTP routing" is an AKS deployment option, read URL below to learn more
* This deploys the nginx ingress controller as an addon and configures DNS into the *.<region>aksapp.io domain
* myappa.example.com ->  888326a4-d388-4bb0-bb01-79c4d162a7a7.centralus.aksapp.io
  That means that the cert will need a SN of  appa.example.com, rather than the long name.
* I recommend to use method 2 as the ingress controller will be the same across Kubernetes clusters, regardless of the Hyperscaler
https://docs.microsoft.com/en-us/azure/aks/http-application-routing

##  Ingress Controller - Method #2
* Deploy nginx ingress controller and configure it
https://docs.microsoft.com/en-us/azure/aks/ingress
```

$ helm install stable/nginx-ingress --namespace kube-system --set rbac.create=false --set rbac.createRole=false --set rbac.createClusterRole=false

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
$ helm install stable/kube-lego \
  --set config.LEGO_EMAIL=user@contoso.com \
  --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory

$ helm repo add azure-samples https://azure-samples.github.io/helm-charts/
$ helm install azure-samples/aks-helloworld

$ helm install azure-samples/aks-helloworld --set title="AKS Ingress Demo" --set serviceName="ingress-demo"

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

## Persistent Volumes - Azure Disks
```
A PersistentVolume (PV) is a piece of storage in the cluster that has been provisioned by an administrator. It is a resource in the
cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual
pod that uses the PV. This API object captures the details of the implementation of the storage, be that NFS, iSCSI,
or a cloud-provider-specific storage system.

A PersistentVolumeClaim (PVC) is a request for storage by a user. It is similar to a pod. Pods consume node resources and PVCs consume
PV resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes
(e.g., can be mounted once read/write or many times read-only).
```
```
https://kubernetes.io/docs/concepts/storage/persistent-volumes/
https://docs.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv
https://docs.microsoft.com/en-us/azure/aks/azure-files-dynamic-pv
```
*Disk sizes upto 1 TB are supported, however be aware that bot every vm size supports 1TB disk sizes

## Persistent Volumes - Azure Files
```
Will add in exampple.
```
https://docs.microsoft.com/en-us/azure/aks/azure-files-dynamic-pv

## Deploy virtual-kubelet
* Azure Container Instance is not available at location "centralus". The available locations are "westus,eastus,westeurope,southeastasia"
```
$ az aks install-connector --name akscluster --resource-group demorg --connector-name myaciconnector --os-type both
```

## Upgading virtual-kubelet
```
$ az aks upgrade-connector --name orange-aks --resource-group orange-aks-rg --connector-name myaciconnector
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
$ az aks use-dev-spaces -g <rg> -n <name>
```
### Look at code in current directory and create a Dockerfile and helm chart
```
$ azds prep --public
$ azds up
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
$ azds space list
$ azds space select -n lisa
Hit F5
```

## Kubernetes Cronjobs
* k8s-cron-jobs required k8s 1.8 or higher https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
```

$ wget https://raw.githubusercontent.com/kubernetes/website/master/docs/concepts/workloads/controllers/cronjob.yaml
$ kubectl create -f ./cronjob.yaml
$ kubectl get cronjob
$ cronoutput=$(kubectl get pods --selector=job-name=hello-4111706356 --output=jsonpath={.items..metadata.name})
$ echo $cronoutput
# View output from cron
$ kubectl logs $cronoutput
$ kubectl delete cronjob hello
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
1.10.3               None available
1.9.6                1.10.3
1.9.2                1.9.6, 1.10.3
1.9.1                1.9.2, 1.9.6, 1.10.3
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
$ az aks upgrade -n $CLUSTERNAME --resource-group $RG --kubernetes-version 1.10.3 --yes
```

## metrics-server
```
Heapster will be deprecated, and will start to be removed in 1.11 
metrics-server is not automatically deployed in AKS.
It can be deployed with manifests.
```
* https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/metrics-server

## Procedure to reboot VM's within the agent pool
```
kubectl get nodes
# Prevent new pods from being scheduled onto node (cordon)
kubectl cordon <NODE_NAME>
# Drain - Gracefully terminate all pods on the node while marking the node as unschedulable:
# If your daemonsets are non-critical pods such as monitoring agents then ignore-daemonsets
kubectl drain <NODE_NAME> --ignore-daemonsets --force

# Check that SchedulingDisabled is set
$ kubectl get nodes
NAME                       STATUS                     ROLES     AGE       VERSION
aks-agentpool-75595413-0   Ready,SchedulingDisabled   agent     3d        v1.9.6
aks-agentpool-75595413-2   Ready                      agent     3d        v1.9.6

# Check no pods running on NODE_NAME snd ensure that the pods are up and running on the new pool
$ kubectl get pods -o wide

$ az vm restart --resource-group MC_orange-aks-rg_orange-aks_centralus -n aks-agentpool-75595413-0
$ kubectl uncordon <NODE_NAME>
$ kubectl get nodes - o wide
```

## Remove your cluster cleanly
```
$ az aks delete --resource-group $RG --name ${CLUSTERNAME} --yes
$ az group delete --name $CLUSTERNAME --no-wait --yes
```

## Collecting logs for troubleshooting

Run these commands

```
$ kubectl cluster-info dump
$ kubectl cluster-info dump --all-namespaces --output-directory=$PWD/cluster-state-2018-06-13
$ tree cluster-state-2018-06-13

$ kubectl get events
```

## RBAC Troubleshooting
```
To determine what authorization-mode setting has been configured in order to see if RBAC has been enabled or not when your cluster was deployed, you need to SSH into a VM in the agent-pool and look at the options for the kubelet daemon.

However, I cannot find a method to query the authorization-mode setting within kube-system or any namespace.
If anybody finds out if the argv options are stored there, please do let me know, as that’ll be much easier.

Here are a list of all authorization-mode options when kubelet and kube-apiserver are run.
https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/

--authorization-mode string     Default: "AlwaysAllow"
	Ordered list of plug-ins to do authorization on secure port. Comma-delimited list of: AlwaysAllow,AlwaysDeny,ABAC,Webhook,RBAC,Node.

1.
Follow instructions to be able to SSH into your VM’s within the agent pool.
https://docs.microsoft.com/en-us/azure/aks/aks-ssh

2.
root@aks-agentpool-45595413-0:~# ps auxwwwwwww | grep "/usr/local/bin/[k]ubelet"
root       1525  3.7  3.0 795136 105436 ?       Ssl  Jun02 1359:39 /usr/local/bin/kubelet --enable-server --node-labels=kubernetes.io/role=agent,agentpool=agentpool,storageprofile=managed,storagetier=Premium_LRS,kubernetes.azure.com/cluster=MC_daz-aks-rg_daz-aks_centralus --v=2 --volume-plugin-dir=/etc/kubernetes/volumeplugins --address=0.0.0.0 --allow-privileged=true --authorization-mode=Webhook --azure-container-registry-config=/etc/kubernetes/azure.json --cadvisor-port=0 --cgroups-per-qos=true --cloud-config=/etc/kubernetes/azure.json --cloud-provider=azure --cluster-dns=10.0.0.10 --cluster-domain=cluster.local --enforce-node-allocatable=pods --event-qps=0 --eviction-hard=memory.available<100Mi,nodefs.available<10%,nodefs.inodesFree<5% --feature-gates=Accelerators=true --image-gc-high-threshold=85 --image-gc-low-threshold=80 --keep-terminated-pod-volumes=false --kubeconfig=/var/lib/kubelet/kubeconfig --max-pods=110 --network-plugin=kubenet --node-status-update-frequency=10s --non-masquerade-cidr=10.244.0.0/16 --pod-infra-container-image=k8s-gcrio.azureedge.net/pause-amd64:3.1 --pod-manifest-path=/etc/kubernetes/manifests

3.In conclusion, this AKS Kubernetes 1.9.6 cluster which I deployed, is’nt running in RBAC enabled mode.
To use RBAC, I need to re-deploy.
```

## Random commands
```
# Increase verbosity
$ kubectl delete -f mpich.yml -v=9

# Selecting a pod, by the label
$ kubectl get pods --selector app=samples-tf-mnist-demo --show-all

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

# Testing Service Discovery using DNS (Not Environment variables)
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

# View details of a deployment
$ kubectl describe deployments acs-helloworld-idle-dachshund

# Scale a deployment to 5 replicas
$ kubectl scale deployment/azure-vote-front --replicas=5

$ kubectl cluster-info dump

$ kubectl explain pods

$ kubectl get service --watch --show-labels

# Run a shell on a VM within the agent pool, to troubeshoot from inside out
$ alias kshell='kubectl run -it shell --image giantswarm/tiny-tools --restart Never --rm -- sh'
“--restart Never” ensures that only a pod resource is created (instead of a deployment, replicaset and pod)
“--rm” ensures the pod is deleted when you exit the shell

# Decode Kubernetes secrets
https://github.com/ashleyschuett/kubernetes-secret-decode

# Get all pod names under service / endpoint
$ kubectl get ep aks-helloworld -n default -o jsonpath='{range .subsets[*].addresses[*]}{.targetRef.name}{"\n"}{end}'
acs-helloworld-illocutionary-angelfish-95974fb95-s44kz

# Get not tainted node(s)
$ kubectl get nodes -o go-template='{{range .items}}{{if not .spec.taints}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'
aks-agentpool-85595413-0
aks-agentpool-85595413-2

$ sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
NAMES               IMAGE               STATUS
sonic               dazdaz/sonic        Up 2 weeks

$ kubectl get all --all-namespaces -l co=fabrikam

# Show JSON paths to query
kubectl proxy &
curl -O 127.0.0.1:8001/swagger.json
cat swagger.json | jq '.paths | keys[]'

View k8s agent config
curl -O http://127.0.0.1:8001/apis/apps/v1/controllerrevisions

# Re-attach to a pod
$ kubectl attach aks-ssh-7b5b5856cd-58wwq -c aks-ssh -i -t

$ Launch a pod runing busybox
$ kubectl exec -it busybox-3-c8f969bdd-5xj8b -n default -- sh
/ # nslookup bing.com 168.63.129.16

# Quickest demo of AKS
kubectl run mynginx --image nginxdemos/hello --port=80 --replicas=3
kubectl expose deployments mynginx --port=80 --type=LoadBalancer
kubectl scale --replicas=5 deployment/mynginx

# Viewing logs
kubectl logs -f deploy/addon-http-application-routing-external-dns -n kube-system
```

Wildcard Certs - Getting, Setting up
https://www.youtube.com/watch?v=JNbvEl52dd4

Ingress - NGINX, TLS
https://www.youtube.com/watch?v=U9_A5B9x4SY

Ingress controller config on k8s.
https://blogs.technet.microsoft.com/livedevopsinjapan/2017/02/28/configure-nginx-ingress-controller-for-tls-termination-on-kubernetes-on-azure-2/

AKS Docs
https://docs.microsoft.com/en-us/azure/aks/

AKS Volume Drivers
https://github.com/Azure/kubernetes-volume-drivers

Azure File mounting from K8s
https://github.com/andyzhangx/demo/blob/master/linux/azurefile/azurefile-mountoptions.md

AKS Networking
https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/aks/networking-overview.md

K8s config samples
https://github.com/yokawasa/kubernetes-config-samples

https://acotten.com/post/kube17-security RBAC Guide
http://kubernetesbyexample.com/
https://kubernetes.feisky.xyz/en/
https://thenewstack.io/taking-kubernetes-api-spin/
https://docs.microsoft.com/en-us/azure/aks/acs-aks-migration Migrating from Azure Container Service (ACS) to Azure Kubernetes Service (AKS)
