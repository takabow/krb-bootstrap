#!/bin/sh

# https://groups.google.com/a/cloudera.org/forum/#!topic/scm-users/ChGln8DekBM

CMNODE=localhost
TARGET="$@"
BASE=http://$CMNODE:7180/api/v8
CLUSTER=$(curl -X GET -u "admin:admin" -i $BASE/clusters | grep '"name"' | awk -F'"' '{print $4}')

hdfs=$(curl -X GET -u "admin:admin" -i $BASE/clusters/$CLUSTER/services | grep '"displayName"' | grep -i hdfs | awk -F'"' '{print $4}')
hdfs=$(curl -X GET -u "admin:admin" -i $BASE/clusters/$CLUSTER/services | grep '"displayName"' | grep -i hdfs | awk -F'"' '{print $4}')
zookeeper=$(curl -X GET -u "admin:admin" -i $BASE/clusters/$CLUSTER/services | grep '"displayName"' | grep -i zookeeper | awk -F'"' '{print $4}')
yarn=$(curl -X GET -u "admin:admin" -i $BASE/clusters/$CLUSTER/services | grep '"displayName"' | grep -i yarn | awk -F'"' '{print $4}')
mr1=$(curl -X GET -u "admin:admin" -i $BASE/clusters/$CLUSTER/services | grep '"displayName"' | grep -i mapreduce | awk -F'"' '{print $4}')
hbase=$(curl -X GET -u "admin:admin" -i $BASE/clusters/$CLUSTER/services | grep '"displayName"' | grep -i hbase | awk -F'"' '{print $4}')


hdfs(){
    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"hadoop_security_authentication","value":"kerberos"},{"name":"hadoop_security_authorization","value":"true"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$hdfs/config

    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"dfs_datanode_http_port","value":"1006"}, 
{"name":"dfs_datanode_port","value":"1004"}, 
{"name":"dfs_datanode_data_dir_perm","value":"700"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$hdfs/roleConfigGroups/$hdfs-DATANODE-BASE/config
}

mr(){
    [ -n "mr1" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"taskcontroller_min_user_id","value":"0"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$mr1/roleConfigGroups/$mr1-TASKTRACKER-BASE/config

    [ -n "yarn" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"container_executor_min_user_id","value":"0"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$yarn/roleConfigGroups/$yarn-NODEMANAGER-BASE/config
}

krb(){
    curl -X PUT -u "admin:admin" -H "content-type:application/json" \
	-d '{ "items": [{"name": "KDC_HOST", "value": "'$CMNODE'"}, 
                  {"name": "KDC_TYPE", "value": "MIT KDC"}, 
                  {"name": "KRB_MANAGE_KRB5_CONF", "value": "true"},
                  {"name": "SECURITY_REALM", "value": "HADOOP"}]}' \
	$BASE/cm/config
}

other(){
    curl -X POST -u "admin:admin" -i \
	-G --data-urlencode 'username=cloudera-scm/admin@HADOOP' \
        --data-urlencode 'password=cloudera' \
	$BASE/cm/commands/importAdminCredentials
}

restart(){
    curl -X POST -u "admin:admin" -i \
	-H "Content-Type:application/json" \
	-d '{"redeployClientConfiguration": true, "restartOnlyStaleServices": null}' \
    $BASE/clusters/$CLUSTER/commands/restart
#    curl -X POST -u admin:admin "$BASE/cm/service/commands/restart"
}

hdfs
mr
krb
other
restart
