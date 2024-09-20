#!bin/bash

# Inspired by: https://github.com/rstudio/evaluations/blob/main/src/scripts/install_rspm.sh

# Become root (passwordless)
sudo -s

# Setup system libs
# Not all of these are likely needed
sudo apt-get update
sudo apt-get upgrade

sudo apt install -y libssl-dev libcurl4-openssl-dev openssl nano libxml2 libxml2-dev libuser1-dev
apt-get install -y libgdal-dev libgeos-dev libproj-dev libudunits2-dev unixodbc unixodbc-dev gdebi-core

sudo apt-get install -y libpng-dev

#sudo apt-get install realmd sssd sssd-tools samba-common  samba-common-bin samba-libs adcli ntp nfs-common

# Set an Connect version, vars
# Download a previous version: https://docs.posit.co/previous-versions/
CONNECT_VERSION=2024.08.0
export R_VERSION=4.2.0
export PYTHON_VERSION=3.12.4
export DEFAULT_R_VERSION=4.2.0
export DEFAULT_PYTHON_VERSION=3.12.4
export RSC_LICENSE=add-yours-here

# Warning - the link below needs to be updated to pull the correct OS (in case a different AMI is chosen)

# Install R 
# curl -O https://cdn.rstudio.com/r/ubuntu-2004/pkgs/r-${R_VERSION}_1_amd64.deb 
curl -O https://cdn.rstudio.com/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb 
gdebi r-${R_VERSION}_1_amd64.deb

#/opt/R/${R_VERSION}/bin/R --version
ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R 
ln -s /opt/R/${R_VERSION}/bin/Rscript 

# Test R
#R --version
#/opt/R/${R_VERSION}/bin/R

# View R installations 
#ls -ld /opt/R/*
#/usr/local/bin/R --version

#Optional: 
# sudo /opt/R/${R_VERSION}/bin/Rscript -e 'install.packages(c("haven","forcats","readr","lubridate","shiny", "DBI", "odbc", "rvest", "plotly","rmarkdown", "rsconnect","pins","png","tidyverse", "Rcpp"), repos = "http://cran.us.r-project.org")'

# Install Python 
curl -O https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb
gdebi python-${PYTHON_VERSION}_1_amd64.deb

/opt/python/"${PYTHON_VERSION}"/bin/pip install --upgrade \ pip setuptools wheel
PATH=/opt/python/"${PYTHON_VERSION}"/bin:$PATH
/opt/python/${PYTHON_VERSION}/bin/pip install ipykernel
/opt/python/${PYTHON_VERSION}/bin/python -m ipykernel install --name py${PYTHON_VERSION} --display-name "Python ${PYTHON_VERSION}"

# Test Python 
#python --version
#/opt/python/"${PYTHON_VERSION}"/bin

# View Python installations 
#ls -ld /opt/python/*

# get the rsc installer script TODO switch to this method
#wget -q https://cdn.rstudio.com/connect/installer/installer-ci.sh -O /tmp/rsc-installer.sh
#chmod +x /tmp/rsc-installer.sh

#UNATTENDED=true /tmp/rsc-installer.sh ${RSC_VERSION}

# Install connect
curl -O https://cdn.posit.co/connect/2024.08/rstudio-connect_${CONNECT_VERSION}~ubuntu22_amd64.deb
#gdebi -n rstudio-connect_${CONNECT_VERSION}~ubuntu22_amd64.deb
sudo apt install ./rstudio-connect_2024.08.0~ubuntu22_amd64.deb # Match the admin guide more closely

# start with a blank configuration
cat /dev/null > /etc/rstudio-connect/rstudio-connect.gcfg

# [Server] section
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[Server]
; provided during automated install
Address = http://localhost/pub/

SenderEmail = rstudio-connect@example.com
EmailProvider = SMTP

PublicWarning = <b>WARNING: This server is for demonstration purposes only.</b>
LoggedInWarning = <b>WARNING: This server is for demonstration purposes only.</b>

DefaultContentListView = "expanded"

JumpStartEnabled = false
EOF

# [SMTP] section
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[SMTP]
Host = localhost
Port = 25
StartTLS = never
EOF

# [HTTP] section
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[HTTP]
Listen = :3939
NoWarning = true
EOF

# [CORS] section
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[CORS]
EnforceWebsocketOrigin = false
EOF

# [Authentication] section
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[Authentication]
Provider = pam
Notice = "WARNING: This server is for demonstration purposes only. Login with user/password."
Lifetime = 168h
Inactivity = 168h
EOF

# [Authorization] section
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[Authorization]
DefaultUserRole = publisher
PublishersCanManageVanities = true
EOF

# [R] section
R_PATH=${R_PATH:-/opt/R}
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[R]
Enabled = true
ExecutableVersionScanning = false
ConfigActive = evaluations
EOF

for EACH_R_VERSION in $(echo $R_VERSIONS | awk 'BEGIN {RS=","} {print $1}'); do
  cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
Executable = ${R_PATH}/$EACH_R_VERSION/bin/R
EOF
done

# [Python] section
PYTHON_PATH=${PYTHON_PATH:-/opt/python}
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[Python]
Enabled = true
EOF

for EACH_PYTHON_VERSION in $(echo $PYTHON_VERSIONS | awk 'BEGIN {RS=","} {print $1}'); do
  cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
Executable = ${PYTHON_PATH}/$EACH_PYTHON_VERSION/bin/python3
EOF
done

# [Quarto] section
QUARTO_PATH=${QUARTO_PATH:-/opt/quarto}
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[Quarto]
; provided during automated install
Enabled = true
EOF

for EACH_QUARTO_VERSION in $(echo $QUARTO_VERSIONS | awk 'BEGIN {RS=","} {print $1}'); do
  cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
Executable = ${QUARTO_PATH}/$EACH_QUARTO_VERSION/bin/quarto
EOF
done


# Repo sections
R_REPO="http://localhost/pkg/cran/__linux__/jammy/latest"
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[RPackageRepository "CRAN"]
URL = ${R_REPO}
[RPackageRepository "RSPM"]
URL = ${R_REPO}
EOF

# [Logging] section
cat >> /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
[Logging]
AuditLogFormat = TEXT
AuditLog = /var/log/rstudio/rstudio-connect/rstudio-connect.audit.log
EOF

# Activate the license 
sudo /opt/rstudio-connect/bin/license-manager activate ${RSC_LICENSE}

# Restart
if [ -z "$RSC_NO_RESTART" ]; then
  # restart to reload configuration
  systemctl restart rstudio-connect
fi

# clean up
rm /tmp/rsc-installer.sh
rm https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb
rm rstudio-connect_${CONNECT_VERSION}~ubuntu22_amd64.deb
rm r-${R_VERSION}_1_amd64.deb
