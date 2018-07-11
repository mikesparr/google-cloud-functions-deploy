#!/usr/bin/env bash

set -e

gcloud auth activate-service-account --key-file "${PWD}/client-secret.json" || die "unable to authenticate service account for gcloud"

gcloud --quiet config set project $PROJECT_NAME_PRD
gcloud --quiet config set container/cluster $CLUSTER_NAME_PRD
gcloud --quiet config set compute/zone ${CLOUDSDK_COMPUTE_ZONE}

gcloud container clusters get-credentials $CLUSTER_NAME_PRD

source deploy/functions.sh

CHANGED_FILES=$(git diff --name-only $TRAVIS_COMMIT_RANGE)

function deploy_function () {
    if [[ ! -z "$1" ]]; then
        echo "===> Getting trigger for $1"
        TRIGGER=${MYFUNCS[$1]} # trigger
        echo "===> Deploying trigger $TRIGGER"

        # call appropriate command
        if [[ "$TRIGGER" == "http" ]]; then
            gcloud beta functions deploy $1 \
            --source https://source.developers.google.com/projects/$PROJECT_NAME_PRD/repos/$REPOSITORY_ID/moveable-aliases/master/paths/$2 \
            --memory "128MB" --trigger-http
        else
            gcloud beta functions deploy $1 \
            --source https://source.developers.google.com/projects/$PROJECT_NAME_PRD/repos/$REPOSITORY_ID/moveable-aliases/master/paths/$2 \
            --memory "128MB" --trigger-event providers/cloud.pubsub/eventTypes/topic.publish --trigger-resource $TRIGGER
        fi
    fi
}

for change in $CHANGED_FILES; do
    CHANGED_PATH=${change%/*} # just get base path without filename
    echo "===> Path: $CHANGED_PATH"

    # check for pattern in path and capture last directory
    if [[ "$CHANGED_PATH" == "functions/"* ]]; then
        echo "===> Function changed!"
        # get last directory for function name
        FUNCTION_NAME=$(echo "$CHANGED_PATH" | awk -F'/' '{print $2}')
        echo "===> Function name: $FUNCTION_NAME"

        deploy_function $FUNCTION_NAME $CHANGED_PATH
    fi
done