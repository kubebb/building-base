# Installer

Here are the steps about how to install building-base component which include ways to install:

- a [kind](https://kind.sigs.k8s.io/) cluster
- `u4a-component` which provides account, authentication, authorization and audit management
    - [nginx ingress service](https://docs.nginx.com/nginx-ingress-controller/)
    - [cert-manager service](https://cert-manager.io/)
    - [oidc based on dex](https://github.com/dexidp/dex)
    - [multi-tenant based on capsule](https://github.com/clastix/capsule)
    - [oidc-proxy based on kube-oidc-proxy](https://github.com/jetstack/kube-oidc-proxy)
- more addons
    - [kuber-dashboard](https://github.com/kubernetes/dashboard)
    - [kubelogin](https://github.com/int128/kubelogin)

## Prerequisites

- [Install Docker](https://docs.docker.com/engine/install/)
- [Install kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Install Helm](https://helm.sh/docs/intro/install/)
- [Install kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- Get source code
  ```shell
  $ git clone https://github.com/kubebb/building-base.git
  ```

## Documentation
You can view th official document of kubebb here: [view document](http://kubebb.k8s.com.cn/)

## Quick Start

  Create a k8s cluster via kind and deploy the cluster component, u4a component.

```shell
# if  you don't have a k8s cluster, it will create a k8s cluster by kind
make kind

# it will install cluster components, u4a-components
make e2e
```

## Manual deployment

### 1. Install u4a-component
For the 1st step, we'll install u4a-component and it'll provide the account, authentication, authorization and audit funcationality built on Kubernetes. And it has the capability to add more features following the guide later.

#### 1.1 Install u4a services

Enter into u4a-component folder and following the step below:

> **Note**
> This step will install a ingress nginx controller with ingressclass named 'portal-ingress' and cert-manager for certificate management.


This step will install the following services:
* cert-manager
* ingress-nginx
* Capsule for tenant management
* kube-oidc-proxy for K8S OIDC enablement
* oidc-server for OIDC and iam service
* resource-view-controller for resource aggregation view from multiple clusters

1. Create namespace `u4a-namespace`

    ```
    kubectl create ns u4a-system
    ```


2. Edit values.yaml to replace the placeholder below:
* `<replaced-ingress-nginx-ip>`, replace it with the IP address of the ingress nginx node that deployed in the previous step, this placeholder will have multiple ones
* `<replaced-oidc-proxy-node-name>`, replace it with the node name where kube-oidc-proxy will be installed
* `<replaced-kube-oidc-proxy-host-ip>`, replace it with the IP address of node where kube-oidc-proxy will be installed, this placeholder will have multiple ones
* you should also update the image address if you're using a private registry
* edit `charts/cluster-component/values.yaml` to replace `<replaced-ingress-node-name>` with the K8S node name that will install the ingress controller, so update the value of deployedHost, and remember the IP address of this host, will use it at the next step.

    ```yaml
    ingress-nginx:
    # MUST update this value
      deployedHost: &deployedHost
        k8s-ingress-nginx-node-name
    ```

3. Install u4a component using helm

    ```
    # run helm install
    $ helm install --wait u4a-component -n u4a-system .

    # wait for all pods to be ready
    $ kubectl get pod -n u4a-system
    NAME                                                          READY   STATUS    RESTARTS   AGE
    bff-server-6c9b4b97f5-gqrx6                                   1/1     Running   0          45m
    capsule-controller-manager-6cf656b98c-sjm5n                   1/1     Running   0          66m
    cert-manager-756fd78bff-wb2vh                                 1/1     Running   0          76m
    cert-manager-cainjector-64685f8d48-qg69v                      1/1     Running   0          76m
    cert-manager-webhook-5c46d68c6b-f4dkh                         1/1     Running   0          76m
    cluster-component-ingress-nginx-controller-5bd67897dd-5m9n7   1/1     Running   0          76m
    kube-oidc-proxy-5f4598c77c-fzl5q                              1/1     Running   0          65m
    oidc-server-85db495594-k6pkt                                  2/2     Running   0          65m
    resource-view-controller-76d8c79cf-smkj5                      1/1     Running   0          66m
    ```

4. At the end of the helm install, it'll prompt you with some notes like below:

    ```
    NOTES:
    1. Get the  ServiceAccount token by running these commands:

      export TOKENNAME=$(kubectl get serviceaccount/host-cluster-reader -n u4a-system -o jsonpath='{.secrets[0].name}')
      kubectl get secret $TOKENNAME -n u4a-system -o jsonpath='{.data.token}' | base64 -d
    ```

    Save the token and will use it to add the cluster later.


5. Open the host configured using ingress below:

    `https://portal.<replaced-ingress-nginx-ip>.nip.io`


    If your host isn't able to access nip.io, you should add the ip<->host mapping to your hosts file. Login with user admin/kubebb-admin (default one).


6. Prepare the environment
1) Create a namespace for cluster management, it should be 'cluster-system'.

    ```
    kubectl create -n cluster-system
    ```

2) Add current cluster to the portal. Navigate to '集群管理' and '添加集群'
* for API Host, use the one from `hostK8sApiWithOidc`
* for API Token, use the one you saved from step 3.

Now, you should have a cluster and a 'system-tenant' and tenant management.

### 2. Add more components
1. Install kube-dashboard following [this doc](https://github.com/kubebb/addon-components/kube-dashboard/) to integrate with u4a.

    Refer to [kubernetes dashboard ](https://github.com/kubernetes/dashboard) for details.

2. Install kubelogin following [this doc](https://github.com/kubebb/addon-components/kubelogin/) to integrate with u4a

    Refer to [kubelogin](https://github.com/int128/kubelogin) for details.
