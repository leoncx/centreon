#!/bin/bash
#----
## @Synopsis	Install script for CentPluginsTraps
## @Copyright	Copyright 2008, Guillaume Watteeux
## @license	GPL : http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
## Install script for CentPluginsTraps
#----
# install script for CentPlugins
#################################
# SVN: $Id$

echo -e "\n$line"
echo -e "\t$(gettext "Start CentPlugins Traps Installation")"
echo -e "$line"

###### Check disk space
check_tmp_disk_space
[ "$?" -eq 1 ] && purge_centreon_tmp_dir

## Where is nagios_pluginsdir
locate_plugindir

## Locate centreon etc_dir
locate_centreon_etcdir
locate_snmp_etcdir
locate_init_d
locate_snmptt_bindir
locate_centpluginstraps_bindir

check_centreon_group
check_httpd_directory
check_user_apache

## Populate temporaty source directory
copyInTempFile 2>>$LOG_FILE

## Create temporary folder
log "INFO" "$(gettext "Create working directory")"
mkdir -p $TMP_DIR/final/bin
mkdir -p $TMP_DIR/work/bin
mkdir -p $TMP_DIR/work/snmptrapd
mkdir -p $TMP_DIR/final/snmptrapd
mkdir -p $TMP_DIR/work/snmptt
mkdir -p $TMP_DIR/final/snmptt

# Prepare init.d
DISTRIB=""
find_OS "DISTRIB"
if [ "$DISTRIB" = "DEBIAN" ]; then
	cp -f $BASE_DIR/snmptt/initd/debian/snmptt.init.d $TMP_DIR/src
	cp -f $BASE_DIR/snmptt/initd/debian/snmptt.default $TMP_DIR/src
else
	cp -f $BASE_DIR/snmptt/initd/redhat/snmptt.init.d $TMP_DIR/src
fi

## Change Macro in working dir
log "INFO" "$(gettext "Change macros for ")centFillTrapDB, centGenSnmpttConfFile, centTrapHandler-2.x"
flg_error=0
for FILE in  $TMP_DIR/src/bin/centFillTrapDB \
	$TMP_DIR/src/bin/centGenSnmpttConfFile \
	$TMP_DIR/src/bin/centTrapHandler-2.x; do
	${SED} -e 's|@CENTREON_ETC@|'"$CENTREON_ETC"'|g' \
		-e 's|@CENTREON_USER@|'"$CENTREON_USER"'|g' \
		-e 's|@CENTREON_VARLOG@|'"$CENTREON_LOG"'|g' \
		-e 's|@CENTREON_VARLIB@|'"$CENTREON_VARLIB"'|g' \
		"$FILE" > "$TMP_DIR/work/bin/`basename $FILE`"
	[ $? -ne 0 ] && flg_error=1
done
check_result $flg_error "$(gettext "Change macros for CentPluginsTraps")"

## Change macro for init scripts
log "INFO" "$(gettext "Change macros for ")init scripts"
flg_error=0
${SED} -e 's|@SNMPTT_BINDIR@|'"$SNMPTT_BINDIR"'|g' \
	-e 's|@SNMPTT_INI_FILE@|'"$SNMP_ETC/centreon_traps/snmptt.ini"'|g' \
	"$TMP_DIR/src/snmptt.init.d" > "$TMP_DIR/work/snmptt.init.d"
[ $? -ne 0 ] && flg_error=1
if [ "$DISTRIB" = "DEBIAN" ]; then
	${SED} -e 's|@SNMPTT_INI_FILE@|'"$SNMP_ETC/centreon_traps/snmptt.ini"'|g' \
		-e 's|"NO"|"YES"|g' \
		"$TMP_DIR/src/snmptt.default" > "$TMP_DIR/work/snmptt.default"
	[ $? -ne 0 ] && flg_error=1
fi
check_result $flg_error "$(gettext "Change macros for init scripts")"

