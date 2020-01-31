#!/bin/bash
USERCOUNT=25

RUN_PREREQUISITES=false
MULTIUSER=false

while [[ $# -gt 0 ]] && [[ ."$1" = .--* ]] ;
do
    opt="$1";
    shift;              #expose next argument
    case "$opt" in
        "--" ) break 2;;
        "--prerequisites" )
           RUN_PREREQUISITES="true";;
        "--multiuser" )
           MULTIUSER="true";;
        *) exit 0;;
   esac
done






if [ $RUN_PREREQUISITES = true ]
then
    echo "Running pre-requisites"
    echo "**********************"
    echo ""

    echo "Configure authentication"
    cd prerequisites/authentication/  ; chmod +x run.sh ; ./run.sh ; cd ../..
    sleep 15
    oc login -u clusteradmin -p redhat

    if [ $MULTIUSER = true ]
    then
    echo "Configure NFS autoprovisioner (not supported, only for PoC)"
    cd prerequisites/nfs-autoprovisioner/  ; chmod +x run.sh ; ./run.sh ; cd ../..
    fi

   
fi





if [ $MULTIUSER = true ]
then
  echo "Create projects to run the workshop"

  for i in $(eval echo "{1..$USERCOUNT}") ; do
    oc login -u user$i -p redhat  > /dev/null 2>&1
    oc login -u clusteradmin -p redhat > /dev/null 2>&1
    oc new-project workshop-knative-intro-user$i > /dev/null 2>&1
    oc adm policy add-role-to-user admin user$i -n workshop-knative-intro-user$i
    #oc adm policy add-role-to-user admin user$i -n workshop-knative-intro-content
  done


fi




echo "Building and deploying workshop"
cd ..

oc new-project workshop-knative-intro-content

if [ $MULTIUSER = true ]
then
  #.workshop/scripts/deploy-spawner.sh  --settings=develop
  .workshop/scripts/deploy-spawner.sh
  echo "multiuser" > typedeployed
else
  #.workshop/scripts/deploy-personal.sh  --settings=develop
  .workshop/scripts/deploy-personal.sh
  echo "personal" > typedeployed
fi

#oc patch  $(oc get dc -o name)  --type='json' --patch='[{"op": "add", "path": "/spec/template/metadata/annotations", "value":{"sidecar.istio.io/inject": "true"}}]'

sleep 15
.workshop/scripts/build-workshop.sh
oc rollout status $(oc get dc -o name)
sleep 10


WORKSHOP_URL=$(oc get routes.route.openshift.io  | grep lab | awk '{print $2}')

echo ""
echo ""
echo "**********************************************************************************************"
echo "   Now you can open https://$WORKSHOP_URL"
echo ""
echo "   Use your OpenShift credentials to log in"
echo "**********************************************************************************************"
echo ""
