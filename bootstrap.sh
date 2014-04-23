#!/usr/bin/env bash 

#
# Setup variable to track installation logging
#
LOG="$PWD/install.log"

# Explicitly set the HOME variable
export HOME=~vagrant

log() {
  typeset -r msg=$1
  echo "$(date): $msg"
}

#
# Update packages 
#
log "Updating packages..."

#
# Create standard directories
#
DOWNLOADS_DIR=/downloads
TOOLS_DIR=${HOME}/tools
mkdir -p ${DOWNLOADS_DIR}
# Create a directory to install all local non-RPM distributions
mkdir -p ${TOOLS_DIR}

#
# Packages for sane administration
#
log "Install system adminstration packages..."
sudo yum install -y man wget >> $LOG 2>&1

log "Install EPEL gpg keys and package..."
wget https://fedoraproject.org/static/0608B895.txt >> $LOG 2>&1
sudo mv 0608B895.txt /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 >> $LOG 2>&1
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 >> $LOG 2>&1
sudo rpm -ivh http://mirrors.mit.edu/epel/6/x86_64/epel-release-6-8.noarch.rpm >> $LOG 2>&1

#
# Install packages required for Nagios
#
log "Installing required packages for Nagios..."
sudo yum install -y wget httpd php gcc glibc glibc-common gd gd-devel make net-snmp mailx >> $LOG 2>&1

#
# Required packages for RVM
#
log "Install required packages for RVM..."
sudo yum install -y patch libyaml-devel libffi-devel autoconf gcc-c++ patch readline-devel openssl-devel automake libtool bison >> $LOG 2>&1

#
# Required packages for Boundary Event Plugins
#
log "Install required packages for Boundary Event Integration..."
sudo yum install -y curl unzip >> $LOG 2>&1

#
# Required packages for Boundary Event SDK
#
log "Install required packages for Boundary Event SDK..."
sudo yum install -y java-1.7.0-openjdk git >> $LOG 2>&1

# Add Java bin directory in the path
echo "" >> ${HOME}/.bash_profile
echo '# java configuration' >> ${HOME}/.bash_profile
echo "JAVA_HOME="/usr/lib/jvm/jre-1.7.0-openjdk.x86_64 >> ${HOME}/.bash_profile
echo 'export JAVA_HOME ' >> ${HOME}/.bash_profile
echo "" >> ${HOME}/.bash_profile

log "Install maven for Boundary Event SDK..."

MAVEN_DIR=apache-maven-3.2.1
MAVEN_TAR=${MAVEN_DIR}-bin.tar.gz
MAVEN_URI=http://apache.cs.utah.edu/maven/maven-3/3.2.1/binaries/${MAVEN_TAR}

# Fetch the distribution
pushd ${DOWNLOADS_DIR} > /dev/null 2>&1
wget ${MAVEN_URI} >> $LOG 2>&1
popd > /dev/null 2>&1

pushd ${TOOLS_DIR} > /dev/null 2>&1
tar xvf ${DOWNLOADS_DIR}/${MAVEN_TAR} >> $LOG 2>&1
popd > /dev/null 2>&1

# Add Maven bin directory in the path
echo "# Add maven to path" >> ${HOME}/.bash_profile
echo "MAVEN_INSTALL="${TOOLS_DIR}/${MAVEN_DIR} >> ${HOME}/.bash_profile
echo 'export PATH=$PATH:$MAVEN_INSTALL/bin' >> ${HOME}/.bash_profile
echo "" >> ${HOME}/.bash_profile

# Install the Boundary Event SDK
log "Install Boundary Event SDK..."
SDK_LOG="$PWD/boundary_sdk_log.$(date +"%Y-%m-%dT%H:%m")"
source $HOME/.bash_profile

git clone https://github.com/boundary/boundary-event-sdk.git > $SDK_LOG 2>&1
pushd boundary-event-sdk >> $SDK_LOG 2>&1
bootstrap.sh >> $SDK_LOG 2>&1
bash bootstrap.sh  >> $SDK_LOG 2>&1
source bsdk-env.sh  >> $SDK_LOG 2>&1
mvn install >> $SDK_LOG 2>&1
popd  >> $SDK_LOG 2>&1

NAGIOS_FILE=$HOME/nagios

