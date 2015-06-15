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

cm_host="localhost" # Should be changed
cluster="Cluster1" # use '%20 for spaces
api_ver="v6" # choose appropriate versions per the CM versions. see http://cloudera.github.io/cm_api/docs/releases/

base_uri=http://$cm_host:7180/api/$api_ver/clusters/$cluster
hdfs=$(curl -X GET -u "admin:admin" -i $base_uri/services | grep '"displayName"' | grep -i hdfs | awk -F'"' '{print $4}')
zookeeper=$(curl -X GET -u "admin:admin" -i $base_uri/services | grep '"displayName"' | grep -i zookeeper | awk -F'"' '{print $4}')
yarn=$(curl -X GET -u "admin:admin" -i $base_uri/services | grep '"displayName"' | grep -i yarn | awk -F'"' '{print $4}')
mr1=$(curl -X GET -u "admin:admin" -i $base_uri/services | grep '"displayName"' | grep -i mapreduce | awk -F'"' '{print $4}')
hbase=$(curl -X GET -u "admin:admin" -i $base_uri/services | grep '"displayName"' | grep -i hbase | awk -F'"' '{print $4}')

prompt_for_safety() {
  echo "*** Caution: Disabling Kerberos ***"
  echo
  echo "This utility disables Kerberos with the CDH cluster with CM"
  echo "This only does change the configurations of the following services."
  echo
  echo "ZooKeeper: enableSecurity -> false"
  echo "HDFS: hadoop.security.authentication -> simple, hadoop.security.authorization -> false"
  echo "YARN/MR1: min.user.id --> 1000" 
  echo "HBase: hbase.security.authentication --> simple, hbase.security.authorization --> false"
  echo
  echo "*** CAUTION CAUTION CAUTION CAUTION CAUTION ***"
  echo "You have 10 seconds to hit Control-C to stop this script!"
  echo "*** CAUTION CAUTION CAUTION CAUTION CAUTION ***"
  echo

  for i in $($SEQ 1 10) ; do
    sleep 1
    echo -n "."
  done

  echo
}

display_next_steps() {
  echo "*** NEXT ***"
  echo
  echo "As the configurations are being reset, please restart the cluster and deploy"
  echo "the client configuration in the cluster."
}

disable_hbase(){
    [ -n "hbase" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"hbase_security_authentication","value":"simple"},{"name":"hbase_security_authorization","value":"false"}]}' \
	-u admin:admin \
	$base_uri/services/$hbase/config
}

disable_mr(){
    [ -n "mr1" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"taskcontroller_min_user_id","value":"1000"}]}' \
	-u admin:admin \
	$base_uri/services/$mr1/roleConfigGroups/$mr1-TASKTRACKER-BASE/config

    [ -n "yarn" ]; curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"container_executor_min_user_id","value":"1000"}]}' \
	-u admin:admin \
	$base_uri/services/$yarn/roleConfigGroups/$yarn-NODEMANAGER-BASE/config
}

disable_zk(){
    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"enableSecurity","value":"false"}]}' \
	-u admin:admin \
	$base_uri/services/$zookeeper/config
}

disable_hdfs(){
    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"hadoop_security_authentication","value":"simple"},{"name":"hadoop_security_authorization","value":"false"}]}' \
	-u admin:admin \
	$base_uri/services/$hdfs/config
    
    curl -s -X PUT -H 'Content-type:application/json' \
	-d '{"items":[{"name":"dfs_datanode_http_port","value":"50075"},
{"name":"dfs_datanode_port","value":"50010"},
{"name":"dfs_datanode_data_dir_perm","value":"700"}]}' \
    -u admin:admin \
    $base_uri/services/$hdfs/roleConfigGroups/$hdfs-DATANODE-BASE/config
}

prompt_for_safety
disable_hbase
disable_mr
disable_hdfs
disable_zk
display_next_steps

