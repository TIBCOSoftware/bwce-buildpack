#!/bin/bash
# Copyright (c) 2016, TIBCO Software Inc. All rights reserved.
# You may not use this file except in compliance with the license 
# terms contained in the TIBCO License.md file provided with this file.

if [[ $# -lt 1 || $# -gt 3 ]]; then
        echo "Usage: ./uploadBuildpack.sh <path/to/bwce-buildpack.zip> <buildpack-Name><options>"
        printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Location of buildpack zip(bwce-buildpack.zip)"
        printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Buildpack name"
        printf "\t %s \t\t\t %s \n" "-test" "Test uploaded buildpack"
        exit 1
fi
if [ -z "$2"  ]; then
    buildpackName="bwce-buildpack"
else
    buildpackName=$2
fi

OUTPUT=`cf buildpacks | grep "${buildpackName}"`
echo $OUTPUT
if [ -z "$OUTPUT" ]; then
    cf create-buildpack ${buildpackName} $1 1
else
    cf update-buildpack ${buildpackName} -p $1
fi

if [ "$3" == "-test" ]; then
    if [[ "$PWD" == *bwce-buildpack/build* ]]; then
        cd ..
    fi
    cd test
    ./testBuildpack.sh ${buildpackName}
fi
