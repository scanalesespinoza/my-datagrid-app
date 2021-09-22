oc new-project dgdemo --display-name="Data Grid Demo"
oc apply -f - << EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
 name: datagrid
spec:
 targetNamespaces:
 - dgdemo
EOF
oc apply -f - << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
 name: datagrid-operator
spec:
 channel: 8.2.x
 installPlanApproval: Automatic
 name: datagrid
 source: redhat-operators
 sourceNamespace: openshift-marketplace
EOF
sleep 10
oc rollout status -w deployment/infinispan-operator-new-deploy
oc get pods
oc create -f k8s-objects/infinispan.yaml
sleep 10
oc rollout status -w statefulset/datagrid-service
oc apply -f - << EOF
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: my-dg
spec:
  to:
    kind: Service
    name: datagrid-service
    weight: 100
  port:
    targetPort: infinispan
  tls:
    termination: reencrypt
    insecureEdgeTerminationPolicy: Allow
  wildcardPolicy: None
EOF
oc get secret datagrid-service-generated-secret -o jsonpath="{.data.identities\.yaml}" | base64 --decode
export PASSWORD=$(oc get secret datagrid-service-generated-secret -o jsonpath="{.data.identities\.yaml}" | base64 --decode | grep password | awk '{print $2}')
oc apply -f - << EOF
apiVersion: infinispan.org/v2alpha1
kind: Cache
metadata:
  name: mycachedefinition
spec:
  clusterName: datagrid-service
  name: mycache
EOF
sleep 10
for i in {1..100} ; do
  curl -H 'Content-Type: text/plain' -k -u developer:$PASSWORD -X POST -d "myvalue$i" https://my-dg-dgdemo.2886795286-80-elsy07.environments.katacoda.com/rest/v2/caches/mycache/mykey$i
  echo "Added mykey$i:myvalue$i"
done
sleep 10
curl -k -u developer:$PASSWORD https://my-dg-dgdemo.2886795286-80-elsy07.environments.katacoda.com/rest/v2/caches/mycache/mykey22
curl -H 'Content-Type: text/plain' -k -u developer:$PASSWORD -X PUT -d "mynewvalue22" https://my-dg-dgdemo.2886795286-80-elsy07.environments.katacoda.com/rest/v2/caches/mycache/mykey22
curl -k -u developer:$PASSWORD https://my-dg-dgdemo.2886795286-80-elsy07.environments.katacoda.com/rest/v2/caches/mycache/mykey22
curl -k -u developer:$PASSWORD -X DELETE https://my-dg-dgdemo.2886795286-80-elsy07.environments.katacoda.com/rest/v2/caches/mycache/mykey22
curl -i -k -u developer:$PASSWORD https://my-dg-dgdemo.2886795286-80-elsy07.environments.katacoda.com/rest/v2/caches/mycache/mykey22
