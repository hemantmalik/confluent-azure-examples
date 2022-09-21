#!/bin/bash

source utils/helper.sh

printf "\nSetting up environment\n\n"
env_id=$(terraform output resource-ids | awk 'NR==3 {print $3}')
cluster_id=$(terraform output resource-ids | awk 'NR==4 {print $4}')
cloud_key=$(terraform output resource-ids | awk 'NR==8 {print $5}' | tr -d \")
cloud_secret=$(terraform output resource-ids | awk 'NR==9 {print $5}' | tr -d \")
service_account=$(terraform output resource-ids | awk 'NR==7 {print $2}' | tr -d \")

confluent environment use $env_id
confluent kafka cluster use $cluster_id

printf "\nCreating the ksqlDB instance\n"
confluent ksql cluster create $ksql_cluster_name --cluster "$cluster_id" --api-key "$cloud_key" --api-secret "$cloud_secret" --csu 1 -o json | jq -r '.[].id'

printf "\nSleeping 30 seconds\n"
sleep 30

ksqldb=$(confluent ksql cluster list -o json | jq -r '.[].id')
ksqldb_endpoint=$(confluent ksql cluster list -o json | jq -r '.[].endpoint')

MAX_WAIT=720
printf "\n";print_process_start "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
retry $MAX_WAIT validate_ksqldb_endpoint_ready $ksqldb_endpoint || exit 1
print_pass "Confluent Cloud KSQL is UP"

printf "\nConfiguring ksqlDB ACLs\n"
CMD="confluent ksql cluster configure-acls "$ksqldb" pageviews users"
$CMD \
  && print_code_pass -c "$CMD" \
  || exit_with_error -c $? -n "$NAME" -m "$CMD" -l $(($LINENO -3))

echo -e "\nSleeping 10 seconds\n"
sleep 10

scratch_output=$(confluent api-key create --service-account "$service_account" --resource "$ksqldb" -o json)

ksql_api_key=$(echo "$scratch_output" | jq -r ".key")
ksql_api_secret=$(echo "$scratch_output" | jq -r ".secret")

echo "${ksql_api_key}:${ksql_api_secret}"

printf "\nSubmitting KSQL queries via curl to the ksqlDB REST endpoint\n"
printf "\tSee https://docs.ksqldb.io/en/latest/developer-guide/api/ for more information\n"
while read ksqlCmd; do # from statements-cloud.sql
	response=$(curl -w "\n%{http_code}" -X POST $ksqldb_endpoint/ksql \
	       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
	       -u "${ksql_api_key}:${ksql_apisecret}" \
	       --silent \
	       -d @<(cat <<EOF
	{
	  "ksql": "$ksqlCmd",
	  "streamsProperties": {
			"ksql.streams.auto.offset.reset":"earliest",
			"ksql.streams.cache.max.bytes.buffering":"0"
		}
	}
EOF
	))
	echo "$response" | {
	  read body
	  read code
	  if [[ "$code" -gt 299 ]];
	    then print_code_error -c "$ksqlCmd" -m "$(echo "$body" | jq .message)"
	    else print_code_pass  -c "$ksqlCmd" -m "$(echo "$body" | jq -r .[].commandStatus.message)"
	  fi
	}
sleep 3;
done < utils/statements-cloud.sql
printf "\nConfluent Cloud ksqlDB ready\n"