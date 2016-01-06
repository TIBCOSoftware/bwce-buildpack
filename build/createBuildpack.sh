#!/bin/bash
# Copyright (c) 2016, TIBCO Software Inc. All rights reserved.
# You may not use this file except in compliance with the license 
# terms contained in the TIBCO License.md file provided with this file.

get_abs_filename() {
# $1 : relative filename
echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

echo ">>>>>>>>>> Start time: $(date) <<<<<<<<<<<<"
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: ./createBuildpack.sh <path/to/bwce.zip> <options>"
    printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Location of runtime zip(bwce.zip)"
    printf "\t %s \t\t\t %s \n" "-test" "Test created buildpack"
    exit 1
fi

zipLocation=$1
cd ..
mkdir -p resources/cache && cp -i $zipLocation "$_"

zip -r build/bwce-buildpack.zip bin/ java-profile-token-resolver/ resources/

buildpackLocation=`get_abs_filename build/bwce-buildpack.zip`

cd build
if [ "$2" == "-test" ]; then
    sh uploadBuildpack.sh $buildpackLocation -test
else
    sh uploadBuildpack.sh $buildpackLocation
fi
echo ">>>>>>>>>> End time: $(date) <<<<<<<<<<<<"
