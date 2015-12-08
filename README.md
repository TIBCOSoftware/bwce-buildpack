# Cloud Foundry TIBCO BusinessWorks Container Edition Buildpack (bwce-buildpack)
The `bwce-buildpack` is a highly extensible [Cloud Foundry] buildpack for running TIBCO BusinessWorks Container Edition applications. This buildpack can be customized for supported third-party drivers, OSGI bundles, integration with application configuration management systems, application certificates etc.
     
#Prerequisite
    To create/extend bwce-buildpack, you must have access to https://edelivery.tibco.com
    
#Create buildpack
   1. Clone this repository onto your local machine
   2. Download TIBCO BusinessWorks Container Edition 1.0.0 from https://edelivery.tibco.com
   3. Find bwce.zip from the download and copy it into `<Your-local-buildpack-repo>/resources/cache` (Create cache folder if not exists)
   4. Zip contents of repository from your local machine as [`bwce-buildpack.zip`]
   5. Push new buildpack to Cloud Foundry environment

#Buildpack Extension
   1. Clone this repository onto your local machine
   2. Download TIBCO BusinessWorks Container Edition 1.0.0 from https://edelivery.tibco.com
   3. Find bwce.zip from the download and copy it into `<Your-local-buildpack-repo>/resources/cache` (Create cache folder if not exists)
   4. Extend buildpack for Third-party JDBC drivers or OSGi bundles: You can customize buildpack to use supported third-party drivers e.g. Oracle JDBC driver or OSGified bundles in TIBCO BusinessWorks Container Edition runtime.
     * Provision suppprted JDBC drivers: 
          * Follow steps mentioned under section "Using Third Party JDBC Drivers" on https://docs.tibco.com/pub/bwcf/1.0.0/doc/html/GUID-881316C3-28F9-4BCF-A512-38B731BE63D1.html.
          * Copy the appropriate driver bundle from `<TIBCO_HOME>/bwcf/<version>/config/drivers/shells/<driverspecific runtime>/runtime/plugins/` to the `<Your-local-buildpack-repo>/resources/addons/jars` folder
     * Provision OSGi bundle jar(s): Copy OSGified bundle jar(s) into `<Your-local-buildpack-repo>/resources/addons/jars`
   5. aaa
   6. aaa
   7. aaa
   8. aaa
   9. aaa
   10. aa
   11. aa
  
     
