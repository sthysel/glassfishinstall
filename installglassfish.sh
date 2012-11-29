#!/bin/bash
# This script will install glassfish and all the domains listed in DOMAINS

# use the shflags library to handle command line parameters
. ./shflags

THIS_VERSION=2.0.1

declare DOMAINNAME
declare GLASSFISH_VERSION
declare PORT_OFFSET # port offset for concurrent glassfish versions

# glassfish version config
#
# NOTE: This script supports the installation of multiple versions of glassfish.
#       To achieve this, modify the 'portoffset' property below for the new version
#       of glassfish - this will ensure that the new version's domains do not
#       conflict with those of the existing installation.
#
#       eg ["portoffset"]=20
declare -A GF_VERSION_CONFIG=(
    ["3.0.1"]='(
        ["unzipedfoldername"]="glassfishv3"
        ["portoffset"]=0
    )'
    ["3.1.1"]='(
        ["unzipedfoldername"]="glassfish3"
        ["portoffset"]=0
    )'
    ["3.1.2"]='(
        ["unzipedfoldername"]="glassfish3"
        ["portoffset"]=0
    )'
    ["3.1.2.2"]='(
        ["unzipedfoldername"]="glassfish3"
        ["portoffset"]=0
    )'
)

DEFINE_string domain 'Sthysel' "Glassfish Domain" d
DEFINE_string version '3.1.2.2' "Glassfish Version" v
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

checkDomain() {
    DOMAINNAME=${FLAGS_domain}

    # check domain
    if [[ ${DOMAINNAME} = "" ]]
    then
        echo Please select domain: i.e: ${0} TheShire
        flags_help
        exit 1
    fi
}

checkVersion() {
    # check version
    for v in "${!GF_VERSION_CONFIG[@]}"
    do 
        if [[ $v = ${FLAGS_version} ]] 
        then 
            echo "Version $v selected"
            GLASSFISH_VERSION=$v
            declare -A gfv=${GF_VERSION_CONFIG[$v]}
            PORT_OFFSET=${gfv[portoffset]}
            return 0
        fi
    done
    echo "Version ${FLAGS_version} of glassfish is unknown"
    flags_help
    exit 1
}

checkDomain
checkVersion

echo "Installing Glassfish ${GLASSFISH_VERSION} for domain ${DOMAINNAME}"

export JAVA_HOME=/opt/javahome

APPLICATION_ROOT=/opt
DATA_ROOT=/opt/data
NODENAME=$(uname -n)
INIT_DIR="/etc/init.d/"

USER_HOME=/home
SHELL=/bin/bash

DERBY_HOME="/opt/derby"
GLASSFISH_HOME="/opt/glassfishhome"

GLASSFISH_INSTALL_PACKAGE="glassfish-${GLASSFISH_VERSION}.zip"

# glashfish system user
GLASSFISH_ID="61005"
GLASSFISH_NAME="glassfish"
GLASSFISH_FULL_NAME="Glassfish Application Server account"

GLASSFISH_ROOT=${APPLICATION_ROOT}/${GLASSFISH_NAME}
GLASSFISH_DATA=${DATA_ROOT}/${GLASSFISH_NAME}
GLASSFISH_DOMAINS=${GLASSFISH_DATA}/${GLASSFISH_VERSION}/domains
GLASSFISH_NODES=${GLASSFISH_DATA}/${GLASSFISH_VERSION}/nodes

PASSWORD_FILE="asadminpass"

PREFIX="glassfish-${GLASSFISH_VERSION}-domain" 

# Domain detail
declare -A DOMAINS=( 
    [Sthysel]='(
        [init]="${PREFIX}.sthysel" 
        [portbase]="8000"
        [description]="The Domain of Sthysel"
    )'
    [TheShire]='( 
        [init]="${PREFIX}.theshire"
        [portbase]="9000"
        [description]="The Shire"
    )'
    [Mordor]='( 
        [init]="${PREFIX}.Mordor"
        [portbase]="9100"
        [description]="Mordor"
    )'
)


ADMIN_PORT="48"
WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ASSEMBLE_FOLDER=${WORKING_DIR}/assemble # folder to assemble glassfish in
GF_ASSEMBLY=${ASSEMBLE_FOLDER}/${GLASSFISH_VERSION}
GF_ASSEMBLY_DRIVERS=${GF_ASSEMBLY}/drivers/
#GF_ASSEMBLY_INITS=${GF_ASSEMBLY}/initscripts/

