### Docs to deploy istio on AKS
* https://docs.microsoft.com/en-us/azure/aks/istio-install

### Deploy Istio 1.2.0 onto AKS 1.14.0
```
# Render Istio resources yaml

kubectl create ns istio-system
./k8s-secret-grafana.sh
./k8s-secret-kiali.sh

ISTIO_VERSION=1.2.0
git clone https://github.com/istio/istio.git istio-${ISTIO_VERSION}-code && cd istio-${ISTIO_VERSION}-code
helm template install/kubernetes/helm/istio-init/ --name istio-init --namespace istio-system > istio-init.yaml
kubectl apply -f istio-init.yaml

# https://istio.io/docs/reference/config/installation-options/
helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=true \
  --set gateways.enabled=true \
  --set gateways.istio-ingressgateway.enabled=true \
  --set gateways.istio-egressgateway.enabled=true \
  --set global.controlPlaneSecurityEnabled=true \
  --set mixer.adapters.useAdapterCRDs=false \
  --set grafana.enabled=true --set grafana.security.enabled=true \
  --set tracing.enabled=true \
  --set kiali.enabled=true \
  --set kiali.dashboard.grafanaURL=http://grafana:3500 \
  --set kiali.dashboard.jaegerURL=http://jaeger:16686 > istio.yaml
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

### To access Grafana (analytics and monitoring dashboards for Istio are provided by Grafana) from laptop
* Changed to port 3500 on localhost
```
export CLUSTERNAME=lambo-sng-istio
export RGNAME=aksapp2-rg
az login
az account set -s 1234567890
az aks get-credentials -n $CLUSTERNAME -g $RGNAME
kubectl config get-contexts
kubectl config use-context $CLUSTERNAME
kubectl config current-context
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3500:3000
```

### To access Metrics for Istio are provided by Prometheus from laptop
```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090
```

### To view Tracing within Istio is provided by Jaeger from laptop
```
kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686
```

### To view the service mesh observability dashboard is provided by Kiali from laptop
```
kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001
```

### Sidecar injection
```
kubectl label namespace default istio-injection=enabled
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