if [ -r ${NAGIOS_FILE} ]
then
#
# Add the nagios user and groups
#
NAGIOS_USER=nagios
NAGIOS_GROUP=nagios
NAGIOS_CMD_GROUP=nagcmd
log "Add required users and groups..."
sudo useradd ${NAGIOS_USER} >> $LOG 2>&1
groupadd ${NAGIOS_CMD_GROUP} >> $LOG 2>&1
usermod -a -G ${NAGIOS_CMD_GROUP} ${NAGIOS_USER} >> $LOG 2>&1
echo "nagios" | sudo passwd nagios --stdin >> $LOG 2>&1

#
# Download the Nagios distribution
#

log "Downloading Nagios core and plugins..."

NAGIOS_CORE_DIR="nagios-3.5.1"
NAGIOS_PLUGINS_DIR="nagios-plugins-2.0"
NAGIOS_CORE_TAR="${NAGIOS_CORE_DIR}.tar.gz"
NAGIOS_PLUGINS_TAR="${NAGIOS_PLUGINS_DIR}.tar.gz"

# Nagios core
wget http://prdownloads.sourceforge.net/sourceforge/nagios/${NAGIOS_CORE_TAR} >> $LOG 2>&1

# Nagios plugins
wget http://nagios-plugins.org/download/${NAGIOS_PLUGINS_TAR} >> $LOG 2>&1

# Extract
log "Extract Nagios core and plugins..."
tar xvf "${NAGIOS_CORE_TAR}" >> $LOG 2>&1
tar xvf "${NAGIOS_PLUGINS_TAR}" >> $LOG 2>&1

#
# Create directory to install Nagios
#
log "Create Nagios install directory..."
NAGIOS_INSTALL=/usr/local/nagios
NAGIOS_INSTALL_PERM=0755
sudo mkdir ${NAGIOS_INSTALL} >> $LOG 2>&1 
sudo chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_INSTALL} >> $LOG 2>&1
sudo chmod ${NAGIOS_INSTALL_PERM} ${NAGIOS_INSTALL} >> $LOG 2>&1

# Build and install Nagios

pushd nagios > /dev/null 2>&1
log "Build Nagios..."
./configure --with-command-group=${NAGIOS_CMD_GROUP}  >> $LOG 2>&1
make all >> $LOG 2>&1
log "Install Nagios..."
make install >> $LOG 2>&1
sudo make install-init >> $LOG 2>&1
make install-config >> $LOG 2>&1
make install-commandmode >> $LOG 2>&1
sudo make install-webconf  >> $LOG 2>&1
# Copy contributions
log "Install contributed event handlers..."
cp -R contrib/eventhandlers ${NAGIOS_INSTALL}/libexec >> $LOG 2>&1
sudo chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_INSTALL}/libexec/eventhandlers >> $LOG 2>&1
popd > /dev/null 2>&1

log "Validate nagios configuration..."
${NAGIOS_INSTALL}/bin/nagios -v ${NAGIOS_INSTALL}/etc/nagios.cfg >> $LOG 2>&1

# Start the Nagios and httpd services
log "Start nagios and httpd..."
sudo /etc/init.d/nagios start >> $LOG 2>&1

sudo /etc/init.d/httpd start >> $LOG 2>&1

# Define our administrative user and password
log "Configure nagios admin..."
htpasswd -b -c ${NAGIOS_INSTALL}/etc/htpasswd.users nagiosadmin nagios123 >> $LOG 2>&1

log "Build Nagios plugins..."
pushd "${NAGIOS_PLUGINS_DIR}" >> $LOG 2>&1
./configure --with-nagios-user=${NAGIOS_USER} --with-nagios-group=${NAGIOS_GROUP} >> $LOG 2>&1
make  >> $LOG 2>&1
make install >> $LOG 2>&1
popd  >> $LOG 2>&1


# Configure startup
log "Configuring nagios and httpd startup..."
sudo chkconfig --add nagios >> $LOG 2>&1
sudo chkconfig --level 35 nagios on >> $LOG 2>&1
sudo chkconfig --add httpd >> $LOG 2>&1
sudo chkconfig --level 35 httpd on >> $LOG 2>&1
fi

log "Details of the installation have been logged to $LOG"