GF_DEPLOY_TARGET=${GLASSFISH_ROOT}/${GLASSFISH_VERSION}
GLASSFISH_BIN=${GF_DEPLOY_TARGET}/glassfish/bin/

# Creates a user (and a group for that user) with the provided ID and name.
# $1: ID
# $2: User Name
# $3: Full User Name
# "${GLASSFISH_ID}" "${GLASSFISH_NAME}" "${GLASSFISH_FULL_NAME}"
createGlassfishUser() {
    grep -E ${GLASSFISH_ID} /etc/passwd > /dev/null
    if [[ "$?" = "0" ]]
        then
            echo "Not creating user ${GLASSFISH_NAME}... user with ID ${GLASSFISH_ID} already exists"
        else
            echo "User ${GLASSFISH_NAME} with ID ${GLASSFISH_ID} does not exists. Creating..."
            adduser --uid ${GLASSFISH_ID} --shell ${SHELL} --force-badname --disabled-login --gecos "${GLASSFISH_FULL_NAME},,," ${GLASSFISH_NAME}
            echo ${GLASSFISH_NAME}:forgetmenow | chpasswd
            passwd --expire ${GLASSFISH_NAME}
    fi
}

createASENVConf() {
    ASENV_CONF=${GF_DEPLOY_TARGET}/glassfish/config/asenv.conf
    echo "Creating custom asenv.conf in ${ASENV_CONF}"
    rm ${ASENV_CONF}

# cut $ pasted orifinal licence here
cat << EOF > ${ASENV_CONF}
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2004-2010 Oracle and/or its affiliates. All rights reserved.
#
# The contents of this file are subject to the terms of either the GNU
# General Public License Version 2 only ("GPL") or the Common Development
# and Distribution License("CDDL") (collectively, the "License").  You
# may not use this file except in compliance with the License.  You can
# obtain a copy of the License at
# https://glassfish.dev.java.net/public/CDDL+GPL_1_1.html
# or packager/legal/LICENSE.txt.  See the License for the specific
# language governing permissions and limitations under the License.
#
# When distributing the software, include this License Header Notice in each
# file and include the License file at packager/legal/LICENSE.txt.
#
# GPL Classpath Exception:
# Oracle designates this particular file as subject to the "Classpath"
# exception as provided by Oracle in the GPL Version 2 section of the License
# file that accompanied this code.
#
# Modifications:
# If applicable, add the following below the License Header, with the fields
# enclosed by brackets [] replaced by your own identifying information:
# "Portions Copyright [year] [name of copyright owner]"
#
# Contributor(s):
# If you wish your version of this file to be governed by only the CDDL or
# only the GPL Version 2, indicate your decision by adding "[Contributor]
# elects to include this software in this distribution under the [CDDL or GPL
# Version 2] license."  If you don't indicate a single choice of license, a
# recipient has the option to distribute your version of this file under
# either the CDDL, the GPL Version 2 or to extend the choice of license to
# its licensees as provided above.  However, if you add GPL Version 2 code
# and therefore, elected the GPL Version 2 license, then the option applies
# only if the new code is made subject to such option by the copyright
# holder.
#

#
#                       * * *    N O T E     * * *
#
# Although the lines in this file are formatted as environment
# variable assignments, this file is NOT typically invoked as a script 
# from another script to define these variables.  Rather, this file is read 
# and processed by a server as it starts up.  That scanning code resolves 
# the relative paths against the GlassFish installation directory.
#
# Yet, this file is also where users of earlier versions have sometimes added 
# a definition of AS_JAVA to control which version of Java GlassFish
# should use.  As a result, in order to run a user-specified version of Java, 
# the asadmin and appclient scripts do indeed invoke this file as a 
# script - but ONLY to define AS_JAVA.  Any calling script should not
# rely on the other settings because the relative paths will be resolved 
# against the current directory when the calling script is run, not the 
# installation directory of GlassFish, and such resolution will not work 
# correctly unless the script happens to be run from the GlassFish installation
# directory.
#
EOF

    echo "# Installed by $0 on $(date)" >> ${ASENV_CONF}
    echo "#AS_JAVA=\${JAVA_HOME}" >> ${ASENV_CONF}
    echo "AS_JAVA=/opt/javahome/" >> ${ASENV_CONF}
    echo "AS_IMQ_LIB=\"../../mq/lib\"" >> ${ASENV_CONF}
    echo "AS_IMQ_BIN=\"../../mq/bin\"" >> ${ASENV_CONF}
    echo "AS_CONFIG=\"../config\"" >> ${ASENV_CONF}
    echo "AS_INSTALL=".."" >> ${ASENV_CONF}
    echo "AS_DEF_DOMAINS_PATH=\"$GLASSFISH_DOMAINS\"" >> ${ASENV_CONF}
    echo "AS_DEF_NODES_PATH=\"$GLASSFISH_NODES\"" >> ${ASENV_CONF}
    echo "AS_DERBY_INSTALL=\"$DERBY_HOME\"" >> ${ASENV_CONF}
}

