### Docs to deploy istio on AKS
* https://docs.microsoft.com/en-us/azure/aks/istio-install

### Deploy Istio 1.2.0 onto AKS 1.14.0
```
# Render Istio resources yaml

kubectl create ns istio-system
./k8s-secret-grafana.sh
./k8s-secret-kiali.sh

git clone https://github.com/istio/istio.git istio-1.2.0-code && cd istio-1.2.0-code
helm template install/kubernetes/helm/istio-init/ --name istio-init --namespace istio-system > istio-init.yaml
kubectl apply -f istio-init.yaml

helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=true \
  --set gateways.enabled=true \
  --set gateways.istio-ingressgateway.enabled=true \
  --set gateways.istio-egressgateway.enabled=true \
  --set global.controlPlaneSecurityEnabled=true \
  --set mixer.adapters.useAdapterCRDs=false \
  --set grafana.enabled=true --set grafana.security.enabled=true \
  --set tracing.enabled=true \
  --set kiali.enabled=true > istio.yaml
kubectl apply -f istio.yaml

kubectl get pods --field-selector=status.phase=Running --all-namespaces
kubectl get svc --namespace istio-system --output wide
kubectl get pods -n istio-system
kubectl get events -n istio-system
kubectl top pods -n istio-system
kubectl get deployments -n istio-system --show-labels
kubectl get crd

kubectl logs -lapp=galley -n istio-system --all-containers=true
kubectl logs -lapp=istio-ingressgateway -n istio-system --all-containers=true
kubectl logs -lapp=istio-mixer -n istio-system --all-containers=true
kubectl logs -lapp=pilot -n istio-system --all-containers=true
kubectl logs -lapp=istio-telemetry -n istio-system --all-containers=true
kubectl logs -lapp=istio-policy -n istio-system --all-containers=true

kubectl describe pod -lapp=galley -n istio-system
kubectl describe pod -lapp=istio-ingressgateway -n istio-system
kubectl describe pod -lapp=istio-mixer -n istio-system
kubectl describe pod -lapp=pilot -n istio-system
kubectl describe pod -lapp=istio-telemetry -n istio-system
kubectl describe pod -lapp=istio-policy -n istio-system
```

### Install the Istio istioctl client
```
$ kubectl get deployment -n istio-system
ISTIO_VERSION=1.2.0
curl -sL "https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istio-$ISTIO_VERSION-linux.tar.gz" | tar xz
sudo cp istio-$ISTIO_VERSION/bin/istioctl /usr/local/bin/istioctl
sudo chmod +x /usr/local/bin/istioctl
rmdir -f istio-$ISTIO_VERSION
```

### To access Grafana from laptop
* Deploy Istio 1.0.4 deployed on K8s 1.11.5 (deployed using AKS) using helm 2.11 and for Grafana,
* changed to port 3500 on localhost
```
run mingw.exe
kubectl.exe -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3500:3000
```

### Using istio
* https://docs.microsoft.com/en-us/azure/aks/istio-scenario-routing


### Removing istio
```
kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
kubectl get crd | grep -i istio | awk '{print $1}' | xargs -n 1 kubectl delete crd
kubectl get customresourcedefinitions | grep istio
kubectl delete --cascade namespace istio-system
helm delete --purge istio
helm delete --purge istio-init
kubectl delete ns istio-system
```
