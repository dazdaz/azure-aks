# Azure Policy for AKS

# https://mybuild.techcommunity.microsoft.com/sessions/77061?source=sessions#top-anchor
# https://azure.microsoft.com/en-us/blog/partnering-with-the-community-to-make-kubernetes-easier/

az aks enable-addons --addons azure-policy --name build-policy --resource-group build-policy-rg

# Then goto portal.azure.com and select Aure Policy / Authoring / Assigments and select "Assign policy"

# Search: whitelist

Allowed container images regex:
^phewacr.azurecio.io/.+$

kubectl apply -f test-pod.yaml

Error from server: Denied admission webhook gatekeeper.microsoft.com denied the request: The operation was disallowed b policy 'azurepolicy--container-imagewhitelist'

Error details: container image \centos\ has not been whitelisted.

# You can deploy a pod from your registry, which is allowed

kubectl run --generator=run-pod/v1 jpalma-hello --image=jpalma.azurecr.io/helloworld:v1
