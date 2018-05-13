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

## Remove your cluster cleanly
```
# az aks delete --resource-group $RG --name ${CLUSTERNAME} --yes
# az group delete --name $RG --no-wait --yes
```

Wildcard Certs - Getting, Setting up
https://www.youtube.com/watch?v=JNbvEl52dd4

Ingress - NGINX, TLS
https://www.youtube.com/watch?v=U9_A5B9x4SY

Ingress controller config on k8s.
https://blogs.technet.microsoft.com/livedevopsinjapan/2017/02/28/configure-nginx-ingress-controller-for-tls-termination-on-kubernetes-on-azure-2/
