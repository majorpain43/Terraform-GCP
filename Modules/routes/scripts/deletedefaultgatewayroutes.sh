!/bin/bash

set -e

if [ -n "${GOOGLE_APPLICATION_CREDENTIALS}" ]; then
  export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=${GOOGLE_APPLICATION_CREDENTIALS}
fi

PROJECT_ID=$1
NETWORK_ID=$2
FILTERED_ROUTES=$(gcloud compute routes list \
  --project="${PROJECT_ID}" \
  --format="value(name)" \
  --filter=" \
    nextHopGateway:(https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/global/gateways/default-internet-gateway) \
    AND network:(https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/global/networks/${NETWORK_ID}) \
    AND name~^default-route \
  "
)

function delete_internet_gateway_routes {
  local routes="${1}"
  echo "${routes}" | while read -r line; do
    echo "Deleting route ${line}..."
    gcloud compute routes delete "${line}" --quiet --project="${PROJECT_ID}"
  done
}

if [ -n "${FILTERED_ROUTES}" ]; then
  delete_internet_gateway_routes "${FILTERED_ROUTES}"
else
  echo "Default internet gateway route(s) not found; exiting..."
fi

