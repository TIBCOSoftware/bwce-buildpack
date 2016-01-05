# Buildpack Scripts for TIBCO BusinessWorks™ Container Edition 
The TIBCO BusinessWorks™ Container Edition buildpack is a highly extensible [Cloud Foundry] buildpack for running TIBCO BusinessWorks™ Container Edition applications. This buildpack can be customized for supported third-party drivers, OSGI bundles, integration with application configuration management systems, application certificate management etc.

TIBCO BusinessWorks(TM) Container Edition allows customers to leverage the power and functionality of TIBCO ActiveMatrix BusinessWorks(TM) in order to build cloud-native applications with an API-first approach and to deploy it to container-based PaaS platforms such as Cloud Foundry(TM).

To find more about TIBCO BusinessWorks™ Container Edition, refer https://docs.tibco.com/products/tibco-businessworks-container-edition-1-0-0

These buildpack scripts are subject to the license shared as part of the repository. Review the license before using or downloading these buildpack scripts.
     
##Prerequisite
    To create/extend the buildpack, you must have access to https://edelivery.tibco.com.
    
##Create buildpack
   1. Clone this repository onto your local machine.
   2. Download TIBCO BusinessWorks™ Container Edition 1.0.0 from https://edelivery.tibco.com.
   3. Find bwce.zip from the downloaded artifacts and copy it into `<Your-local-buildpack-repo>/resources/cache`. (Create a cache folder if it does not exist.)
   4. Zip the contents of the repository from your local machine as [`bwce-buildpack.zip`].
   5. Push the new buildpack to your Cloud Foundry environment.

##Buildpack Extension
   1. Clone this repository onto your local machine.
   2. Download TIBCO BusinessWorks™ Container Edition 1.0.0 from https://edelivery.tibco.com.
   3. Find bwce.zip from the downloaded artifacts and copy it into `<Your-local-buildpack-repo>/resources/cache`. (Create cache folder if it does not exist.)
   4. Extend the buildpack for Third-party JDBC drivers or OSGi bundles: You can customize the buildpack to use the supported third-party drivers e.g. Oracle JDBC driver or OSGified bundles in TIBCO BusinessWorks™ Container Edition runtime.
     * Provision suppprted JDBC drivers: 
          * Follow steps described in "Using Third Party JDBC Drivers" on https://docs.tibco.com/pub/bwcf/1.0.0/doc/html/GUID-881316C3-28F9-4BCF-A512-38B731BE63D1.html.
          * Copy the appropriate driver bundle from `<TIBCO_HOME>/bwcf/<version>/config/drivers/shells/<driverspecific runtime>/runtime/plugins/` to  `<Your-local-buildpack-repo>/resources/addons/jars` folder.
     * Provision [OSGi](https://www.osgi.org) bundle jar(s): Copy OSGified bundle jar(s) into `<Your-local-buildpack-repo>/resources/addons/jars`
   5. Add support for the new application configuration management system: We support [Spring Cloud Config](http://cloud.spring.io/spring-cloud-config/spring-cloud-config.html) (both as managed and as [CUPS](https://docs.cloudfoundry.org/devguide/services/user-provided.html)) and [Zuul Config](https://github.com/Confluex/Zuul/wiki) (as CUPS) management systems out of the box. Refer https://docs.tibco.com/pub/bwcf/1.0.0/doc/html/GUID-3AAEE4AD-8701-4F4E-AD7B-2416A9DDA260.html for CUPS support. To add support for other systems, update `<Your-local-buildpack-repo>/java-profile-token-resolver/ProfileTokenResolver.java`. This class has a dependecy on Jettison(1.3.3) JSON library. You can pull this dependency from the installation `<TIBCO_HOME>/bwcf/<version>/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison_*` or download it from the web.
   6. Extend the buildpack for certificates: There are various use cases where you would want to use certificates from different systems for your application. For example, a certificate to connect to SpringCloud config service or a certificate to connect to TIBCO Enterprise Message Service. Bundling certificates with your application is not a good idea as you would need to rebuild your application when the certificates expire. To avoid that, you can copy your certificates into the `<Your-local-buildpack-repo>/resources/addons/certs` folder. Once the certificates expire, you can copy the new certificates into the buildpack without rebuilding your application. Just push your application with the new buildpack. To access the certificates folder from your application, use the environment variable [BW_KEYSTORE_PATH]. For example, #BW_KEYSTORE_PATH#/mycert.jks in your application property.
   7. Zip contents of the repository from your local machine as [`bwce-buildpack.zip`].
   8. Push new buildpack to your Cloud Foundry environment.

##License
These buildpack scripts are released under [3-clause BSD](License.md) license.
     
