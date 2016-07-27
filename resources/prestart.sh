#!/bin/bash
# Copyright (c) 2016, TIBCO Software Inc. All rights reserved.
# You may not use this file except in compliance with the license 
# terms contained in the TIBCO License.md file provided with this file.

printBWTable ()
{
	echo "---------------> Product Inventory"
	echo "---------------------------------------------------------"
	echo "Name      = "`grep product.name $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "Version   = "`grep product.version $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "Build     = "`grep product.build $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "Vendor    = "`grep product.vendor $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "BuildDate = "`grep product.build.date $APPDIR/tibco.home/bw*/*/system/lib/bw.ini|cut -d'=' -f 2`
	echo "---------------------------------------------------------"
mkdir -p $APPDIR/tibco.home/addons
pluginFolder=$APPDIR/tibco.home/addons
if [ "$(ls $pluginFolder | grep lib)"  ]; then
for name in $(find $pluginFolder/lib -type f); 
do	
	# filter out hidden files
	if [[  "$(basename $name )" != .* ]];then
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
export APPDIR=/home/vcap/app
export BW_KEYSTORE_PATH=$HOME/keystore
export MALLOC_ARENA_MAX=4
chmod 755 $APPDIR/tibco.home/bw*/*/bin/bwappnode
chmod 755 $APPDIR/tibco.home/bw*/*/bin/startBWAppNode.sh
sed -i.bak "s#_APPDIR_#$APPDIR#g" $APPDIR/tibco.home/bw*/*/config/appnode_config.ini
if [ "$(ls $APPDIR/tibco.home/bw*/*/ext/shared)"  ]; then 
	sed -i "s#_APPDIR_#$APPDIR#g" $APPDIR/tibco.home/bw*/*/ext/shared/addons.link	
fi
if [ "$(ls $APPDIR/tibco.home/addons/lib)"  ]; then 
	sed -i "s#_APPDIR_#$APPDIR#g" $APPDIR/tibco.home/bw*/*/bin/bwappnode.tra	
fi


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
JRE_VERSION=`ls $APPDIR/tibco.home/tibcojre64/`
jreLink=tibcojre64/$JRE_VERSION
chmod +x $APPDIR/tibco.home/$jreLink/bin/java
chmod +x $APPDIR/tibco.home/$jreLink/bin/javac
$APPDIR/tibco.home/$jreLink/bin/javac -cp $JETTISON_JAR:.:$APPDIR/tibco.home/$jreLink/lib:$APPDIR/tibco.home/$jreLink/bin ProfileTokenResolver.java
$APPDIR/tibco.home/$jreLink/bin/java -cp $JETTISON_JAR:.:$APPDIR/tibco.home/$jreLink/lib:$APPDIR/tibco.home/$jreLink/bin ProfileTokenResolver

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