## Copy in final dir
log "INFO" "$(gettext "Copying Traps binaries in final directory")"
cp -f $TMP_DIR/work/bin/* $TMP_DIR/final/bin >> $LOG_FILE 2>&1

## Copy init scripts in final dir
cp $TMP_DIR/work/snmptt.init.d $TMP_DIR/final/snmptt.init.d
if [ "$DISTRIB" = "DEBIAN" ]; then
	cp $TMP_DIR/work/snmptt.default $TMP_DIR/final/snmptt.default
fi

## Install the plugins traps binaries
log "INFO" "$(gettext "Installing the plugins Traps binaries")"
$INSTALL_DIR/cinstall $cinstall_opts \
	-m 755 -p $TMP_DIR/final/bin \
	$TMP_DIR/final/bin/* $CENTPLUGINSTRAPS_BINDIR >> $LOG_FILE 2>&1
check_result $? "$(gettext "Installing the plugins Trap binaries ")"

# Create a SNMP config
## Create centreon_traps directory
$INSTALL_DIR/cinstall $cinstall_opts \
	-u $WEB_USER -g $CENTREON_GROUP -d 775 \
	$SNMP_ETC/centreon_traps >> $LOG_FILE 2>&1

log "INFO" "$(gettext "Backup all your snmp files")"
# Backup snmptrapd.conf if exist
if [ -e "$SNMP_ETC/snmptrapd.conf" ] ; then
	log "INFO" "$(gettext "Backup") : $SNMP_ETC/snmptrapd.conf"
	mv $SNMP_ETC/snmptrapd.conf $SNMP_ETC/snmptrapd.conf.bak-centreon
fi
# Backup snmptt.ini 
if [ -e "$SNMP_ETC/centreon_traps/snmptt.ini" ] ; then
	log "INFO" "$(gettext "Backup") : $SNMP_ETC/centreon_traps/snmptt.ini"
	mv $SNMP_ETC/centreon_traps/snmptt.ini \
		$SNMP_ETC/centreon_traps/snmptt.ini.bak-centreon
fi

# Backup snmptt init if exists
if [ -e "$INIT_D/snmptt" ]; then
	log "INFO" "$(gettext "Backup") : $INIT_D/snmptt"
	mv $INIT_D/snmptt $INIT_D/snmptt.bak
fi

# Backup snmp.conf if exist
if [ -e "$SNMP_ETC/snmp.conf" ] ; then
	log "INFO" "$(gettext "Backup") : $SNMP_ETC/snmp.conf"
	mv $SNMP_ETC/snmp.conf $SNMP_ETC/snmp.conf.bak-centreon
fi

# Backup snmptt if exist
if [ -e "$SNMPTT_BINDIR/snmptt" ] ; then
	log "INFO" "$(gettext "Backup") : $SNMPTT_BINDIR/snmptt"
	mv $SNMPTT_BINDIR/snmptt $SNMPTT_BINDIR/snmptt.bak-centreon
fi

# Backup snmptthandler if exist
if [ -e "$SNMPTT_BINDIR/snmptthandler" ]; then
	log "INFO" "$(gettext "Backup") : $SNMPTT_BINDIR/snmptthandler"
	mv $SNMPTT_BINDIR/snmptthandler \
		$SNMPTT_BINDIR/snmptthandler.bak-centreon
fi

# Backup snmpttconvertmib if exist
if [ -e "$SNMPTT_BINDIR/snmpttconvertmib" ] ; then
	log "INFO" "$(gettext "Backup") : $SNMPTT_BINDIR/snmpttconvertmib"
	mv $SNMPTT_BINDIR/snmpttconvertmib \
		$SNMPTT_BINDIR/snmpttconvertmib.bak-centreon
	check_result $?  "$(gettext "Backup all your snmp files")"
fi

log "INFO" "$(gettext "Installing snmptt")"
# Change macros on snmptrapd.conf
${SED} -e 's|@SNMPTT_INI_FILE@|'"$SNMP_ETC/centreon_traps/snmptt.ini"'|g' \
	-e 's|@SNMPTT_BINDIR@|'"$SNMPTT_BINDIR"'|g' \
	$TMP_DIR/src/snmptrapd/snmptrapd.conf > \
	$TMP_DIR/work/snmptrapd/snmptrapd.conf 2>>$LOG_FILE
check_result $? "$(gettext "Change macros for snmptrapd.conf")"

# Change macros on snmptt.ini
# TODO: SNMPTT_LOG, SNMPTT_SPOOL
${SED} -e 's|@SNMP_ETC@|'"$SNMP_ETC"'|g' \
	$TMP_DIR/src/snmptt/snmptt.ini > $TMP_DIR/work/snmptt/snmptt.ini \
	2>>$LOG_FILE
check_result $? "$(gettext "Change macros for snmptt.ini")"

## Copy in final dir
log "INFO" "$(gettext "Copying traps config in final directory")"
cp -r $TMP_DIR/work/snmptrapd/snmptrapd.conf \
	$TMP_DIR/final/snmptrapd/snmptrapd.conf >> $LOG_FILE 2>&1
cp $TMP_DIR/work/snmptt/snmptt.ini \
	$TMP_DIR/final/snmptt/snmptt.ini >> $LOG_FILE 2>&1
cp $TMP_DIR/src/snmptrapd/snmp.conf \
	$TMP_DIR/final/snmptrapd/snmp.conf >> $LOG_FILE 2>&1
cp $TMP_DIR/src/snmptt/snmptt \
	$TMP_DIR/final/snmptt/snmptt >> $LOG_FILE 2>&1
cp $TMP_DIR/src/snmptt/snmptthandler \
	$TMP_DIR/final/snmptt/snmptthandler >> $LOG_FILE 2>&1
cp $TMP_DIR/src/snmptt/snmpttconvertmib \
	$TMP_DIR/final/snmptt/snmpttconvertmib >> $LOG_FILE 2>&1

## Install init scripts
log "INFO" "$(gettext "SNMPTT init script installed")"
$INSTALL_DIR/cinstall $cinstall_opts -m 755 \
	$TMP_DIR/final/snmptt.init.d \
	$INIT_D/snmptt >> $LOG_FILE 2>&1
check_result $? "$(gettext "SNMPTT init script installed")"
if [ "$DISTRIB" = "DEBIAN" ]; then
	log "INFO" "$(gettext "SNMPTT default script installed")"
	$INSTALL_DIR/cinstall $cinstall_opts -m 755 \
		$TMP_DIR/final/snmptt.default \
		/etc/default/snmptt >> $LOG_FILE 2>&1
	check_result $? "$(gettext "SNMPTT default script installed")"
fi
install_init_service "snmptt" | tee -a $LOG_FILE

## Install all config file
log "INFO" "$(gettext "Install") : snmptrapd.conf"
$INSTALL_DIR/cinstall $cinstall_opts -m 644 \
	$TMP_DIR/final/snmptrapd/snmptrapd.conf \
	$SNMP_ETC/snmptrapd.conf >> $LOG_FILE 2>&1
check_result $? "$(gettext "Install") : snmptrapd.conf"

log "INFO" "$(gettext "Install") : snmp.conf"
$INSTALL_DIR/cinstall $cinstall_opts -m 644 \
	$TMP_DIR/final/snmptrapd/snmp.conf \
	$SNMP_ETC/snmp.conf >> $LOG_FILE 2>&1
check_result $? "$(gettext "Install") : snmp.conf"

log "INFO" "$(gettext "Install") : snmptt.ini"
$INSTALL_DIR/cinstall $cinstall_opts -u $WEB_USER -g $CENTREON_GROUP -m 644 \
	$TMP_DIR/final/snmptt/snmptt.ini \
	$SNMP_ETC/centreon_traps/snmptt.ini >> $LOG_FILE 2>&1
check_result $? "$(gettext "Install") : snmptt.ini"

log "INFO" "$(gettext "Install") : snmptt"
$INSTALL_DIR/cinstall $cinstall_opts -m 755 \
	$TMP_DIR/final/snmptt/snmptt \
	$SNMPTT_BINDIR/snmptt >> $LOG_FILE 2>&1
check_result $? "$(gettext "Install") : snmptt"

log "INFO" "$(gettext "Install") : snmptthandler"
$INSTALL_DIR/cinstall $cinstall_opts -m 755 \
	$TMP_DIR/final/snmptt/snmptthandler \
	$SNMPTT_BINDIR/snmptthandler >> $LOG_FILE 2>&1
check_result $? "$(gettext "Install") : snmptthandler"

log "INFO" "$(gettext "Install") : snmpttconvertmib"
$INSTALL_DIR/cinstall $cinstall_opts -m 755 \
	$TMP_DIR/final/snmptt/snmpttconvertmib \
	$SNMPTT_BINDIR/snmpttconvertmib >> $LOG_FILE 2>&1
check_result $? "$(gettext "Install") : snmpttconvertmib"

log "INFO" "$(gettext "Install") : spool directory"
$INSTALL_DIR/cinstall $cinstall_opts -d 775 \
	/var/spool/snmptt

if [ -f $CENTREON_ETC/conf.pm ] ; then 
	log "INFO" "$(gettext "Generate SNMPTT configuration")"
	$CENTPLUGINSTRAPS_BINDIR/centGenSnmpttConfFile >> $LOG_FILE 2>&1
	check_result $? "$(gettext "Generate SNMPTT configuration")"
fi

# Create traps directory in nagios pluginsdir
#$INSTALL_DIR/cinstall $cinstall_opts -d 664 \
#	-g $WEB_GROUP \
#	$NAGIOS_PLUGIN/traps

#echo_success "$(gettext "Install SNMPTT")" "$ok"
## TODO : comment ^^ , log and echo_*
#	: copy centreon.pm and centreon.conf if not exist


