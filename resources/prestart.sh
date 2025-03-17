#!/bin/bash
# Copyright (c) 2016, TIBCO Software Inc. All rights reserved.
# You may not use this file except in compliance with the license 
# terms contained in the TIBCO License.md file provided with this file.
printBWTable()
{
	echo "------------------- Product Inventory -------------------"
	echo "---------------------------------------------------------"
	echo "Name      = "`grep product.name $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "Version   = "`grep product.version $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "Build     = "`grep product.build $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "Vendor    = "`grep product.vendor $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "BuildDate = "`grep product.build.date $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "---------------------------------------------------------"
	mkdir -p $APPDIR/tibco.home/addons
	pluginFolder=$APPDIR/tibco.home/addons
	if [ "$(ls $pluginFolder | grep lib)" ]; then
		for name in $(find $pluginFolder/lib -type f); 
		do	
			# filter out hidden files
			if [[ "$(basename $name)" != .* && "$(basename $name)" == *.ini ]]; then
				echo "Name      = "`grep product.name $name|cut -d'=' -f 2`
				echo "Version   = "`grep product.version $name|cut -d'=' -f 2`
				echo "Build     = "`grep product.build $name|cut -d'=' -f 2`
				echo "Vendor    = "`grep product.vendor $name|cut -d'=' -f 2`
				echo "BuildDate = "`grep product.build.date $name|cut -d'=' -f 2`
				echo "---------------------------------------------------------"
			fi
		done
	fi
}

checkJAVAHOME()
{
	if [[ ${JAVA_HOME} ]]; then
 		echo $JAVA_HOME
 	else
		JRE_VERSION=`ls $APPDIR/tibco.home/tibcojre64/`
		jreLink=tibcojre64/$JRE_VERSION
		chmod +x $APPDIR/tibco.home/$jreLink/bin/java
		export JAVA_HOME=$APPDIR/tibco.home/$jreLink
 	fi
}

memoryCalculator()
{
	if [[ ${MEMORY_LIMIT} ]]; then
		memory_Number=`echo $MEMORY_LIMIT | sed 's/m$//'`
		configured_MEM=$((($memory_Number*67+50)/100))
		thread_Stack=$((memory_Number))
		JAVA_PARAM="-Xmx"$configured_MEM"M -Xms128M -Xss512K"
		if [[ ${BW_JAVA_OPTS} && ${BW_JAVA_OPTS} != *"Xm"* ||  -z ${BW_JAVA_OPTS} ]]; then
			export BW_JAVA_OPTS=$JAVA_PARAM" "$BW_JAVA_OPTS
		fi
	fi
}

checkJMXConfig()
{
	if [[ ${BW_JMX_CONFIG} ]]; then
		if [[ $BW_JMX_CONFIG == *":"* ]]; then
			JMX_HOST=${BW_JMX_CONFIG%%:*}
			JMX_PORT=${BW_JMX_CONFIG#*:}
		else
			JMX_HOST="127.0.0.1"
			JMX_PORT=$BW_JMX_CONFIG
		fi
		JMX_PARAM="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port="$JMX_PORT" -Dcom.sun.management.jmxremote.rmi.port="$JMX_PORT" -Djava.rmi.server.hostname="$JMX_HOST" -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false "
		export BW_JAVA_OPTS=$BW_JAVA_OPTS" "$JMX_PARAM
	fi
}


checkJavaGCConfig()
{
	if [[ ${BW_JAVA_GC_OPTS}  ]]; then
 		echo $BW_JAVA_GC_OPTS
 	else
 		export BW_JAVA_GC_OPTS="-XX:+UseG1GC"
 	fi
}

checkThirdPartyInstallation() 
{
	INSTALL_DIR=$APPDIR/tibco.home/thirdparty-installs
	if [ -d "$INSTALL_DIR" ]; then
		for f in "$INSTALL_DIR"/*; do
      		if [ -d $f ]
      		then
            	if [ -d "$f"/lib ]; then
                	export LD_LIBRARY_PATH="$f"/lib:$LD_LIBRARY_PATH
            	fi	
      		
      			setupFile=`ls "$f"/*.sh`
      			if [ -f "$setupFile" ]; then
      		    	chmod 755 "$setupFile" 
      		    	source "$setupFile" "$f"
      			fi	
      		fi
		done;
	fi
}

export APPDIR=/home/vcap/app
export BW_KEYSTORE_PATH=$HOME/keystore
export MALLOC_ARENA_MAX=2
export MALLOC_MMAP_THRESHOLD_=1024
export MALLOC_TRIM_THRESHOLD_=1024
export MALLOC_MMAP_MAX_=65536
export TIB_DTCP_EXTERNAL={$CF_INSTANCE_IP}{$PORT/$CF_INSTANCE_PORT}
chmod 755 $APPDIR/tibco.home/bw*/*/bin/startBWAppNode.sh
sed -i.bak "s#_APPDIR_#$APPDIR#g" $APPDIR/tibco.home/bw*/*/config/appnode_config.ini
if [ "$(ls $APPDIR/tibco.home/bw*/*/ext/shared)"  ]; then 
	sed -i "s#_APPDIR_#$APPDIR#g" $APPDIR/tibco.home/bw*/*/ext/shared/addons.link	
fi

chmod 755 $APPDIR/tibco.home/bw*/*/bin/bwappnode
sed -i "s#_APPDIR_#$APPDIR#g" $APPDIR/tibco.home/bw*/*/bin/bwappnode.tra	
sed -i "s#_APPDIR_#$APPDIR#g" $APPDIR/tibco.home/bw*/*/bin/bwappnode

