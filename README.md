## Azure Kubernetes Service

### Building an AKS cluster with autoScaling
```
az ad sp create-for-rbac --skip-assignment
{
  "appId": "b26615b0-0000-4550-afa8-8888a21b8888",
  "displayName": "azure-cli-2019-01-31-01-37-13",
  "name": "http://azure-cli-2019-01-31-01-37-13",
  "password": "88888888-5555-1111-bbbb-999999999999",
  "tenant": "88888888-86f1-41af-0000-999999999999"
}

export APPID=<appId>
export CLIENTSECRET=<password>
export LOCATION=southeastasia
export CLUSTERNAME=lion-aks
export RGNAME=rg-lion-aks

az group create --name $RGNAME --location $LOCATION

### Standard VM Type (unless changed) is : Standard_D2_v2
az aks create \
--resource-group $RGNAME \
--name $CLUSTERNAME \
--kubernetes-version 1.12.6 \
--generate-ssh-keys
--dns-name-prefix $CLUSTERNAME \
--location $LOCATION \
--enable rbac \
--enable-vmss \
--enable-cluster-autoscaler \
--min-count 1 \
--max-count 3 \
--service-principal $APPID \
--client-secret $CLIENTSECRET \
--enable-addons http_application_routing,monitoring \
--no-wait
```

# New AKS Cluster
```
az aks create --resource-group <RESOURCE_GP> --name <CLUSTER_NAME> --node-count 2 --generate-ssh-keys \
--vnet-subnet-id <SUBNET_ID> --dns-name-prefix <DNS_PREFIX> --aad-server-app-id <AAD_SERVER_ID> --aad-server-app-secret <ADD_SECRET> \
--aad-client-app-id <AAD_CLIENT_ID> --aad-tenant-id <TENANT_ID> --network-plugin azure --network-policy calico \
--kubernetes-version 1.14.0
```

# Creating an AKS cluster with a custom "node resource group", where your AKS VM's etc will sit
```
# Example command:
az aks create -l eastus --name CustomRG --node-resource-group HamBaconSwiss --resource-group coreDNS --generate-ssh-keys
```

### Troubleshooting the cluster-autoscaler
```
kubectl -n kube-system describe configmap cluster-autoscaler-status
kubectl  logs coredns-autoscaler-6fcdb7d64-m6lcr -n kube-system
Also, enable diagnostic logs
```

### Check the newly created cluster
```
az aks list -o table
az aks get-credentials --resource-group $RGNAME --name $CLUSTERNAME --admin
```

### Building an AKS cluster with-out node auto-scaling
```
az aks create \
--resource-group $RGNAME \
--name $CLUSTERNAME \
--kubernetes-version 1.12.6 \
--service-principal $APPID \
--client-secret $CLIENTSECRET \
--generate-ssh-keys \
--location $LOCATION \
--node-count 1 \
--enable-addons http_application_routing,monitoring
```

### Building an AKS cluster with Advanced Networking, without node auto-scaling
```
# If you want to plug your VM's into an existing VNet, then something like this, uses Azure CNI (azure network plugin)
az aks create --name aks-cluster \
--resource-group aks \
--enable-addons monitoring \
--network-plugin azure \
--max-pods 1000 \
--service-cidr 10.0.0.0/16 \
--dns-service-ip 10.0.0.10 \
--docker-bridge-address 172.17.0.1/16 \
--vnet-subnet-id /subscriptions/{SUBSCRIPTION ID}/resourceGroups/{RESOURCE GROUP NAME}/providers/Microsoft.Network/virtualNetworks/{VIRTUAL NETWORK NAME}/subnets/{SUBNET NAME}

# You can deploy AKS without RBAC, by using the flag "--rbac=false"
```

