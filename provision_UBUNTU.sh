#!/usr/bin/env bash 

#
# Setup variable to track installation logging
#
LOG="$PWD/install.log"


case $(cat /proc/version | tr '[:lower:]' '[:upper:]' | tr ' ' '_') in
*UBUNTU*)
  sdk_target=UBUNTU
  ;;
*RED_HAT*)
  sdk_target=RED_HAT
  ;;
*)
  echo "Unknown SDK Target exiting"
  exit 1
  ;;
esac

# Explicitly set the HOME variable
export HOME=~vagrant

log() {
  typeset -r msg=$1
  echo "$(date): $msg"
}

addUser_RED_HAT() {
  typeset -r user=$1
  typeset -r group=$1
  typeset -r password=$1
#
# Add the sdk user and groups
#
log "Add required users and groups..."

sudo groupadd ${group} 
sudo useradd ${user} 
echo "${password}" | sudo passwd ${user} --stdin 
}

addUser_UBUNTU() {
  typeset -r user=$1
  typeset -r group=$1
  typeset -r password=$1
#
# Add the sdk user and groups
#
log "Add required users and groups..."

sudo groupadd ${group} 
sudo useradd ${user} 
echo "${password}" | sudo passwd ${user} --stdin 
}


update_packages_RED_HAT() {
#
# Update packages 
#
sudo yum update >> $LOG 2>&1
}

update_packages_UBUNTU() {
#
# Update packages 
#
sudo apt-get update >> $LOG 2>&1
}

log "Updating packages..."
"update_packages_$sdk_target"

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

install_admin_packages_RED_HAT() {
sudo yum install -y man wget which file bind-utils >> $LOG 2>&1
}

install_admin_packages_UBUNTU() {

sudo apt-get install man wget which file bind-utils >> $LOG 2>&1
}

"install_admin_packages_$sdk_target"

log "Install required packages for Boundary Event SDK..."

install_boundary_sdk_packages_RED_HAT() {

log "Install EPEL gpg keys and package..."
wget https://fedoraproject.org/static/0608B895.txt >> $LOG 2>&1
sudo mv 0608B895.txt /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 >> $LOG 2>&1
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 >> $LOG 2>&1
sudo rpm -ivh http://mirrors.mit.edu/epel/6/x86_64/epel-release-6-8.noarch.rpm >> $LOG 2>&1

#
# Required packages for Boundary Event SDK
#
sudo yum install -y java-1.7.0-openjdk java-1.7.0-openjdk-devel git curl unzip autoconf gcc libtool make net-snmp.x86_64 net-snmp-utils.x86_64 rpm-build >> $LOG 2>&1

# Add Java bin directory in the path
echo "" >> ${HOME}/.bash_profile
echo '# java configuration' >> ${HOME}/.bash_profile
echo 'JAVA_HOME="/usr/lib/jvm/java-1.7.0"' >> ${HOME}/.bash_profile
echo 'export JAVA_HOME ' >> ${HOME}/.bash_profile
echo "" >> ${HOME}/.bash_profile

}

"install_boundary_sdk_packages_$sdk_target"

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

git clone https://github.com/boundary/boundary-event-sdk.git >> $SDK_LOG 2>&1
pushd boundary-event-sdk >> $SDK_LOG 2>&1
bash setup.sh  >> $SDK_LOG 2>&1
mvn install >> $SDK_LOG 2>&1
popd  >> $SDK_LOG 2>&1

chown -R vagrant:vagrant boundary-event-sdk

# Configure rsyslog

log "Configure syslog ..."
sudo su -c "echo '*.*' @localhost:1514 >> /etc/rsyslog.conf" >> $SDK_LOG 2>&1
sudo service rsyslog restart >> $SDK_LOG 2>&1

