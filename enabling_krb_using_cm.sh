#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright Cloudera 2015

# https://groups.google.com/a/cloudera.org/forum/#!topic/scm-users/ChGln8DekBM
curl -o /usr/local/bin/jq http://stedolan.github.io/jq/download/linux64/jq && sudo chmod +x /usr/local/bin/jq

CMNODE=localhost
TARGET="$@"
BASE=http://$CMNODE:7180/api/v8
CLUSTER=$(curl -X GET -u "admin:admin" -i $BASE/clusters | grep '"name"' | awk -F'"' '{print $4}')
services_json=`curl -s -u admin:admin "$BASE/clusters/$CLUSTER/services" | jq '[.items[]|{name, type}]'`
num_services=`echo $services_json | jq 'length'`

zk(){
    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"enableSecurity","value":"true"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$1/config
}

hdfs(){
    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"hadoop_security_authentication","value":"kerberos"},{"name":"hadoop_security_authorization","value":"true"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$1/config

    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"dfs_datanode_http_port","value":"1006"}, 
{"name":"dfs_datanode_port","value":"1004"}, 
{"name":"dfs_datanode_data_dir_perm","value":"700"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$1/roleConfigGroups/$1-DATANODE-BASE/config
}

mr(){
    [ -n "mr1" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"taskcontroller_min_user_id","value":"0"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$1/roleConfigGroups/$1-TASKTRACKER-BASE/config

    [ -n "yarn" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"container_executor_min_user_id","value":"0"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$1/roleConfigGroups/$1-NODEMANAGER-BASE/config
}

hbase(){
    [ -n "hbase" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"hbase_security_authentication","value":"kerberos"},{"name":"hbase_security_authorization","value":"true"}]}' \
	-u admin:admin \
	$BASE/clusters/$CLUSTER/services/$1/config
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

display_next_steps() {
  echo "*** NEXT ***"
  echo
  echo "As the configurations are being updated, stop the entire services,"
  echo "deploy Kerberos client configuration, deploy cluster client configuration, "
  echo "and start the cluster."
}

index=0
while [ $index -lt $num_services ]; do
    dictionary=`echo $services_json | jq ".[$index]"`
    name=`echo $dictionary | jq -r '.name'`
    type=`echo $dictionary | jq -r '.type'`

    case $type in
        HBASE)
            hbase $name
            ;;
        HDFS)
            hdfs $name
            ;;
        YARN)
            mr $name
	    ;;
	MAPREDUCE)
	    mr $name
            ;;
        ZOOKEEPER)
            zk $name
            ;;
    esac

    let index=index+1
done

krb
other
display_next_steps