# Multple Node Pools
* https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools
```
az extension add --name aks-preview
az feature register --name MultiAgentpoolPreview --namespace Microsoft.ContainerService
az feature register --name VMSSPreview --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerService

# Create a resource group in East US
az group create --name myResourceGroup --location eastus

# Create a basic single-node AKS cluster
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --enable-vmss \
    --node-count 1 \
    --generate-ssh-keys \
    --kubernetes-version 1.12.6

# Add a node pool
    az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name gpunodepool \
    --node-count 1 \
    --node-vm-size Standard_NC6 \
    --no-wait

# Set the taint on the nodepool
kubectl taint node aks-gpunodepool-28993262-vmss000000 sku=gpu:NoSchedule

# Upgrade a node pool
az aks nodepool upgrade \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --kubernetes-version 1.12.7 \
    --no-wait
az aks nodepool list --resource-group myResourceGroup --cluster-name myAKSCluster -o table

# Scale a node pool
az aks nodepool scale \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 5 \
    --no-wait

# Delete a node pool
az aks nodepool delete -g myResourceGroup --cluster-name myAKSCluster --name mynodepool --no-wait
```

### Troubleshooting an AKS deployment
```
aks create --debug ...
```

## Install kubectl

Chose from one of the following

### Method 1 (Ubuntu|RHEL)

```
$ sudo az aks install-cli
Or:
# Install kubectl which works with K8s 1.7.7
$ sudo az aks install-cli --client-version 1.7.7
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
az account set --subscription <subID>
az aks install-cli --install-location c:\apps\kubectl.exe
az aks get-credentials --name k8s-aks --resource-group k8s-aks-rg
```

## Configure K8s Dashboard, if your using RBAC
```
$ kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
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

## Helm Overview
* Helm is the recommended way to deploy your applications on a Kubernetes cluster
* This is the preferred method to deploy your applications over "kubectl apply -f <manifest>"
* Helm allows you to package, upgrade and rollback the application.

```
helm create mychart
Chart.yaml
values.yaml
templates/ deployment.yaml
         / service.yaml
```

## Install helm - Method 1 - Automatically download latest version
```
wget https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
chmod a+x get
./get
helm init

# You can also specify a specific version
./get -v 2.7.2
```

## Install helm - Method 2 - Manual - Download a specific version for Linux
* We give tiller (helm server), cluster-admin priviledges
* https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/aks/kubernetes-helm.md
```
wget https://kubernetes-helm.storage.googleapis.com/helm-v2.7.2-linux-amd64.tar.gz
sudo tar xvzf helm-v2.7.2-linux-amd64.tar.gz --strip-components=1 -C /usr/local/bin linux-amd64/helm
```

```
cat > helm-rbac.yaml <<!EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF
```

```
$ kubectl apply -f helm-rbac.yaml

# Install Tiller (helm server)
$ helm init --service-account tiller --upgrade
$ kubectl get pods -n kube-system | grep tiller

# Test an installation via helm, to ensure that it's working
# Installing and removing a package on K8s 1.9.6 has been a workaround
$ helm install stable/locust
$ helm delete vigilant-hound
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

### Give AKS permissions to pull images from ACR
* 2 Methods
** Grant AKS-generated Service Principal access to ACR (assumes use of AKS and ACR)
** Create a Kubernetes Secret

** Grant AKS-generated Service Principal access to ACR (assumes use of AKS and ACR)
```
AKS_RESOURCE_GROUP=myAKSResourceGroup
AKS_CLUSTER_NAME=myAKSCluster
ACR_RESOURCE_GROUP=myACRResourceGroup
ACR_NAME=myACRRegistry

# Get the id of the service principal configured for AKS
CLIENT_ID=$(az aks show --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)

# Get the ACR registry resource id
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP --query "id" --output tsv)

# Create role assignment
az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID
```

## Deploy Datadog helm chart for monitoring
```
$ helm install --name dg-release --set datadog.apiKey=1234567890 --set rbac.create=false --set rbac.serviceAccount=false --set kube-state-metrics.rbac.create=false --set kube-state-metrics.rbac.serviceAccount=false stable/datadog
```

** Create a Kubernetes Secret
```
kubectl create secret docker-registry acr-auth --docker-server <acr-login-server> --docker-username <service-principal-ID> --docker-password <service-principal-password> --docker-email <email-address>

spec:
  imagePullSecrets:
  - name: acr-auth
  containers:
```

## Helm management
```
helm upgrade --set image.tag=v0.0.2,mariadb.db.password=secret123 <CHART-NAME> .
helm history <CHART-NAME>
REVISION  UPDATED   STATUS      CHART           DESCRIPTION
1         Tue       SUPERSEDED  demo-app-0.0.1  Install complete
2         Wed       DEPLOYED    demo-app-0.0.1  Upgrade complete
helm rollback <CHART-NAME> 1
```