prepareDirs() {
    DIRS="${GLASSFISH_ROOT} ${GLASSFISH_INSTANCES} ${GLASSFISH_DATA} ${GLASSFISH_DATA}/${GLASSFISH_VERSION}  ${GLASSFISH_DOMAINS} ${GLASSFISH_NODES}"
    for dir in ${DIRS}
    do
    echo "Creating ${dir}"
    mkdir -p ${dir}
    done
}

deployGlassfish() {
    echo "Moving glassfish to installation location ${GF_DEPLOY_TARGET}"
    rm -rf ${GF_DEPLOY_TARGET}
    mv ${GF_ASSEMBLY} ${GF_DEPLOY_TARGET}

    echo "Creating symbolic links for Glassfish installation..."
    unlink ${GLASSFISH_HOME}
    ln -s ${GF_DEPLOY_TARGET} ${GLASSFISH_HOME}
}

moveUnzippedFolder() {
    declare -A gf_current_config=${GF_VERSION_CONFIG[${GLASSFISH_VERSION}]}
    local fname=${gf_current_config[unzipedfoldername]}
    mv ${fname} "./${GLASSFISH_VERSION}"
}

unpackGlassfish() {
    rm -fr ${ASSEMBLE_FOLDER}
    mkdir -p ${ASSEMBLE_FOLDER}
    echo "Unpacking Glassfish..."
    unzip -q -d ${ASSEMBLE_FOLDER}/ "${WORKING_DIR}/${GLASSFISH_INSTALL_PACKAGE}"
    cd ${ASSEMBLE_FOLDER} 

    moveUnzippedFolder

    rm -rf "./${GLASSFISH_VERSION}/javadb"
    rm -rf "./${GLASSFISH_VERSION}/glassfish/domains"
    #ln -s "$DERBY" "./$GLASSFISH_VERSION/javadb"
}

# add drivers to distribution, they will be copied to the correct domains later
addDrivers() {
    echo "Adding JDBC drivers to ${GF_ASSEMBLY_DRIVERS}"
    cp -r ${WORKING_DIR}/drivers/ ${GF_ASSEMBLY_DRIVERS}
}


# $1: Domain Name 
deployInitScript() {
    local name=$1
    echo "Deploying init script for ${name}"
    declare -A domain=${DOMAINS[${name}]}
    local init=${domain[init]}
    local targetinit=${INIT_DIR}/${init}
    echo "Init scrip for ${name} is ${targetinit}"
    echo "Deploying ${targetinit}"
    update-rc.d -f ${init} remove

cat << EOINTITF > ${targetinit}
#! /bin/sh
### BEGIN INIT INFO
# Provides:          glassfish.domain.${name}
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start Glassfish Domain ${name} at boot time.
# Description:       Start Glassfish Domain ${name} at boot time.
### END INIT INFO

GLASSFISH_HOME="${GF_DEPLOY_TARGET}"
GLASSFISH_CLI="\$GLASSFISH_HOME/bin/asadmin"
START_DOMAIN="start-domain"
STOP_DOMAIN="stop-domain"
RESTART_DOMAIN="restart-domain"
DOMAIN="${name}"

JAVA_HOME="/opt/javahome"
PATH="\$JAVA_HOME/bin:\$PATH"


do_start() {
        if [ -x "\$GLASSFISH_CLI" ]; then
                "\$GLASSFISH_CLI" "\$START_DOMAIN" "\$DOMAIN"
                return \$?
        fi
}

do_stop() {
        if [ -x "\$GLASSFISH_CLI" ]; then
                "\$GLASSFISH_CLI" "\$STOP_DOMAIN" "\$DOMAIN"
                return \$?
        fi
}

do_restart() {
        if [ -x "\$GLASSFISH_CLI" ]; then
                "\$GLASSFISH_CLI" "\$RESTART_DOMAIN" "\$DOMAIN"
                return \$?
        fi
}

case "\$1" in
    start)
        do_start
        ;;
    reload|force-reload)
        echo "Error: argument '\$1' not supported" >&2
        exit 3
        ;;
    stop)
        do_stop
        ;;
    restart)
        do_restart
      ;;
    *)
        echo "Usage: \$0 start|stop|restart" >&2
        exit 3
        ;;
