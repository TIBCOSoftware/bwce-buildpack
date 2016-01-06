# Buildpack Scripts for TIBCO BusinessWorks™ Container Edition 
The TIBCO BusinessWorks™ Container Edition buildpack is a highly extensible [Cloud Foundry] buildpack for running TIBCO BusinessWorks™ Container Edition applications. This buildpack can be customized for supported third-party drivers, OSGI bundles, integration with application configuration management systems, application certificate management etc.

TIBCO BusinessWorks(TM) Container Edition allows customers to leverage the power and functionality of TIBCO ActiveMatrix BusinessWorks(TM) in order to build cloud-native applications with an API-first approach and to deploy it to container-based PaaS platforms such as Cloud Foundry(TM).

To find more about TIBCO BusinessWorks™ Container Edition, refer https://docs.tibco.com/products/tibco-businessworks-container-edition-1-0-0

These buildpack scripts are subject to the license shared as part of the repository. Review the license before using or downloading these buildpack scripts.

##Prerequisite
    1. Need access to https://edelivery.tibco.com.
    2. Install [Cloud Foundry CLI](https://docs.pivotal.io/pivotalcf/devguide/installcf/install-go-cli.html).
    3. Install ZIP utility on your local machine.
    4. [Login to your Pivotal Cloud Foundry environment](https://docs.pivotal.io/pivotalcf/devguide/installcf/whats-new-v6.html#login).
    
##Download TIBCO BusinessWorks™ Container Edition Runtime
    Download appropriate TIBCO BusinessWorks™ Container Edition 1.0.0 artifacts from [https://edelivery.tibco.com](https://edelivery.tibco.com/storefront/eval/tibco-businessworks-container-edition/prod11654.html). It contains TIBCO BusinessWorks™ Container Edition runtime(bwce.zip).
     
##Create buildpack
   1. Clone this repository onto your local machine.
   2. Locate bwce.zip file from the downloaded artifacts and run [/build/createBuildpack.sh](/build/createBuildpack.zip). This will create TIBCO BusinessWorks™ Container Edition buildpack(bwce-buildpack.zip) inside [build](/build) directory.

##Buildpack Extension
Extend the buildpack for Third-party JDBC drivers or OSGi bundles: You can customize the buildpack to use the supported third-party drivers e.g. Oracle JDBC driver or OSGified bundles in TIBCO BusinessWorks™ Container Edition runtime.
* **Provision suppprted JDBC drivers**:
     * Follow steps described in "Using Third Party JDBC Drivers" on https://docs.tibco.com/pub/bwcf/1.0.0/doc/html/GUID-881316C3-28F9-4BCF-A512-38B731BE63D1.html.
     * Copy the appropriate driver bundle from `<TIBCO_HOME>/bwcf/<version>/config/drivers/shells/<driverspecific runtime>/runtime/plugins/` to  `<Your-local-buildpack-repo>/resources/addons/jars` folder. 
* **Provision [OSGi](https://www.osgi.org) bundle jar(s)**: Copy OSGified bundle jar(s) into `<Your-local-buildpack-repo>/resources/addons/jars`
* **Application Configuration Management**: We support [Spring Cloud Config](http://cloud.spring.io/spring-cloud-config/spring-cloud-config.html) (both as managed and as [CUPS](https://docs.cloudfoundry.org/devguide/services/user-provided.html)) and [Zuul Config](https://github.com/Confluex/Zuul/wiki) (as CUPS) management systems out of the box. Refer https://docs.tibco.com/pub/bwcf/1.0.0/doc/html/GUID-3AAEE4AD-8701-4F4E-AD7B-2416A9DDA260.html for CUPS support. To add support for other systems, update `<Your-local-buildpack-repo>/java-profile-token-resolver/ProfileTokenResolver.java`. This class has a dependecy on Jettison(1.3.3) JSON library. You can pull this dependency from the installation `<TIBCO_HOME>/bwcf/<version>/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison` or download it from the web.
* **Certificate Management**: There are use cases where you need to use certificates into your application to connect to different systems. For example, a certificate to connect to SpringCloud config service or a certificate to connect to TIBCO Enterprise Message Service. Bundling certificates with your application is not a good idea as you would need to rebuild your application when the certificates expire. To avoid that, you can copy your certificates into the `<Your-local-buildpack-repo>/resources/addons/certs` folder. Once the certificates expire, you can copy the new certificates into the buildpack without rebuilding your application. Just push your application with the new buildpack. To access the certificates folder from your application, use the environment variable [BW_KEYSTORE_PATH]. For example, #BW_KEYSTORE_PATH#/mycert.jks in your application property.

Run run [/build/createBuildpack.sh](/build/createBuildpack.sh) to create customized buildpack.

##Push buildpack to CloudFoundry environment
     1. Loggin to your Cloud Foundry environment
     2. Create buildpack if not already created
     2. Run run [/build/pushBuildpack.sh](/build/pushBuildpack.sh)
     
##Test buildpack
     1. Loggin to your Cloud Foundry environment
     2. Push buildpack to Cloud Foundry if not already done
     3. Run run [/test/testBuildpack.sh](/test/testBuildpack.sh)
If valid buildpack is created and uploaded, you will see `Buildpack test Passed !!` message printed.

##License
These buildpack scripts are released under [3-clause BSD](License.md) license.
     