## Setting up a helm repository
* To be added
```
helm repo add mycharts location
helm package chart
helm push filename chart
helm search chart
```

# Kubernetes Reboot Daemon
* https://docs.microsoft.com/en-us/azure/aks/node-updates-kured
```
helm install stable/kured
## Use helm above to deploy kured
## kubectl apply -f https://github.com/weaveworks/kured/releases/download/1.1.0/kured-1.1.0.yaml
```

# AKS Node Pools
```
# View nodepool config:
az aks nodepool list --cluster-name multiplenodepooldemo -g build2019-aks-demo -o table
VirtualMachineScaleSets 1 30 nodepool1 1.13.5 100 Linux Sucessed build-demo Standard_DS2_v2
VirtualMachineScaleSets 1 30 nodepoolgpu 1.13.5 100 Linux Sucessed build-demo Standard_NC6
VirtualMachineScaleSets 1 30 npwin 1.13.5 100 Windows Sucessed build-demo Standard_D2s_v3

# Scale VM's within a nodepool
az aks nodepool scale --cluster-name multiplenodepooldemo -g build2019-aks-demo -n nodepoolgpu --node-count 2
```

# spotify-docker-gc
```
wget https://raw.githubusercontent.com/helm/charts/master/stable/spotify-docker-gc/values.yaml
helm install --name docker-gc -f values.yaml stable/spotify-docker-gc --namespace kube-system
Error: release docker-gc failed: namespaces "kube-system" is forbidden: User "system:serviceaccount:kube-system:default" cannot get namespaces in the namespace "kube-system"
```

# Storage / Azure Dynamic Disk Provisioning
```
$ kubectl get sc
NAME                PROVISIONER                AGE
default (default)   kubernetes.io/azure-disk   39d
managed-premium     kubernetes.io/azure-disk   39d

## Manifest for dynamically carving out an Azure disk - app-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-managed-disk
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 5Gi


* Ensure that the disk is created before you start the pod, which can be done in the helm chart
"helm.sh/hook": pre-install
"helm.sh/hook-weight": "-5"
"helm.sh/hook-delete-policy": hook-succeeded


## Manfest for mounting the disk - webapp-deploy.yaml
kind: Pod
apiVersion: v1
metadata:
 name: mypod
spec:
 containers:
  name: myfrontend
  image: nginx
  volumeMounts:
   - mountPath: "/mnt/azure"
     - name: volume
volumes:
  - name: volume
    persistentVolumeClaim:
      claimName: azure-managed-disk
```

## Static Storage in AKS - Azure Disk
* Not intended for new workloads, good for data migration, ie datadisk mounted in a VM, moving to K8s
```
az disk create --resource-group MC_myResourceGroup_myAKSCluster_southeastasia --name myAKSDisk --size-gb 20 --query id --output tsv

/subscriptions/<subscriptionID>/resourceGroupsMC_myAKSCluster_myAKSCluster_southeastasia/providers/Microsoft.Compute/disks/myAKSDisk

kind: Pod
apiVersion: v1
metadata:
 name: azue-disk-pod
spec:
 containers:
  - image: microsoft/sample-aks-helloworld
  name: azure
  volumeMounts:
    -name: azure
    mountPath: /mnt/azure
  volumes:
       - name: azure
       azureDisk:
         kind: Managed
         diskName: myAKSDisk
         diskURI: /subscriptions/<subscriptionID>/resourceGroupsMC_myAKSCluster_myAKSCluster_southeastasia/providers/Microsoft.Compute/disks/myAKSDisk
```

## StatefulSet uses a volumeClaimTemplates directive
* Uses this as a template for all of the pods in the StatefulSet
```
volumeClaimTemplates:
- metadata:
    name: mongo-vol
  spec:
    accessModes: [ "ReadWriteOnce" ]
    storageClassName: managed-premium
    resources:
      requests:
        storage: 1024M
```

