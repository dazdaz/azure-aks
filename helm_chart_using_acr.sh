## Helm

```
add acr repo to helm repository -> az acr helm repo add -n <acr-name>
create -> https://docs.helm.sh/developing_charts/
store  -> az acr helm push wordpress-2.1.10.tgz
deploy -> helm install <acrName>/wordpress
delete -> az acr helm delete wordpress --version 2.1.10
```

** Manual working example of creating, storing and deploying a helm chart :

```
ACRNAME=myacr
mkdir ~/acr-helm && cd ~/acr-helm
helm fetch stable/selenium
tar xvzf selenium-0.3.1.tgz
<modify files in helm chart>
<update version in Chart.yaml>
helm lint my-chart

git init
git add selenium/
git commit -am "changes config variables"
git push origin master

tar cvzf selenium-0.3.2.tgz selenium/
az acr helm repo add -n $ACRNAME
az acr helm push selenium-0.3.2.tgz -n $ACRNAME
az acr helm list -n $ACRNAME                  # view charts in acr repo - full info
az acr helm list -n $ACRNAME -o table         # view charts in acr repo - summary
az acr helm delete selenium --version 0.3.1  # this is how you delete, keep previous versions available online
az acr helm show selenium -n $ACRNAME -o table  # show does the same as list command
helm repo update
helm inspect dazacr/selenium # Show information for a Helm chart
helm install stable/selenium
# shows the config of live running helm charts
helm get values stable/selenium
```

https://docs.microsoft.com/en-us/azure/container-registry/container-registry-helm-repos [https://aka.ms/acr/helm-repos]
https://azure.microsoft.com/en-us/blog/azure-container-registry-public-preview-of-helm-chart-repositories-and-more/
https://docs.microsoft.com/en-us/azure/container-registry/
https://docs.microsoft.com/en-us/cli/azure/acr/helm/repo?view=azure-cli-latest#az-acr-helm-repo-add
