#!/bin/bash

#offline_access_token=$(cat "$1")
cluster_name="$1"

retries=0
max_retries=269

percent_complete=0

percent_complete_from_api=0

max_error_retries=10  # Allow up to 10 errors before throwing in the towel

error_retries=0


while [ $retries -lt $max_retries -a $percent_complete -lt 100 ]
do
    retries=$(($retries+1))

    percent_complete_from_api=$(curl -s -X GET "http://127.0.0.1:8090/api/assisted-install/v2/clusters?with_hosts=true" \
      -H "accept: application/json" \
      -H "get_unregistered_clusters: false" | jq -r ".[] | select (.name == \"$cluster_name\") |.progress.total_percentage" 2>&1)

    if [[ $percent_complete_from_api =~ ^(0|[1-9][0-9]{0,1}|100)$ ]]
    then
        percent_complete=$percent_complete_from_api
        if [ $percent_complete -eq 100 ]
        then
          break
        else
          sleep 20
        fi
    else
      error_retries=$(($error_retries+1))
      if [ $error_retries -lt $max_error_retries ]
      then
         sleep 20
         continue
      else
         echo "Error: Assisted Installer API call failed - max error retries exceeded"
         exit 1
       fi
    fi
done

if [ $percent_complete -lt 100 ]
then
  echo "Error: Install timed out after 90 minutes"
  exit 1
else
  echo "Install successful !"
  exit 0
fi
