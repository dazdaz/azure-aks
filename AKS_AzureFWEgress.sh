# Azure FW - Filter egress traffic from AKS

# Restricting north/south traffic
# https://mybuild.techcommunity.microsoft.com/sessions/77061?source=sessions#top-anchor
# https://github.com/palma21/build2019

az group create --name build-egress-rg --location westus2

# AKS Subnet
az network vnet create --resource-group build-egress-rg --name build-egressvnet --address-prefixes 10.42.0.0/16 --subnet-name build-egressakssubnet --subnet-prefix 10.42.1.0/24 --no-wait

# Azure FW Subnet
az network vnet subnet create --resource-group build-egress-rg --vnet-name build-egressvnet --name AzureFirewallSubnet --address-prefix 10.42.3.0/24 --no-wait
az network public-ip create -g build-egress-rg -n build-egressfwpublicip -l westus2 --sku Standard

az network firewall create -g build-egress-rg -b build-egressfw -l westus2

# Associate public IP with the fw
az network firewall ip-config create -g build-egress-rg -f build-egressfw -n build-egressfwconfig --public-ip-address build-egressfwpublicip --vnet-name build-egressvnet

# Grab the private IP of the fw
# Overlay cluster+nodepool to firewall, then to public IP
FWPRIVATE_IP=$(az network firewall show -g $RG -n $FWNAME --query "ipConfigurations[0].privateIpAddress" -o tsv)

# Route that defines the hop from private IP to the fw
az network route-table create -g build-egress-rg --name build-egressfwrt

# Hop from cluster to private IP of the firewall
# az network route-table route create -g build-egress-rg --name build-egressfwrn --route-table-name build-egressfwrt --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FWPRIVATE_IP --subscription $SUBID

# Open ports 443,9000
az network firewall network-rule create -g build-egress-rg -f build-egressfw --collection-name 'aksfwnr' -n 'netrules' --protocols 'TCP' --source-addresses '*' --destination-addresses '*' --destination-ports 9000 443 --action allow --priority 100

# Allow External URL's
az network firewall application-rule create -g build-egress-rg -f build-egressfw --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --target-fqdns '*.azmk8s.io' 'aksrepos.azurecr.io' '*blob.core.windows.net' '*mcr.microsoft.com' 'login.microsoftonline.com' 'management.azure.com' '*ubuntu.com' --action allow --priority 100

# Update the subnet with the route table
az network vnet subnet update -g build-egress-rg --vnet-name build-egressvnet --name build-egressakssubnet --route-table build-egressfwrt

az aks create -g build-egress-rg -n build-egress -k 1.13.5 -l westus2 --node-count 2 --generate-ssh-keys --network-plugin azure --network-policy azure --service-cidr 10.41.0.0./16 --dns-service-ip 10.41.0.10 --docker-bridge-address 172.17.0.1/16 --vnet-subnet-id $SUBNETID --service-principal $APPID --client-secret $PASSWORD --no-wait

kubectl apply test-pod.yaml
kubectl exec -it centos -- /bin/bash
curl ubuntu.com
# egress blocked
curl chucknorris.com
