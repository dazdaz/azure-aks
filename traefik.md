

### Traefik
* Edge router
* Ingress controller with INgress
* Native and declarative constructs for:
*  ingresses
*  circuit breakers
*  traffic shifting (canary testing)


* Helm values for traefik with LetsEncrypt
* deploy via helm
* public IP required by LetsEncrypt
* ingressClass used due to 2 or more Ingress controllers (int+ext)
* acme is the settings for LetsEncrypt
* DNS address of the load balancer : cdk8spu-dev.westus.cloudapp.azure.com"
```
image: traefik
serviceType: LoadBalancer
loadBalancerIP: "40.78.47.210"
replicas: 1

kubernetes:
  ingressClass: "pu-dev-traefik-external"
ssl:
  enabled: true
  enforced: true
  permanentRedirect: true

acme:
  enabled: true
  email: me@mydomain.com
  domains:
    enabled: true
    domainsList:
      - main: "cdk8spu-dev.westus.cloudapp.azure.com"
gzip:
  enabled: true
rbac:
  enabled: true
```


### Ingress with traffic shifting
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: pu-dev-traefik-external
    traefik.ingress.kkubernetes.io/service-weights: |
      pu-dev-website-partsunlimited-website-blue: 20%
      pu-dev-website-partsunlimited-website-blue: 80%
  labels:
    app: partsunlimited-website
    chart: paertsunlimited-website-0.1.0
    heritage: Tiller
    release: pu-dev-website
    system: PartsUnlimited
  name: pu-dev-website-partsunlimited-website
  namespace: pu-dev
spec:
  rules:
  - host: cdk8spu-dev.westus.cloudapp.azure.com
    http:
      paths:
      - backend:
        serviceName: pu-dev-website-partsunlimited-website-blue
        servicePort: http
      path: /site
    - backend:
        serviceName: pu-dev-website-partsunlimited-website-green
        servicePort: http
      path: /site
```


* If we have less than 80% success rates on this traffic, then we remove the traffic, so that we don't have cascading failures
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    traefik.backend.circuitbreaker: NetworkErrorRatio() > 0.2
  labels:
    app: partsunlimited-api
    canary: blue
    chart: partsunlimited-api-0.1.0
    heritage: Tiller
    release: pu-dev-api
    system: PartsUnlimited
  name: pu-dev-api-partsunlimited-api-blue
  namespace: pu-dev
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
  selector:
    app: partsunlimited-api
    canary: blue
    release: pu-dev-api
    system: PartsUnlimited
```

https://colinsalmcorner.com/post/container-devops-beyond-build-part-1
https://www.colinsalmcorner.com/post/container-devops-beyond-build-part-2---traefik
https://www.colinsalmcorner.com/post/container-devops-beyond-build-part-3---canary-testing


