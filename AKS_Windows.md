* Build an AKS Cluster, Add a Windows Node Pool and run a Windows containers


# Create a Service Principal, Resource Group
```console
#!/usr/bin/env bash

az ad sp create-for-rbac --skip-assignment

export APPID=<AppID>
export CLIENTSECRET=<Password>
export LOCATION=southeastasia
export CLUSTERNAME=k8s
export RGNAME=k8s-rg

az group create --name $RGNAME --location $LOCATION
```

### Install the aks-preview extension
```console
az extension add --name aks-preview
az extension update -n aks-preview
```

### Enable MultiAgentpoolPreview Feature Flag
```console
az feature register --name MultiAgentpoolPreview --namespace Microsoft.ContainerService
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/MultiAgentpoolPreview')].{Name:name,State:properties.state}"
```

### Enable VMSSPreview Feature Flag
```console
az feature register --name VMSSPreview --namespace Microsoft.ContainerService
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/VMSSPreview')].{Name:name,State:properties.state}"
```

### Enable WindowsPreview Feature Flag
```console
az feature register --name WindowsPreview --namespace Microsoft.ContainerService
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/WindowsPreview')].{Name:name,State:properties.state}"
```

### When feature is registered, then propogate changes
```console
az provider register --namespace Microsoft.ContainerService
```

### Deploy K8s
```console
az aks create \
    --resource-group $RGNAME  \
    --name $CLUSTERNAME \
    --dns-name-prefix $CLUSTERNAME \
    --service-principal $APPID \
    --client-secret $CLIENTSECRET \
    --enable-vmss \
    --node-count 1 \
    --generate-ssh-keys \
    --windows-admin-password "G&68a#@190" \
    --windows-admin-username azureuser \
    --network-plugin azure \
    --network-policy calico \
    --kubernetes-version 1.14.0 \
    --enable-addons monitoring \
    --no-wait

az aks list -o table

az aks nodepool list --resource-group $RGNAME --cluster-name $CLUSTERNAME -o table

### Download private key
az aks get-credentials -n $CLUSTERNAME -g $RGNAME --admin
```

### Add a node pool
```console
az aks nodepool list --resource-group $RGNAME --cluster-name $CLUSTERNAME -o table
az aks nodepool add \
    --resource-group $RGNAME \
    --cluster-name $CLUSTERNAME \
    --os-type Windows \
    --name wnpool \
    --node-count 1 \
    --kubernetes-version 1.14.0 \
    --no-wait
```

### Check status of node pool
```console
az aks nodepool list --resource-group $RGNAME --cluster-name $CLUSTERNAME -o table
```

### Upgrade to 2 Windows Nodes
```console
az aks nodepool scale \
    --resource-group $RGNAME \
    --cluster-name $CLUSTERNAME \
    --name wnpool \
    --node-count 2 \
    --no-wait
```

### Deploy a Windows Container using kubectl onto a Windows node
```console
kubectl get nodes --show-labels
kubectl describe node aksnpwin000000
kubectl run sc --image mcr.microsoft.com/dotnet/framework/samples:aspnetapp --restart=Never --replicas=1 --overrides='{"apiVersion": "v1", "spec": {"nodeSelector": { "beta.kubernetes.io/os": "windows" }}}'
kubectl get pods,svc
kubectl get pod sc -o yaml
kubectl exec -it sc -- powershell.exe
$PSVersionTable
Get-Service
Get-Process
Get-NetTCPConnection -State Listen
Get-EventLog -LogName Application -Source Docker -After (Get-Date).AddMinutes(-5) | Sort-Object Time

kubectl delete deployments sc
az aks nodepool delete -g $RGNAME --cluster-name $CLUSTERNAME --name gpunodepool --no-wait
```

### Further reading :
* https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools
* https://docs.microsoft.com/en-us/azure/aks/windows-container-cli