## Azure Files
* Not intended to be a replacement for a cluster-filesystem.  Avoid high IO.

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
* If your using resource requests to request a % of CPU for your app, then :
* 75% of resource requests "cpu".  So if 200m (millicores) of CPU, then scale when CPU reaches 150m (millicores)
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

## HPA - Viewing config
```
kubectl get hpa.v2beta1.autoscaling -o yaml
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

## Ingress
* Ingress is a solution which allows inbound connections and is an alternative to the external loadbalancer and nodePorts
* The ingress controller is essentially a loadBalancer within the Kubernetes cluster

## Ingress Controller (HTTP routing) - Method #1
* "HTTP routing" is an AKS deployment option, read URL below to learn more
* This deploys the nginx ingress controller as an addon and configures DNS into the *.<region>aksapp.io domain
* myappa.example.com ->  888326a4-d388-4bb0-bb01-79c4d162a7a7.centralus.aksapp.io
  That means that the cert will need a SN of  appa.example.com, rather than the long name.
* If you use method 2 as the ingress controller, then it will be the same across Kubernetes clusters, regardless of the Hyperscaler
https://docs.microsoft.com/en-us/azure/aks/http-application-routing

```
Get your AKS Ingress URL
az aks show -n <your cluster name> -g <your resource group name> --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName
```

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
* https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/
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

## Demo of ACI bursting form Kubernetes
*https://github.com/Azure-Samples/virtual-kubelet-aci-burst

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

# Configuring RBAC for Azure DevOps Release Pipeline to deploy resource to AKS cluster - granting the read-only permission for group system:serviceaccounts
```
kubectl create clusterrolebinding azure-devops-deploy --clusterrole=view --group=system:serviceaccounts --namespace=xyz
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

## K8s Networking
* 1.AKS does not currently support flannel.
* 2.ACS-Engine does support Flannel in PR2967 https://github.com/Azure/acs-engine/pull/2967
* 3.Tigera Calico coming to Azure Kubernetes Service (AKS) https://www.tigera.io/tigera-calico-coming-to-azure-kubernetes-service-aks/

## Kubernetes Network Policy's
```
kubectl get networkpolicies --all-namespaces
kubectl get networkpolicies default-deny -n policy-demo -o yaml
```

## Changing K8s cluster context
```
$ kubectl config current-context
daz-aks
$ kubectl config delete-cluster daz2-aks
deleted cluster daz2-aks from /home/devans/.kube/config
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

* Define a role and assign users and groups to that role.
* Role (single namespace) and ClusterRole (cluster-wide)
* RoleBinding (single namespace) and ClusterRoleBinding (cluster-wide)
* Roles define a list of actions that can be performed over the resources or verbs: GET, WATCH, LIST, CREATE, UPDATE, PATCH, DELETE.
* Roles are assigned to ServiceAccounts

$ kubectl api-versions|grep rbac
rbac.authorization.k8s.io/v1
rbac.authorization.k8s.io/v1beta1

$ kubectl get clusterroles
No resources found.

# View cluster-admin clusterrole in yaml format
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

## RBAC Role granting read access to pods and secrets within default namespace
* If you want this across all namespaces, then use ClusterRole instead of Role and remove namespace attribute
```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "secrets"]
  verbs: ["get", "watch", "list"]

# Assign users to the newly created role

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: bob
  apiGroup:rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io

