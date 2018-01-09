<pre>
# Introducing AKS (managed Kubernetes) and Azure Container Registry improvements
# https://azure.microsoft.com/en-us/blog/introducing-azure-container-service-aks-managed-kubernetes-and-azure-container-registry-geo-replication/

# 29th Oct 2017
# https://docs.microsoft.com/en-us/azure/aks/ # Docs on AKS
# Kubernetes Version 1.7.7 deployed by default

# westus2 / ukwest
LOCATION=eastus
RG=daz-mngk8s-rg
CLUSTERNAME=daz-mngk8s

# While AKS is in preview, creating new clusters requires a feature flag on your subscription.
az provider register -n Microsoft.ContainerService

az group create --name $RG --location $LOCATION
az aks create --resource-group $RG --name ${CLUSTERNAME} --node-count 2 -s Standard_D2_v2
# Download and install kubectl
sudo az aks install-cli
kubectl get nodes
# Downloads and merge credentials into ~/.kube/config
az aks get-credentials -n ${CLUSTERNAME} -g $RG

# Display version and state of Azure Managed k8s cluster
az aks show -g $RG -n ${CLUSTERNAME} -o table

# Build out a total of 3 Agent VM's to run out containers
az aks scale -g $RG -n ${CLUSTERNAME} --node-count 3

# Run 3 pods
kubectl run mynginx --image nginxdemos/hello --port=80 --replicas=3

# Expose the mynginx deployment via the Azure LoadBalancer
kubectl expose deployments mynginx --port=80 --type=LoadBalancer

# Run 5 pods
kubectl scale --replicas=5 deployment/mynginx

# Check what version of Azure Managed k8s is available
az aks get-versions -g $RG -n $CLUSTERNAME -o table

az aks upgrade -g $RG -n $CLUSTERNAME -k 1.8.2
# Check that our nodes have been upgraded to 1.8.2
kubectl get nodes
kubectl version

# Access k8s GUI, setup SSH Tunelling in your SSH Client
kubectl get pods --namespace kube-system | grep kubernetes-dashboard
kubernetes-dashboard-3427906134-9vbjh   1/1       Running   0          49m
kubectl -n kube-system port-forward kubernetes-dashboard-1427906131-8vbjh 9090:9090

# Install reverse proxy, show IP on LoadBalancer
helm init
helm install stable/nginx-ingress
kubectl --namespace default get services -o wide -w flailing-hound-nginx-ingress-controller
NOTES:
The nginx-ingress controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace default get services -o wide -w flailing-hound-nginx-ingress-controller'

An example Ingress that makes use of the controller:

  apiVersion: extensions/v1beta1
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


# k8s-cron-jobs required k8s 1.8 https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
# kubectl run cronjobname --schedule "*/5 * * * *" --restart=OnFailure --image "imagename" -- "command"

# az aks delete --resource-group $RG --name ${CLUSTERNAME} --yes
# az group delete --name $RG --no-wait --yes
</pre>

Wildcard Certs - Getting, Setting up
https://www.youtube.com/watch?v=JNbvEl52dd4

Ingress - NGINX, TLS
https://www.youtube.com/watch?v=U9_A5B9x4SY

Ingress controller config on k8s.
https://blogs.technet.microsoft.com/livedevopsinjapan/2017/02/28/configure-nginx-ingress-controller-for-tls-termination-on-kubernetes-on-azure-2/
