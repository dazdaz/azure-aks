#### Introducing AKS (managed Kubernetes) and Azure Container Registry improvements
* https://azure.microsoft.com/en-us/blog/introducing-azure-container-service-aks-managed-kubernetes-and-azure-container-registry-geo-replication/

* 12th April 2018
* https://docs.microsoft.com/en-us/azure/aks/ # Docs on AKS
* Kubernetes Version 1.8.11 deployed by default

```
# westus2 / ukwest
LOCATION=centralus
RG=daz-aks-rg
CLUSTERNAME=daz-aks

# While AKS is in preview, creating new clusters requires a feature flag on your subscription.
az provider register -n Microsoft.ContainerService

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
# Standard_D2_v2 Standard_B1ms Standard_DS1_v2
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

## Install helm
```
wget https://kubernetes-helm.storage.googleapis.com/helm-v2.7.2-linux-amd64.tar.gz
sudo tar xvzf helm-v2.7.2-linux-amd64.tar.gz --strip-components=1 -C /usr/local/bin linux-amd64/helm

# Install Tiller (helm server)
helm init --service-account default
```

## Add Azure repo
```
helm repo add azure
helm install azure/wordpress
```

## Deploy Datadog helm chart for monitoring
```
helm install --name dg-release --set datadog.apiKey=1234567890 --set rbac.create=false --set rbac.serviceAccount=false --set kube-state-metrics.rbac.create=false --set kube-state-metrics.rbac.serviceAccount=false stable/datadog
```

## To use and configure HTTP routing, read up here or depoy nginx ingress controller manually
https://docs.microsoft.com/en-us/azure/aks/http-application-routing

## Deploy nginx ingress controller and configure it
```
helm install stable/nginx-ingress
kubectl --namespace default get services -o wide -w flailing-hound-nginx-ingress-controller
```

You can watch the status by running
```kubectl --namespace default get services -o wide -w flailing-hound-nginx-ingress-controller
```

An example Ingress that makes use of the controller:
```
  apiVersion: extensions/v1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
    name: example
    namespace: foo
  spec:
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
        - hosts:
            - www.example.com
          secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

## Deploy virtual-kubelet
```
az aks install-connector --name akscluster --resource-group demorg --connector-name myaciconnector --os-type both
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

## Remove your cluster cleanly
```
# az aks delete --resource-group $RG --name ${CLUSTERNAME} --yes
# az group delete --name $RG --no-wait --yes
```


## Random commands
```
# Increase verbosity
kubectl delete -f mpich.yml -v=9

# Selecting a pod, by the label
kubectl get pods --selector app=samples-tf-mnist-demo --show-all
```

Wildcard Certs - Getting, Setting up
https://www.youtube.com/watch?v=JNbvEl52dd4

Ingress - NGINX, TLS
https://www.youtube.com/watch?v=U9_A5B9x4SY

Ingress controller config on k8s.
https://blogs.technet.microsoft.com/livedevopsinjapan/2017/02/28/configure-nginx-ingress-controller-for-tls-termination-on-kubernetes-on-azure-2/
