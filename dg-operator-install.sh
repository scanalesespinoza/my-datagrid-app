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