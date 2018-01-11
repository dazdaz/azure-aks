# 11th Jan 2018
# Orginal yaml here, some minor modifications to display how AKS works
# https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough

cat <<EOF>azure-vote.yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: azure-vote-back
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: azure-vote-back
    spec:
      containers:
      - name: azure-vote-back
        image: redis
        ports:
        - containerPort: 6379
          name: redis
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-back
spec:
  ports:
  - port: 6379
  selector:
    app: azure-vote-back
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: azure-vote-front
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: azure-vote-front
    spec:
      containers:
      - name: azure-vote-front
        image: microsoft/azure-vote-front:redis-v1
        ports:
        - containerPort: 80
        env:
        - name: REDIS
          value: "azure-vote-back"
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-front
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: azure-vote-front
EOF

LOCATION=eastus
RG=daz-mngk8s-rg
CLUSTERNAME=daz-mngk8s

# Brief overview of existing AKS cluster
kubectl get nodes
kubectl top node
kubectl create -f azure-vote.yaml
kubectl get service azure-vote-front --watch

# Use web browser to connect to frontend IP on Azure LB and demo app running on k8s

# Show k8s pod config
kubectl get pods -o wide
# Scale from 2 to 5 pods
kubectl scale deployment/azure-vote-front --replicas=5
kubectl get pods
# Build out a total of 3 Agent VM's to run out containers
az aks scale -g $RG -n ${CLUSTERNAME} --node-count 3
kubectl delete deployment azure-vote-front
kubectl delete deployment azure-vote-back
kubectl delete service azure-vote-front
kubectl delete service azure-vote-back
# az group delete --name $RG--yes --no-wait
