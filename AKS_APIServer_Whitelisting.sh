# AKS API Server Whitelisting

# https://mybuild.techcommunity.microsoft.com/sessions/77061?source=sessions#top-anchor
# https://docs.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges
# Deploy pod in cluster, then expose it publically, API server then communicates publicly
# 10 address ranges currently supported

# Configure IPWL
az aks update \
--resource-group $RG \
--name $CLUSTERNAME \
--api-server-authorized-ip-ranges 40.85.180.0/24,40.83.0.0/16

az aks show -g ipwlrg -n ipwlclu
apiServerAuthorizedIpRanges
...[Service - ]
.. [Azure Cloud Shell IP address range]
. [Azure Management VM]

# Remove IPWL
az aks update \
--resource-group $RG \
--name $CLUSTERNAME \
--api-server-authorized-ip-ranges 
''
