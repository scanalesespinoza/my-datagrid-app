#!/bin/bash
# TASK
echo "########################################################"
echo "###         INICIANDO PRUEBA DE DATA GRID...         ###"
echo "########################################################"

echo "CREANDO PROYECTO Y TEMPLATE"
echo "########################################################"
oc new-project dgdemo --display-name="Data Grid Demo"
echo "`oc process -f k8s-objects/dg-template.yaml | oc create -f -`" | tee -a test.log

echo "ESPERANDO LA INSTANCIA DEL OPERADOR..."
echo "########################################################"
sleep 30

echo "`oc rollout status -w deployment/infinispan-operator-new-deploy`" | tee -a test.log
echo "`oc get pods`" | tee -a test.log

echo "ESPERANDO LA INSTANCIA DEL SERVICIO DATAGRID..."
echo "########################################################"
sleep 60
echo "`oc rollout status -w statefulset/datagrid-service`" | tee -a test.log
echo "`oc get pods`" | tee -a test.log

echo "OBTENIENDO ACCESOS AL GRID"
echo "########################################################"
oc get secret datagrid-service-generated-secret -o jsonpath="{.data.identities\.yaml}" | base64 --decode
export PASSWORD=$(oc get secret datagrid-service-generated-secret -o jsonpath="{.data.identities\.yaml}" | base64 --decode | grep password | awk '{print $2}')

echo "ESPERANDO QUE EL CACHE ESTE LISTO..."
echo "########################################################"
sleep 60

export DGHOST=$(oc get route my-dg -o=jsonpath='{.spec.host}{"\n"}')

echo "INJECTANDO DATOS AL GRID"
echo "########################################################"
for i in {1..100} ; do
	curl -H 'Content-Type: text/plain' -k -u developer:$PASSWORD -X POST -d "myvalue$i" https://$DGHOST/rest/v2/caches/mycache/mykey$i
  echo "Added mykey$i:myvalue$i"
done

# SLEEP
sleep 10

echo "CONSULTANDO DATO AL GRID"
echo "########################################################"
echo "`curl -k -u developer:$PASSWORD https://$DGHOST/rest/v2/caches/mycache/mykey22`" | tee -a test.log
echo "ACTUALOZANDO DATO AL GRID"
echo "`curl -H 'Content-Type: text/plain' -k -u developer:$PASSWORD -X PUT -d "mynewvalue22" https://$DGHOST/rest/v2/caches/mycache/mykey22`" | tee -a test.log
echo "CONSULTANDO NUEVO VALOR DEL DATO AL GRID"
echo "`curl -k -u developer:$PASSWORD https://$DGHOST/rest/v2/caches/mycache/mykey22`" | tee -a test.log
echo "ELIMINANDO DATO AL GRID"
echo "`curl -k -u developer:$PASSWORD -X DELETE https://$DGHOST/rest/v2/caches/mycache/mykey22`" | tee -a test.log
echo "CONSULTANDO DATO ELIMINADO AL GRID"
echo "`curl -i -k -u developer:$PASSWORD https://$DGHOST/rest/v2/caches/mycache/mykey22`" | tee -a test.log

echo "PRUEBA DE DATOS EN CACHE EJECUTADA"
echo "PUEDES ACCEDER A LA CONSOLA WEB MEDIANTE LA URL: https://$DGHOST/"

read -p "LISTO PARA ELIMINAR EL ESPACIO DE PRUEBA? (Y/N) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

cat test.log
# SLEEP
echo "REALIZANDO LIMPIEZA DEL PROYECTO..."
echo "########################################################"
sleep 10

echo "`oc process -f k8s-objects/dg-template.yaml | oc delete -f -`" | tee -a test.log
oc delete all --all -n dgdemo --wait=true
oc delete project dgdemo


# TASK
echo "########################################################"
echo "###       FINALIZANDO PRUEBA DE DATA GRID...         ###"
echo "########################################################"
sleep 20

fi