if [[ ${BW_LOGLEVEL} ]]; then
	echo "Before substitution...."
	cat $APPDIR/tmp/pcf.substvar
	# subst profile file
	echo PORT is $PORT
fi
if grep -q BW.CLOUD.PORT "$APPDIR/tmp/pcf.substvar"; then
	sed -i.bak -Ee "
	/BW.CLOUD.PORT/ {
	# append a line
	N
	s/(<value>)[0-9]+(<\/value)/\1${PORT}\2/
	}" $APPDIR/tmp/pcf.substvar
 else
   echo "BW.CLOUD.PORT not found."
fi

export JETTISON_JAR=`echo $APPDIR/tibco.home/bw*/*/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison*/jettison*.jar`

setLogLevel()
{
	logback=$APPDIR/tibco.home/bw*/*/config/logback.xml
	if [[ ${CUSTOM_LOGBACK} ]]; then
		     logback_custom=$APPDIR/tibco.home/custom-logback/logback.xml
			 if [ -e ${logback_custom} ]; then
				cp ${logback} `ls $logback`.original.bak && cp -f ${logback_custom}  ${logback}  
				echo "Using Custom Logback file"
			else
				echo "Custom Logback file not found. Using the default logback file"
			fi	
	fi

	if [[ ${BW_LOGLEVEL} && "${BW_LOGLEVEL,,}"="debug" ]]; then
		if [ -e ${logback} ]; then
			sed -i.bak "/<root/ s/\".*\"/\"$BW_LOGLEVEL\"/Ig" $logback
			echo "The loglevel is set to $BW_LOGLEVEL level"
		fi
		else
			sed -i.bak "/<root/ s/\".*\"/\"ERROR\"/Ig" $logback
fi
}


checkBWProfileEncryptionConfig()
{
	if [[ ${BW_PROFILE_ENCRYPTION_KEYSTORE} ]]; then
			certsFolder=$APPDIR/keystore
			KEYSTORETYPE=${BW_PROFILE_ENCRYPTION_KEYSTORETYPE}
			KEYSTORE=${BW_PROFILE_ENCRYPTION_KEYSTORE}
			KEYSTOREPASSWORD=${BW_PROFILE_ENCRYPTION_KEYSTOREPASSWORD}
			KEYALIAS=${BW_PROFILE_ENCRYPTION_KEYALIAS}
			KEYALIASPASSOWRD=${BW_PROFILE_ENCRYPTION_KEYALIASPASSWORD}
			BW_ENCRYPTED_PROFILE_CONFIG=" -Dbw.encryptedprofile.keystoreType="$KEYSTORETYPE" -Dbw.encryptedprofile.keystore="$certsFolder"/"$KEYSTORE" -Dbw.encryptedprofile.keystorePassword="$KEYSTOREPASSWORD" -Dbw.encryptedprofile.keyAlias="$KEYALIAS" -Dbw.encryptedprofile.keyAliasPassword="$KEYALIASPASSOWRD
			export BW_JAVA_OPTS=$BW_JAVA_OPTS" "$BW_ENCRYPTED_PROFILE_CONFIG
	fi
} 

export BW_OPTS=' --add-opens java.management/sun.management=ALL-UNNAMED --add-opens=java.base/jdk.internal.loader=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.naming/com.sun.jndi.ldap=ALL-UNNAMED --add-exports java.base/sun.security.ssl=ALL-UNNAMED --add-exports java.base/com.sun.crypto.provider=ALL-UNNAMED --add-exports java.management/com.sun.jmx.mbeanserver=ALL-UNNAMED '
export BW_JAVA_OPTS="$BW_JAVA_OPTS $BW_OPTS"

setLogLevel
checkJAVAHOME
memoryCalculator
checkJMXConfig
checkJavaGCConfig
checkThirdPartyInstallation
checkBWProfileEncryptionConfig

$JAVA_HOME/bin/java $BW_OPTS -cp `echo $APPDIR/tibco.home/bw*/*/system/shared/com.tibco.bwce.profile.resolver_*.jar`:`echo $APPDIR/tibco.home/bw*/*/system/shared/com.tibco.security.tibcrypt_*.jar`:`echo $APPDIR/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:`echo $APPDIR/tibco.home/bw*/*/system/shared/com.tibco.bw.tpcl.encryption.util_*`/lib/*:$JETTISON_JAR:.:`echo $APPDIR/tibco.home/bw*/*/system/shared/com.tibco.tpcl.logback_*`/*:$JAVA_HOME/lib com.tibco.bwce.profile.resolver.Resolver 1>/dev/null 2>&1
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to subsitute properties."
    exit 1 # terminate and indicate error
fi

if [[ ${BW_LOGLEVEL} ]]; then
	echo "After substitution...."
	cat $APPDIR/tmp/pcf.substvar
fi
printBWTable
exec ./tibco.home/bw*/*/bin/startBWAppNode.sh
