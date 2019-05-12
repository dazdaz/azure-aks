# Network Policy with Calico and IP Whitelisting

# Filter East/West
# Segment network traffic
# Control how traffic can flow between pods

# https://mybuild.techcommunity.microsoft.com/sessions/77061?source=sessions#top-anchor
# https://github.com/palma21/build2019

az aks create --resource-group --name --node-count 1 --generate-ssh-keys --network-plugin azure --service-cidr 10.0.0.0/16 --dns-service-ip 10.0.0.0 --docker-bridge-address 172.17.0.1/16 --vnet-subnet-id <> --service-principal <> --client-secret <> --network-policy calico

az aks get-credentials -g nprg -n npclu
kubectl create ns advanced-policy-demo
kubectl run --namespace=advanced-policy-demo nginx --replicas=2 --image=nginx
kubectl expose --namespace=advanced-policy-demo deployment nginx --port=80
kubectl run --namespace=advanced-policy-demo access --rm -ti --image busybox /bin/bash
wget -q --timeout=5 nginx -O -

# Network Policy to deny all ingress traffic within advanced-policy-demo namespace
kubectl create -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: advanced-policy-demo
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
EOF

wget -q --timeout=5 nginx -O -
wget: download timed out

# Network Policy to allow ingress traffic to nginx pod wihtin advanced-policy-demo namespace
kubectl create -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: access-nginx
  namespace: advanced-policy-demo
spec:
  podSelector:
    matchLabels:
      run: nginx
  ingress:
    - from:
      - podSelector:
          matchLabels: {}
EOF

wget -q --timeout=5 nginx -O -


# Network Policy to deny all egress traffic out of the advanced-policy-demo namespace
kubectl create -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: advanced-policy-demo
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Egress
EOF

# demo transaction of all traffic
nslookup nginx

kubectl get networkpolicy --all-namespaces

NAME                POD-SELECTOR
access-nginx        run=nginx
default-deny-egress <none>
default-deny-ingress <none>
