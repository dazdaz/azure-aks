
In Nginx Ingress Controller version 0.22 the following annotation changed :
Annotation nginx.ingress.kubernetes.io/rewrite-target has changed and will not behave as expected if you don't update them.

The change in annotation is documented here :
https://github.com/kubernetes/ingress-nginx/releases

Refer to here on howto update the rewrite-target rule https://kubernetes.github.io/ingress-nginx/examples/rewrite/#rewrite-target

https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md

* Example ingress.yaml
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/enable-rewrite-log: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
  name: rewrite-ingress
  namespace: default
spec:
  rules:
  - host: rewrite.bar.com
    http:
      paths:
      - backend:
          serviceName: http-svc
          servicePort: 80
        path: /(something/.*)
tls:
  -
    hosts:
      - rewrite.bar.com
    secretName: aks-dev-ingress-tls
```
