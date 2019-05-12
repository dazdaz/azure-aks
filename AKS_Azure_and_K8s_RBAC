# Kubernetes RBAC and Azure RBAC Roles

# https://mybuild.techcommunity.microsoft.com/sessions/77061?source=sessions#top-anchor
# https://github.com/palma21/build2019/blob/master/AAD-RBAC-demo.sh

* 2 Azure Roles which define the access to the cluster
- Azure Kubernetes Service Cluster Admin Role
- Azure Kubernetes Service Cluster User Role

OPSSRE_ID=$(az ad group create --display-name opssre --mail-nickname opssre --query objectId -o tsv)
APPDEV_ID=$(az ad group create --display-name appdev --mail-nickname appdev --query objectId -o tsv)

az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster User Role" --scope $AKS_ID
az role assignment create --assignee $OPSSRE_ID --role "Azure Kubernetes Service Cluster User Role" --scope $AKS_ID

az aks get-credentials --resource-group build-AAD-rg --name build-AAD --admin

kubectl crate ns dev
kubectl apply -f https://github.com/palma21/build2019/blob/master/roles/role-dev-namespace.yaml

# RoleBinding to an AD Group
kubectl apply -f https://github.com/palma21/build2019/blob/master/roles/rolebinding-dev-namespace.yaml

# AKS queries AD, tell me users in this Group, and allows actions

# Binding for Ops
# Maps opssre to K8s RBAC ClusterAdmin role, not AD Group

kubectl apply -f https://github.com/palma21/build2019/blob/master/roles/rolebinding-opssre.yaml

# Add user to AD group
az ad group member add --group appdev --member-id $userID

# user then downloads their credentials to access the AD Group
az aks get-credentials --resource-group build-AAD-rg --name build-AAD --overwrite-existing

# test deploying a pod, which will request 2FA

kubectl run --generator=run-pod/v1 nginx-dev --image=nginx -n dev
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code B7382EQW to authenticate.

# To add user to admin group
az ad group member add --group opssre --member-id $userID
