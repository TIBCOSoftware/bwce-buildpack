# Buildpack Scripts for TIBCO BusinessWorks™ Container Edition 
The TIBCO BusinessWorks™ Container Edition buildpack is a highly extensible [Cloud Foundry] buildpack for running TIBCO BusinessWorks™ Container Edition applications. This buildpack can be customized for supported third-party drivers, OSGI bundles, integration with application configuration management systems, application certificate management etc.

TIBCO BusinessWorks(TM) Container Edition allows customers to leverage the power and functionality of TIBCO ActiveMatrix BusinessWorks(TM) in order to build cloud-native applications with an API-first approach and to deploy it to container-based PaaS platforms such as Cloud Foundry(TM).

To find more about TIBCO BusinessWorks™ Container Edition, visit [Documentation]( https://docs.tibco.com/products/tibco-businessworks-container-edition-2-0-0)

These buildpack scripts are subject to the license shared as part of the repository. Review the license before using or downloading these buildpack scripts.

##Prerequisite
  * Access to https://edelivery.tibco.com.
  * Install [Cloud Foundry CLI](https://docs.pivotal.io/pivotalcf/devguide/installcf/install-go-cli.html).
  * Install ZIP utility on your local machine.
  * [Login to your Pivotal Cloud Foundry environment](https://docs.pivotal.io/pivotalcf/devguide/installcf/whats-new-v6.html#login).
    
##Download TIBCO BusinessWorks™ Container Edition
Download appropriate TIBCO BusinessWorks™ Container Edition 2.0.0 artifacts from [https://edelivery.tibco.com](https://edelivery.tibco.com/storefront/eval/tibco-businessworks-container-edition/prod11654.html). It contains TIBCO BusinessWorks™ Container Edition runtime(bwce_cf.zip).
     
##Create buildpack
   1. Clone this repository onto your local machine.
   2. Locate bwce.zip file from the downloaded artifacts and run [/build/createBuildpack.sh](/build/createBuildpack.sh). This will create TIBCO BusinessWorks™ Container Edition buildpack(bwce-buildpack.zip) inside [build](/build) directory.

##Buildpack Extension
You can customize the buildpack to add supported third-party drivers e.g. Oracle JDBC driver, OSGified bundles or runtime of certified   Plug-ins in TIBCO BusinessWorks™ Container Edition runtime. It can also be customized for application certificate management as well as to integrate with application configuration management services.
* **Provision suppported JDBC drivers**:
     * Run **bwinstall[.exe] help** from `<BWCE_HOME>/bin` and follow instructions to add the driver to BWCE installation.
     * Copy the appropriate driver bundle from `<BWCE_HOME>/config/drivers/shells/<driverspecific runtime>/runtime/plugins/` to  `<Your-local-buildpack-repo>/resources/addons/jars` folder. 
* **Provision [OSGi](https://www.osgi.org) bundle jar(s)**: Copy OSGified bundle jar(s) into `<Your-local-buildpack-repo>/resources/addons/jars`
* **Application Configuration Management**: We support [Spring Cloud Config](http://cloud.spring.io/spring-cloud-config/spring-cloud-config.html) (both as managed and as [CUPS](https://docs.cloudfoundry.org/devguide/services/user-provided.html)) and [Zuul Config](https://github.com/Confluex/Zuul/wiki) (as CUPS) management systems out of the box. Refer https://docs.tibco.com/pub/bwce/2.0.0/doc/html/GUID-3AAEE4AD-8701-4F4E-AD7B-2416A9DDA260.html for CUPS support. To add support for other systems, update `<Your-local-buildpack-repo>/java-profile-token-resolver/ProfileTokenResolver.java`. This class has a dependecy on Jettison(1.3.3) JSON library. You can pull this dependency from the installation `<BWCE_HOME>/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison` or download it from the web.
* **Certificate Management**: There are use cases where you need to use certificates into your application to connect to different systems. For example, a certificate to connect to SpringCloud config service or a certificate to connect to TIBCO Enterprise Message Service. Bundling certificates with your application is not a good idea as you would need to rebuild your application when the certificates expire. To avoid that, you can copy your certificates into the `<Your-local-buildpack-repo>/resources/addons/certs` folder. Once the certificates expire, you can copy the new certificates into the buildpack without rebuilding your application. Just push your application with the new buildpack. To access the certificates folder from your application, use the environment variable [BW_KEYSTORE_PATH]. For example, #BW_KEYSTORE_PATH#/mycert.jks in your application property.
*  **Provision TIBCO BusinessWorks™ Container Edition Plug-in Runtime**: 
   * TIBCO Certified Plug-Ins: The TIBCO BusinessWorks™ Container Edition 1.0.1 and above release has added support for certified plug-ins. Contact `TIBCO Support` for list of all supported plug-ins. To add a plug-in runtime into your buildpack:
     * Download appropriate the plug-in packaging e.g. TIBCO ActiveMatrix BusinessWorks(TM) Plug-in for WebSphere MQ from https://edelivery.tibco.com
     * Locate the plug-in zip file e.g. `<ProductID>_ePaas.zip` or `TIB_<ProductID>_<ProductionVersion>_<BuildNumber>_bwce-runtime.zip` file from the downloaded artifacts and copy into `<Your-local-buildpack-repo>/resources/addons/plugins`
  * Plug-ins created using [TIBCO ActiveMatrix BusinessWorks™ Plug-in Development Kit](https://docs.tibco.com/products/tibco-activematrix-businessworks-plug-in-development-kit-6-1-1): For Plug-ins created using [TIBCO ActiveMatrix BusinessWorks™ Plug-in Development Kit](https://docs.tibco.com/products/tibco-activematrix-businessworks-plug-in-development-kit-6-1-1), their runtime must be added to the buildpack. To add the plug-in runtime into your buildpack:
     * [Install Plug-In](https://docs.tibco.com/pub/bwpdk/6.1.1/doc/html/GUID-0FB70A84-DBF6-4EE6-A6C8-28AC5E4FF1FF.html) if not already installed
     * Navigate to the `<TIBCO-HOME>/bwce/palettes/<plugin-name>/<plugin-version>` directory and  zip `lib` and `runtime` folders into `<plugin-name>.zip` file. Copy `<plugin-name>.zip` into `<Your-local-buildpack-repo>/resources/addons/plugins` folder.
  * Copy any OSGi bundles required by the plug-in e.g. Thirdparty Driver bundles etc. into `<Your-local-buildpack-repo>/resources/addons/jars`

Run [/build/createBuildpack.sh](/build/createBuildpack.sh) to create the customized buildpack.

##Push buildpack to CloudFoundry environment
  * Login to your Cloud Foundry environment
  * Create buildpack if not already created
  * Run [/build/pushBuildpack.sh](/build/pushBuildpack.sh)
     
##Test buildpack
  * Login to your Cloud Foundry environment
  * Push buildpack to Cloud Foundry if not already done
  * Go to [test](/test) directory and run [testBuildpack.sh](/test/testBuildpack.sh). If valid buildpack is created and uploaded,  `Buildpack test Passed !!` message will be printed. In case of failure, inspect logs for `tibco.bwce.sample.http` application.

##License
These buildpack scripts are released under [3-clause BSD](License.md) license.
     
