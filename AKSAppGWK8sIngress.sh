# AppGW as Ingress Controller

# https://mybuild.techcommunity.microsoft.com/sessions/77061?source=sessions#top-anchor
# https://github.com/palma21/build2019
# https://github.com/Azure/application-gateway-kubernetes-ingress

# Layer 7 path based routing
# TLS based termination
# Controlled using K8s

az group create -n build-demo-waf-rg -l westus2 --no-wait

# Subnet for AKS
az network vnet create --resource-group build-demo-waf-rg --name build-demo-waf-demovnet --address-prefixes 10.42.0.0/16 --subnet-name build-demoakssubnet --subnet-prefix 10.42.1.0/24 --no-wait

# Service subnet - shared infras, LB's etc
az network vnet subnet create --resource-group build-demo-waf-rg --vnet-name build-demovnet --name build-demosvcsubnet --address-prefixe 10.42.2.0/24 --no-wait

# VNET for Application Gateway (WAF)
az network vnet subnet create --resource-group build-demo-waf-rg --vnet-name build-demovnet --name build-demoappgwsubnet --address-prefixe 10.42.3.0/24 --no-wait

# Get subnet ID for AKS
VNETID=$(az network vnet show -g $RG --name $VNET_NAME --query id -o tsv)
SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)

# The pods get their IP from Azure CNI
az aks create -g build-demo-waf-rg -n build-demowaf -k 1.13.5 -l westus2 --node-count 2 --generate-ssh-keys --network-plugin azure --network --policy azure --service-cidr 10.41.0.0/16 --dns-service-ip 10.41.0.10 --docker-bridge-address 172.17.0.1/16 --vnet-subnet-id $SUBNETID --service-principal $APPID --client-secret $PASSWORD --no-wait

# IP for WAF (App GW)
az network public-ip create -g build-demo-waf-rg -n build-demoagpublicip -l westus2 --sku Standard --no-wait

az network application-gateway create --name build-demoag --resource-group build-demo-waf-rg --location westus2 --min-capacity 2 --frontend-port 80 --http-settings-cookie-based-affinity Disabled --http-settings-port 80 --http-settings-protocol Http --routing-rule-type Basic --sku WAF_v2 --private-ip-address 10.42.3.12 --public-ip-address build-demoagpublicip --subnet build-demoappgwsubnet --vnet-name build-demovnet --no-wait

helm install --name build-demoag -f agw-helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure

kubectl apply -f build19-web.yaml
kubectl apply -f build19-ingress-web.yaml
build19-worker.yaml

# Show public IP
```
az network public-ip show -g build-waf -n buildagpublicip --query "ipAddress" -o tsv
```
