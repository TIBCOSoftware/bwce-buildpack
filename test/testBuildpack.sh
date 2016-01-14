#!/bin/bash
# Copyright (c) 2016, TIBCO Software Inc. All rights reserved.
# You may not use this file except in compliance with the license 
# terms contained in the TIBCO License.md file provided with this file.
if [[ $# -lt 1 || $# -gt 1 ]]; then
    echo "Usage: ./testBuildpack.sh <buildpack name> "
    printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Buildpack available by typing cf buildpacks"
    exit 1
fi

OUTPUT=`cf buildpacks | grep $1`
if [ -z "$OUTPUT" ]; then
    echo "${1} is not found in the buildpacks. Refer Readme to create and upload buildpack."
    exit 1
fi


echo "***** Starting BWCE Sanity *****"

echo "***** Pushing HTTP Greetings App to CF *****"
appName=`grep -E "name:" manifest.yml | cut -d ':' -f 2 | sed 's/^ *//g' | sed 's/ *$//g'`
URL=`cf push -f manifest.yml -b $1 | grep "urls:" | cut -d ' ' -f 2`
sleep 5
a=$(curl "http://$URL/greetings/")
BWCE_MESSAGE=`grep -E "RESPONSE_MESSAGE:" manifest.yml | cut -d ':' -f 2 | sed 's/^ *//g' | sed 's/ *$//g' `
if [ "${a}" = "Greetings from $BWCE_MESSAGE" ]; then
    echo "----------------------------------------------------------------------";
        echo "******* HTTP Greetings App - running successfully! *******";
     echo "******* Buildpack test Passed !! *******";
    echo "----------------------------------------------------------------------";
else
    echo ${a}
    echo "----------------------------------------------------------------------";
    echo "******* HTTP Greetings App Failed ! Deleting App *******";
    echo "----------------------------------------------------------------------";
    echo "----------------------------------------------------------------------";
    echo "******* Buildpack test Failed !! *******";
    echo "----------------------------------------------------------------------";
    cf delete $appName -f
    exit -1

fi

cf delete $appName -f
