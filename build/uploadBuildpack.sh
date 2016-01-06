#!/bin/bash

if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "Usage: ./uploadBuildpack.sh <path/to/bwce-buildpack.zip> <options>"
        printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Location of buildpack zip(bwce-buildpack.zip)"
        printf "\t %s \t\t\t %s \n" "-test" "Test buildpack after uploading"
        exit 1
fi

OUTPUT=`cf buildpacks | grep "bwce-buildpack"`
if [ -z "$OUTPUT" ]; then
    cf create-buildpack bwce-buildpack $1 1
else
    cf update-buildpack bwce-buildpack -p $1
fi

if [ "$2" == "-test" ]; then
    cd ../test
    sh testBuildpack.sh
fi
