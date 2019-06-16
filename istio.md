* https://docs.microsoft.com/en-us/azure/aks/istio-install

```
# render Istio resources yaml
$ helm template install/kubernetes/helm/istio --kube-version "1.10" --name istio --namespace istio-system \
  --set global.crds=false \
  --set global.controlPlaneSecurityEnabled=true \
  --set global.mtls.enabled=true \
  --set grafana.enabled=true \
  --set tracing.enabled=true \
  --set galley.enabled=false \
  --set kiali.enabled=true \
  --values install/kubernetes/helm/istio/values.yaml \
  >> aks-istio.yaml

# Apply resources yaml to AKS cluster
$ kubectl apply -f aks-istio.yaml -n istio-system
```

Deploy Istio 1.0.4 deployed on K8s 1.11.5 (deployed using AKS) using helm 2.11 and for Grafana, changed to port 3500 on localhost
(no time to figure out why this is in use) :

```
$ kubectl get deployment -n istio-system
$ sudo cp bin/istioctl /usr/local/bin
```

### To access Grafana from laptop
```
run mingw.exe
kubectl.exe -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3500:3000
```

== Using istio ==
* https://docs.microsoft.com/en-us/azure/aks/istio-scenario-routing


== Removing istio ==
```
kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
kubectl get crd | grep -i istio | awk '{print $1}' | xargs -n 1 kubectl delete crd
kubectl get customresourcedefinitions | grep istio
kubectl delete --cascade namespace istio-system
helm delete --purge istio
helm delete --purge istio-init
kubectl delete ns istio-system
```
