
https://github.com/nutanix/openshift/tree/main/docs/install/manual


https://github.com/nutanix/openshift/tree/main/operators/csi

oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Removed"}}'

oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'

## Exposing Image Registry

oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

## Nutanix Volumes Image Registry

```bash
export KUBECONFIG=~/openshift/auth/kubeconfig

echo """apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nutanix-volume
provisioner: csi.nutanix.com
parameters:
  csi.storage.k8s.io/provisioner-secret-name: ntnx-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ntnx-system
  csi.storage.k8s.io/node-publish-secret-name: ntnx-secret
  csi.storage.k8s.io/node-publish-secret-namespace: ntnx-system
  csi.storage.k8s.io/controller-expand-secret-name: ntnx-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: ntnx-system
  csi.storage.k8s.io/fstype: ext4
  dataServiceEndPoint: 10.42.35.38:3260
  storageContainer: Default
  storageType: NutanixVolumes
  #whitelistIPMode: ENABLED
  #chapAuth: ENABLED
allowVolumeExpansion: true
reclaimPolicy: Delete""" > nutanix-volumes-storageclass.yaml

echo """kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: image-registry-claim
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: nutanix-volume""" > nutanix-volumes-pvc.yaml

```

## Nutanix Dynamic Files Image Registry

```bash

export KUBECONFIG=~/openshift/auth/kubeconfig

echo """kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: nutanix-files-dynamic
provisioner: csi.nutanix.com
parameters:
  dynamicProv: ENABLED
  nfsServerName: FedNFS
  #nfsServerName above is File Server Name in Prism without DNS suffix, not the FQDN.
  csi.storage.k8s.io/provisioner-secret-name: ntnx-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ntnx-system
  storageType: NutanixFiles""" > nutanix-files-dynamic-storageclass.yaml

echo """
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: image-registry-claim
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: nutanix-files-dynamic""" > nutanix-files-dynamic-pvc.yaml
```

oc apply -f nutanix-files-dynamic-storageclass.yaml
oc apply -f nutanix-files-dynamic-pvc.yaml

# Patch OC Image Registry to use created PVC

oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"pvc":{"claim":"image-registry-claim"}},"rolloutStrategy": "Recreate"}}'

https://console-openshift-console.apps.ocp1.ntnxlab.local/k8s/cluster/imageregistry.operator.openshift.io~v1~Config/cluster/yaml


## Nutanix Objects s3 Image Registry

https://FedS3.ntnxlab.local

oc create secret generic image-registry-private-configuration-user --from-literal=REGISTRY_STORAGE_S3_ACCESSKEY=B9lSXygeJT9D0jpRjbxu-eA91UZ1rrgQ --from-literal=REGISTRY_STORAGE_S3_SECRETKEY=jP4B_qHMZPo3vdJX-l4USABM-e7HAOFn --namespace openshift-image-registry

Access Key: B9lSXygeJT9D0jpRjbxu-eA91UZ1rrgQ
Secret Key: jP4B_qHMZPo3vdJX-l4USABM-e7HAOFn

https://openshift-image-registry.FedS3.ntnxlab.local
bucket: openshift-image-registry


nx2Tech704!

storage:
  s3:
    bucket: <bucket-name>
    region: <region-name>


---
apiVersion: resources.cattle.io/v1
kind: Backup
metadata:
  name: nightly-rancher-s3-backup
spec:
  resourceSetName: rancher-resource-set
  retentionCount: 10
  schedule: 0 0 * * *
  storageLocation:
    s3:
      bucketName: harvester-rke2-lab-bucket
      credentialSecretName: aws-s3-creds
      credentialSecretNamespace: default
      region: us-gov-east-1
      endpoint: s3.us-gov-east-1.amazonaws.com


https://podman.io/getting-started/installation
sudo dnf -y install podman

## registry login and pull

oc login -u kubeadmin -p oLVsN-6vhUA-ijrIW-VNhue https://api-int.apps.ocp1.ntnxlab.local:6443


podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false default-route-openshift-image-registry.apps.ocp1.ntnxlab.local
podman pull docker.io/busybox
podman tag docker.io/busybox default-route-openshift-image-registry.apps.ocp1.ntnxlab.local/openshi›ft/busybox
podman images

podman push --tls-verify=false default-route-openshift-image-registry.apps.ocp1.ntnxlab.local/openshift/busybox
podman images

podman rmi default-route-openshift-image-registry.apps.ocp1.ntnxlab.local/openshift/busybox
podman images

podman pull --tls-verify=false default-route-openshift-image-registry.apps.ocp1.ntnxlab.local/openshift/busybox
podman images

## cleanup images

podman rmi default-route-openshift-image-registry.apps.ocp1.ntnxlab.local/openshift/busybox docker.io/library/busybox

## kasten install

SECRET=$(kubectl get sc -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io\/is-default-class=="true")].parameters.csi\.storage\.k8s\.io\/provisioner-secret-name}')
DRIVER=$(kubectl get sc -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io\/is-default-class=="true")].provisioner}')

cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
   name: default-snapshotclass
driver: csi.nutanix.com
parameters:
   storageType: NutanixVolumes
   csi.storage.k8s.io/snapshotter-secret-name: $SECRET
   csi.storage.k8s.io/snapshotter-secret-namespace: kube-system
deletionPolicy: Delete
EOF


helm repo add kasten https://charts.kasten.io --force-update && helm repo update
kubectl create ns kasten-io
kubectl annotate volumesnapshotclass default-snapshotclass \
    k10.kasten.io/is-snapshot-class=true

curl -s https://docs.kasten.io/tools/k10_primer.sh | bash


https://10.42.35.37:9440/console/#login

Prism UI Credentials: admin/nx2Tech704!
CVM Credentials: nutanix/nx2Tech704!