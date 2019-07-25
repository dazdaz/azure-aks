## dl
```
wget -O clusterrole.yaml https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/clusterrole.yaml
wget -O clusterrolebinding.yaml https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/clusterrolebinding.yaml
wget -O serviceaccount.yaml https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/serviceaccount.yaml
wget -O values.yaml https://raw.githubusercontent.com/helm/charts/master/stable/datadog/values.yaml
# Check that helm has been deployed
kubectl get pods -n kube-system -l app=helm
```

## deploy_datadog.sh
```
kubectl apply -f clusterrole.yaml
kubectl apply -f clusterrolebinding.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f datadog-agent+logcollection.yaml
helm install --name datadog -f values.yaml stable/datadog
helm ls
kubectl get ds -n default
kubectl describe ds datadog
helm upgrade -f values.yaml datadog stable/datadog --recreate-pods
helm delete datadog --purge
```

## values.yaml
```
image:
  repository: datadog/agent
  tag: 6.10.1
  pullPolicy: IfNotPresent
nameOverride: ""
fullnameOverride: ""

datadog:
  apiKey: 1234567890
  name: datadog
  logLevel: INFO
  useCriSocketVolume: true
  nonLocalTraffic: true
  logsEnabled: true
  logsConfigContainerCollectAll: true
  containerLogsPath: /var/lib/docker/containers
  apmEnabled: true
  processAgentEnabled: true
  resources: {}
clusterAgent:
  enabled: false

  containerName: cluster-agent
  image:
    repository: datadog/cluster-agent
    tag: 1.2.0
    pullPolicy: IfNotPresent
  token: ""

  replicas: 1
  metricsProvider:
    enabled: false
  clusterChecks:
    enabled: false
  resources: {}
rbac:
  create: true
  serviceAccountName: default

tolerations: []

kubeStateMetrics:
  enabled: true

kube-state-metrics:
  rbac:

    create: true

    serviceAccountName: default

daemonset:
  enabled: true
  containers:

    agent:

      resources: {}

    processAgent:

      resources: {}

    traceAgent:

      resources: {}
  useHostPort: true
deployment:
  enabled: false
  replicas: 1
  affinity: {}
  tolerations: []
  service:
    type: ClusterIP
    annotations: {}
clusterchecksDeployment:
  enabled: false

  rbac:
    dedicated: false
    serviceAccountName: default
  replicas: 2
  resources: {}
  tolerations: []
```
