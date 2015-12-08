#Purpose
     Enable TIBCO customers to create/customize TIBCO BusinessWorks Container Edition buildpack for Cloud Foundry as per their needs.
     
#Prerequisite
    In order to create/customize buildpack, you must have access to https://edelivery.tibco.com
    
#Create buildpack
   1. Clone this repository onto your local machine
   2. Download TIBCO BusinessWorks Container Edition 1.0.0 from https://edelivery.tibco.com
   3. Find bwce.zip from the download and copy it into {Your-local-buildpack-repo}/resources/cache (Create cache folder if not exists)
   4. Zip contents of repository from your local machine as a buildpack 
   5. Push new buildpack to Cloud Foundry environment

#Buildpack Customization
   1. Clone this repository onto your local machine
   2. Download TIBCO BusinessWorks Container Edition 1.0.0 from https://edelivery.tibco.com
   3. Find bwce.zip from the download and copy it into {Your-local-buildpack-repo}/resources/cache (Create cache folder if not exists)
   4. Provision Third-party drivers or OSGi bundles
     4a. 