esac

EOINTITF

    chmod +x ${targetinit}
    update-rc.d ${init} start 20 2 3 4 . start 30 5 . stop 80 0 1 6 .
}

# $1: Domain Name
makeDomain() {
    local name=$1
    echo "Removing old domain called ${name}"
    ${GLASSFISH_BIN}/asadmin stop-domain ${name}
    rm -fr ${GLASSFISH_DOMAINS}/${name}
    echo "Adding domain: ${name}"
    local PASSWORDFILE=${WORKING_DIR}/${PASSWORD_FILE}
    declare -A domain=${DOMAINS[$name]}
    local init=${domain[init]}
    local portbase=${domain[portbase]}
    local newportbase=$((${portbase}+${PORT_OFFSET}))
    echo "Port Base: " [${newportbase}]
    CMD="${GLASSFISH_BIN}/asadmin --user admin --passwordfile ${PASSWORDFILE} create-domain --portbase ${newportbase} --domaindir ${GLASSFISH_DOMAINS} --checkports=false --savemasterpassword=true --savelogin=true ${name}"
    echo ${CMD}
    $CMD

    if [[ $? != 0 ]]
    then
    echo ${JAVA_HOME}
    echo ${CMD}
    echo "${GLASSFISH_CLI} failed on error $?"
    exit 1
    fi
}

# $1: Domain Name
copyDriversToDomain() {
    local name=$1
    echo "Deploying JDBC drivers to ${name}"
    TARGET=${GLASSFISH_DOMAINS}/${name}/lib/ext/
    if [[ -d ${TARGET} ]]
    then
    rsync -avr ${GF_DEPLOY_TARGET}/drivers/*.jar ${TARGET}/
    else
    echo "Directory ${TARGET} does not exist. Exiting"
    exit 1
    fi
}

# TODO currently unused
deployDomains() {
    echo "Adding domain..."
    for d in "${!DOMAINS[@]}"
    do
    makeDomain $d
    copyDriversToDomain $d
    deployInitScript $d
    done
}

# $1: user supplied domain name
deployDomain() {
    local domain=$1
    makeDomain $domain
    copyDriversToDomain $domain
    deployInitScript $domain
}

# $1: domain name
enableSecureAdministration() {
    local name=$1
    declare -A domain=${DOMAINS[$name]}
    local portbase=${domain[portbase]}
    echo "Enabling secure administration of domain ${name}..."
    ${GLASSFISH_BIN}/asadmin start-domain ${name}
    ${GLASSFISH_BIN}/asadmin --host localhost --port $((${portbase}+${ADMIN_PORT}+${PORT_OFFSET})) enable-secure-admin
    ${GLASSFISH_BIN}/asadmin stop-domain ${name}
    ${GLASSFISH_BIN}/asadmin start-domain ${name}
}

secureInstallDirs() {
    echo "Securing installation directories..."
    # glassfish install
    chown -R "root":${GLASSFISH_NAME} ${GLASSFISH_ROOT}
    chmod -R 770 ${GLASSFISH_ROOT}
    # glassfish data
    chown -R "root":${GLASSFISH_NAME} ${GLASSFISH_DATA}
    chmod -R 770 ${GLASSFISH_DATA}
}

# prepare the folder to be distributed
prepareDistribution() {
    unpackGlassfish
    addDrivers
}

# deploy the distribution
deploy() {
    createGlassfishUser 
    prepareDirs
    deployGlassfish
    createASENVConf
    deployDomain ${DOMAINNAME}
    # secureInstallDirs
    enableSecureAdministration ${DOMAINNAME}
}

prepareDistribution
deploy

echo "Installation complete"

exit 0