$ kubectl config set-context nigel --cluster=kubernetes.myhost.com --user nigel
```

## RBAC Role granting read/write access to pods within default namespace
* No access to secrets
```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-writer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: ["extensions", "apps"]
  resources: ["deployments"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: write-pods
  namespace: default
subjects:
- kind: User
  name: nigel
  apiGroup:rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io


$ kubectl config use-context nigel
```

## admin-user.yaml
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: "nigel"
- apiGroup: rbac.authorization.k8s.io

kubectl apply -f admin-user.yaml
kubectl config use-context nigel
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
kubectl drain <NODE_NAME> --ignore-daemonsets --grace-period=600
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

## Adding monitoring to an existing cluster
This will automatically create the default Log analytics workspace in the background and deploy the agent to the existing AKS cluster.
There is no pre-requisite in Workspace creation needed.
* https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#enable-container-health-monitoring-for-existing-managed-clusters 
``` 
$ az aks enable-addons -a monitoring -n MyExistingAKSCluster -g MyExistingAKSClusterRG
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

## Kubernetes Secrets
# 1. Storing secrets from text file or private key
```
echo -n "root" > username.txt
echo -n "password" > password.txt
kubectl create secret generic db-user-pass --from-file=username.txt --from-file=password.txt

# A secret can also be a private key or SSH certificate
kubectl create secret generic ssl-certificate --from-file=ssh-privatekey=~/.ssh/id_rsa --ssl-cert-=ssl-cert=mysysslcert.crt
```

# 2. Storing secrets from yaml file and then referncing those secrets via Environment Variables
```
$ kubectl create -f secrets-db.yaml
```

```
$ echo -n "root" | base64
cm9vdA==
$ echo -n "password" | base64
cGFzc3dvcmQ=

apiVersion: v1
kind: Secret
metadata:
 name: db-secret
type: Opaque
data:
 username: cm9vdA==
 password: cGFzc3dvcmQ=
```

```
env:
 - name: SECRET_USERNAME
  valueFrom:
   secretKeyRef:
    name: db-secret
    key: username
 - name: SECRET_PASSWORD
```

# 3. Text files in a pod - uses volumes to be mounted in a container.  Within the volume is a file
```
# secrets will be stored in /etc/creds/db-secrets/username and /etc/creds/db-secrets/password
volumeMounts:
- name: credvolume
  mountPath: /etc/creds
  readOnly: true
volumes:
- name: credvolume
 secret:
  secretName: db-secrets
```

# 4. An external vault application

## ConfigMaps
```
ConfigMap key-value pairs can be read by the app using :
- 1. Environment variables
- 2. Container commandline arguments
- 3. Using volumes (can be a full configuration file)

1. Environment Variables
env:
  -name: DRIVER
   valueFrom:
    configMapKeyRef:
     name: app-config
     key: driver
  - name: DATABASE

2. Configmap direct
# Upload nginx.conf configuration file into a configmap
$ kubectl create configmap nginx-config --from-file=nginx-reverseproxy.conf
$ kubectl get configmap nginx-config -o yaml

3. Using volumes
volumeMounts:
 - name: config-volume
   mountPath: /etc/config
volumes:
 - name: config-volume
   configMap:
    name: app-config
```

## Troubleshooting
```
Pod State
5 different states
PodScheduled - the pod has been scheduled to a node
Ready - the pod can serve requests and is going to be added to matching services
Initialized - the initialization containers have been started successfully
Unschedulable - the Pod can't be scheduled (for example due to resource constraints)
ContainersReady - all containers in the Pod are ready

# To see exceeded quota messages
kubectl describe rs/hello-world-deployment-235680 --namespace=myspace

$ kubectl cluster-info dump

# Show issues
kubectl get events

# Show labels
kubectl get nodes --show-labels

kubectl get nodes --show-labels | sed 's/\//\n/g'
aks-agentpool-20626790-0                                Ready     agent     10d       v1.10.6   agentpool=agentpool,beta.kubernetes.io
arch=amd64,beta.kubernetes.io
instance-type=Standard_DS1_v2,beta.kubernetes.io
os=linux,failure-domain.beta.kubernetes.io
region=southeastasia,failure-domain.beta.kubernetes.io
zone=1,kubernetes.azure.com
cluster=MC_daz-aks-rg_dazaks_southeastasia,kubernetes.io
hostname=aks-agentpool-20626790-0,kubernetes.io
role=agent,storageprofile=managed,storagetier=Premium_LRS
```

## Troubleshooting, ketall is useful to see cluster changes, useful if you have multiple admins or closed eyes
```
https://github.com/corneliusweig/ketall
```

## Kubernetes Performance
```
kubectl top pods --all-namespaces
```

## Random commands
```
# Increase verbosity
$ kubectl delete -f mpich.yml -v=9

# Selecting a pod, by the label
$ kubectl get pods --selector app=samples-tf-mnist-demo --show-all

# Display internal cluster IP addresses
$ kubectl get svc -n=istio-system -o=custom-columns=NAME:.metadata.name,IP:.spec.clusterIP
NAME                       IP
grafana                    10.0.127.232
istio-citadel              10.0.250.0
istio-egressgateway        10.0.29.184
istio-ingressgateway       10.0.224.152
istio-pilot                10.0.94.21
istio-policy               10.0.20.118
istio-sidecar-injector     10.0.233.174
istio-statsd-prom-bridge   10.0.197.58
istio-telemetry            10.0.107.53
jaeger-agent               None
jaeger-collector           10.0.136.179
jaeger-query               10.0.98.154
prometheus                 10.0.216.50
tracing                    10.0.123.141
zipkin                     10.0.42.101

$ kubectl get svc -o=custom-columns=NAME:.metadata.name,IP:.spec.clusterIP
NAME             IP
hellowhale-svc   10.0.234.72
kubernetes       10.0.0.1
nginx-svc        10.0.250.226

# Extract metadata from K8s
$ kubectl get pod dg-release-datadog-hlvxc -o=jsonpath={.status.containerStatuses[].image}
datadog/agent:6.1.2

# View configuration details of a pod, deployment, service etc
$ kubectl get pod dg-release-datadog-hlvxc -o json | jq
<output formatted>

# View events by time sequence
kubectl -n defaults get events --sort-by='{.lastTimestamp}'

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

# Useful command to view details of a K8s Worker node within the agent pool
az vm get-instance-view -g "MC_orange-aks-rg_orange-aks_centralus" -n aks-agentpool-75595413-0 

# View details of a deployment
$ kubectl describe deployments acs-helloworld-idle-dachshund

# Scale a deployment to 5 replicas
$ kubectl scale deployment/azure-vote-front --replicas 5 --namespace dimbulah

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

# Displays just the name of the pods (useful for scripting)
$kubectl --namespace default -o 'jsonpath={.items[*].metadata.name}' get pods

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

# View API version
kubectl get apiservices -o 'jsonpath={range .items[?(@.spec.service.name!="")]}{.metadata.name}{"\n"}{end}'
v1beta1.metrics.k8s.io

# Uses AD to authenticate
kubectl --kubeconfig=aad-kubeconfig get nodes

# Query pods using field selector on labels
kubectl get  po --field-selector=metadata.name==world-*

# Show OMS daemonset
kubectl get ds omsagent --namespace=kube-system
NAME       DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
omsagent   2         2         2         2            2           beta.kubernetes.io/os=linux   77d

# run from laptop, connect to http://localhost:3000
kubectl port-forward <pod> 8080:30030

# show files in contsainer in pod
kubectl exec <pod> -- ls -l

kubectl run -i tty busybox --image=busybox --restart=Never

kubectl attach <pod> -i

kubectl exec -it <pod> -- bash

# Show the status of a container within the pod
$ kubectl get pod datadog-agent-5nbrc -o yaml | grep -A11 containerStatuses
  - containerID: docker://784335aaa1442162860ed33e48e9df37098391afdbf76160a5211b091ddd5d04
    image: datadog/agent:latest
    imageID: docker-pullable://datadog/agent@sha256:713670f9fbb049f6cf9c2f10a083e16273fdd55f7f2bcdcc5c8de4640028bbff
    lastState: {}
    name: datadog-agent
    ready: true
    restartCount: 0
    state:
      running:
        startedAt: 2018-08-05T07:12:31Z

# To see the how much of its quota each node is using we can use this command, with example output for a 3 node cluster:
$ kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo {}; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo'

# Set a default namespace
export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=myspace

# Deploying a container from ACR onto K8s
kubectl run chiodaimage2 --image=bluefields.azurecr.io/test/api2

# Show configuration settings applied to a namespace
$ kubectl describe ns uat
Name:         uat
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Namespace","metadata":{"annotations":{},"name":"uat","namespace":""}}

Status:  Active

No resource quota.

Resource Limits
 Type                   Resource  Min    Max  Default Request  Default Limit  Max Limit/Request Ratio
 ----                   --------  ---    ---  ---------------  -------------  -----------------------
 Container              cpu       200m   1    250m             500m           -
 Container              memory    256Mi  1Gi  256Mi            512Mi          -
 PersistentVolumeClaim  storage   1Gi    5Gi  -                -              -


$ kubectl get nodes -o custom-columns=nodeName:.metadata.name,nodeIP:status.addresses[0].address,routeDestination:.spec.podCIDR
nodeName                                                nodeIP                     routeDestination
aks-agentpool-10926791-0                                aks-agentpool-10926791-0   10.244.4.0/24
aks-agentpool-10926791-2                                10.240.0.6                 10.244.2.0/24
aks-agentpool-10926791-3                                10.240.0.4                 10.244.36.0/24
virtual-kubelet-myaciconnector-linux-southeastasia      10.244.2.53                10.244.242.0/24
virtual-kubelet-myaciconnector-windows-southeastasia    10.244.2.35                10.244.240.0/24
```

# Node labels
* You can give a node either a unique label or the same label, i.e. env=dev to multiple nodes
```
kubectl label nodes node1 hardware=azurea1-sku
kubectl label nodes node2 hardware=azuregpu-sku
kubectl get nodes --show-labels

apiVersion: v1
kind: Pod
metadata:
  name: node.example.com
  labels:
    app: helloworld
spec:
  containers:
  - name: k8s-demo
    image: daz/gpudemo
    ports:
    - containerPort: 3000
 nodeSelector:
  hardware: azuregpu-sku
```
```
kubectl get secret cosmos-db-secret -o yaml
kubectl get secrets cosmos-db-secret -o jsonpath --template '{.data.user}' | base64 -d
```
```
# Get the external Load Balancer IP
kubectl get service hellowhale-svc -o jsonpath='{.status.loadBalancer.ingress[*].ip}'
11.66.100.244
```
```
kubectl logs my-pod --previous
```
```
$ kubectl get pods
NAME                     READY     STATUS    RESTARTS   AGE
nginx-5947c4dd86-94q2x   1/1       Running   0          17d
nginx-5947c4dd86-cm26m   1/1       Running   0          17d
nginx-5947c4dd86-r5n5t   1/1       Running   0          17d

$ kubectl exec nginx-5947c4dd86-94q2x -- printenv
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=nginx-5947c4dd86-94q2x
KUBERNETES_PORT_443_TCP_ADDR=simon-aks-eng-aks-rg-123456-87654321.hcp.southeastasia.azmk8s.io
KUBERNETES_PORT=tcp://simon-aks-eng-aks-rg-123456-87654321.hcp.southeastasia.azmk8s.io:443
KUBERNETES_PORT_443_TCP=tcp://simon-aks-eng-aks-rg-123456-87654321.hcp.southeastasia.azmk8s.io:443
KUBERNETES_SERVICE_HOST=simon-aks-eng-aks-rg-123456-87654321.hcp.southeastasia.azmk8s.io
KUBERNETES_PORT_443_TCP_PORT=443
NGINX_SVC_PORT=tcp://10.0.31.119:80
NGINX_SVC_PORT_80_TCP_PORT=80
NGINX_SVC_PORT_80_TCP_ADDR=10.0.31.119
KUBERNETES_SERVICE_PORT_HTTPS=443
NGINX_SVC_SERVICE_HOST=10.0.31.119
NGINX_SVC_SERVICE_PORT=80
NGINX_SVC_PORT_80_TCP=tcp://10.0.31.119:80
NGINX_SVC_PORT_80_TCP_PROTO=tcp
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
NGINX_VERSION=1.15.8
HOME=/root
```
```
# Excellent command for debugging to better understand the environment
kubectl describe nodes
```
```
# Show component status
$ kubectl get componentstatus
NAME                 STATUS      MESSAGE                                                                                     ERROR
scheduler            Unhealthy   Get http://127.0.0.1:10251/healthz: dial tcp 127.0.0.1:10251: connect: connection refused
controller-manager   Unhealthy   Get http://127.0.0.1:10252/healthz: dial tcp 127.0.0.1:10252: connect: connection refused
etcd-0               Healthy     {"health": "true"}
```

```
# VPA
kubectl describe vpa

Show CPU Requests in millicores
kubectl get pod  -o=custom-columns=NAME:.metadata.name,PHASE:.status.phase,CPU-REQUEST:.spec.containers\[0\].resources.requests.cpu

$ kubectl top nodes
NAME                       CPU(cores)   CPU%      MEMORY(bytes)   MEMORY%
aks-nodepool1-71576875-0   114m         5%        2240Mi          42%

The expression 0.1 is equivalent to the expression 100m, which can be read as “one hundred millicpu”, some people say “one hundred millicores”, which means the same thing.
1 CPU is 1000m (1 thousand milicores)

Meaning of CPU in Kubernetes :
One CPU, in Kubernetes, is equivalent to:
- 1 AWS vCPU
- 1 GCP Core
- 1 Azure vCore
- 1 Hyperthread on a bare-metal Intel processor with Hyperthreading
```

# Howto determine if accelerated networking is enabled on the nodepool VM's
```
$ az aks show --resource-group <myRG> --name funkaks --query "nodeResourceGroup"
"MC_funk-rg_funk_southeastasia"
$ az network nic list --resource-group MC_funk-rg_funk_southeastasia -o table
EnableAcceleratedNetworking    EnableIpForwarding    Location       MacAddress         Name                          Primary    ProvisioningState    ResourceGroup                        ResourceGuid
-----------------------------  --------------------  -------------  -----------------  ----------------------------  ---------  -------------------  -----------------------------------  ------------------------------------
True                           True                  southeastasia  00-0D-3A-99-99-99  aks-nodepool1-81576875-nic-0  True       Succeeded            MC_funk-rg_funk_southeastasia  111e2b48-059c-4c68-4444-aaaf97dadddd
False                          False                 southeastasia  00-0D-3A-AA-AA-AA  jumpvmVMNic                   True       Succeeded            MC_funk-rg_funk_southeastasia  222293c5-e5c4-42b8-aaaa-95499bf4ffff
```

# Kubectl (client) and K8s (server) version
```
$ kubectl version --short
Client Version: v1.11.1
Server Version: v1.13.5
```

# Display OS and architecture of nodes
```
kubectl get node -o="custom-columns=NAME:.metadata.name,OS:.status.nodeInfo.operatingSystem,ARCH:.status.nodeInfo.architecture"
NAME                       OS      ARCH
aks-nodepool1-19880533-0   linux   amd64
```

# Listing the IPs of nodes in a windows nodepool
```
kubectl get no -l beta.kubernetes.io/os=windows -o json | jq '.items[].status.addresses[] | select(.type=="ExternalIP") | .address'
```

# Deploying tiller specifically onto a Linux VM, in a K8s cluster with both Linux/Windows nodes
```
helm init --node-selectors "beta.kubernetes.io/os=linux" --tiller-namespace wad --service-account wad-user --upgrade
```

# Using "kubectl apply dry-run with verbosity ..."
```
kubectl apply --dry-run -f ./deployment-nginx-acr-dockerhub.yaml --v=10 >& out
```

# Tricks when using istio...
```
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
```

== Documentation / Further Info==

* https://azure.microsoft.com/en-us/updates/?status=indevelopment&product=kubernetes-service
* https://docs.microsoft.com/en-us/azure/aks/configure-advanced-networking#plan-ip-addressing-for-your-cluster
* https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster
* https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough#create-aks-cluster 
* https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
* https://docs.microsoft.com/en-us/azure/aks/update-credentials The SPN credential update
* https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler VMSS / Cluster AutoScaler
* https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal AKS SP

Pre-Create the Service principal with least/minimum amount of required permissions from @James Sturtevant
https://github.com/jsturtevant/aks-examples/tree/master/least-privileged-sp

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

External-DNS
https://github.com/kubernetes-incubator/external-dns
https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/azure.md

Helm
https://medium.com/virtuslab/think-twice-before-using-helm-25fbb18bc822 Critical view of helm - mostly accurate

Kubernetes-the-hard-way-on-azure
https://github.com/ivanfioravanti/kubernetes-the-hard-way-on-azure

Long list of useful k8s links
https://github.com/ramitsurana/awesome-kubernetes/blob/master/README.md

AKS Roadmap
https://azure.microsoft.com/en-us/updates/?status=indevelopment&product=kubernetes-service 

K8s Deployment Types ie Canary, Blue/Green
https://www.cncf.io/wp-content/uploads/2018/03/CNCF-Presentation-Template-K8s-Deployment.pdf
https://github.com/ContainerSolutions/k8s-deployment-strategies
