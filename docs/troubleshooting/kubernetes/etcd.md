# etcd troubleshooting


## Health Checks of etcd members

```bash
kubectl -n kube-system exec -it etcd-k8smaster-0 -- sh -c "ETCDCTL_API=3 \
    ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
    ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
    ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
    etcdctl endpoint health"
```

Determine how many databases are part of the cluster. Three and five are common to provide 50up-arrow to return to the previous command and edit the command without having to type the whole command again.

```bash
kubectl -n kube-system exec -it etcd-k8smaster-0 -- sh -c "ETCDCTL_API=3 etcdctl --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --endpoints=https://127.0.0.1:2379 member list"
```

You can also view the status of the cluster in a table format.

```bash
kubectl -n kube-system exec -it etcd-k8smaster-0 -- sh -c "ETCDCTL_API=3 \
    ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
    ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
    ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
    etcdctl --endpoints=https://127.0.0.1:2379 \
    -w table endpoint status --cluster"
```

## Snapshot and Restore ETCD DB

### Snapshot Etcd DB

`ETCDCTL_API=3 etcdctl snapshot save "/tmp/etcd-backup.db" --cacert /etc/kubernetes/pki/etcd/ca.crt   --cert /etc/kubernetes/pki/etcd/server.crt   --key /etc/kubernetes/pki/etcd/server.key`

### Write-out status

```
ETCDCTL_API=3 etcdctl snapshot status "/tmp/etcd-backup.db" --write-out=table
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 9012b5d5 |    23452 |       1479 |     2.5 MB |
+----------+----------+------------+------------+
```

### Restore Database

`ETCDCTL_API=3 etcdctl snapshot restore "/tmp/etcd-backup.db" --skip-hash-check=true --data-dir="/var/lib/etcd-from-backup"`

### Modify /etc/kubernetes/manifests/etcd.yaml

  - hostPath:
      path: /var/lib/etcd-from-backup
      type: DirectoryOrCreate

