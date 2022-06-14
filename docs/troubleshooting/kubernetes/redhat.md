




## Fixing Image Pull Secret

> get current pull secret
  `oc get secret pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}'`

https://access.redhat.com/solutions/4844461

You need to authenticate using a Bearer token, which you can get from the second section at https://cloud.redhat.com/openshift/token. 

OFFLINE_ACCESS_TOKEN=<>

```
$ export BEARER=$(curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token)
```


```
$ curl -X POST https://api.openshift.com/api/accounts_mgmt/v1/access_token --header "Content-Type:application/json" --header "Authorization: Bearer $BEARER" | jq

{
  "auths": {
    "cloud.openshift.com": {
      "auth": "<snip>",
      "email": "<user's email>"
    },
    "quay.io": {
      "auth": "<snip>",
      "email": "<user's email>"
    },
    "registry.connect.redhat.com": {
      "auth": "<snip>",
      "email": "<user's email>"
    },
    "registry.redhat.io": {
      "auth": "<snip>",
      "email": "<user's email>"
    }
  }
}
```

or directly  ` | base64 | pbcopy` and `pbpaste` into cmd line

## Changing the Global Pull Secret 

[How to change the global pull secret in OCP 4](https://access.redhat.com/solutions/4902871)

`oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=.local/rh-pullsecret.json`

`oc get secret pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}'`