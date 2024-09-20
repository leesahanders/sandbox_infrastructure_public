#!bin/bash

# Inspired by: https://github.com/rstudio/evaluations/blob/main/src/scripts/install_rspm.sh

# Become root (passwordless)
sudo -s

# Setup system libs
#apt-get update
#apt-get install -y libgdal-dev libgeos-dev libproj-dev libudunits2-dev unixodbc unixodbc-dev gdebi-core

# Not all of these are likely needed
sudo apt-get update
sudo apt-get upgrade

sudo apt install -y libssl-dev libcurl4-openssl-dev openssl nano libxml2 libxml2-dev libuser1-dev

sudo apt-get install gdebi-core
sudo apt-get install -y libpng-dev

#sudo apt-get install realmd sssd sssd-tools samba-common  samba-common-bin samba-libs adcli ntp nfs-common

# Set an rspm version 
# Download a previous version: https://docs.posit.co/previous-versions/
RSPM_VERSION=2024.08.0-6
export R_VERSION=4.2.0
export PYTHON_VERSION=3.12.4
export DEFAULT_R_VERSION=4.2.0
export DEFAULT_PYTHON_VERSION=3.12.4
export RSPM_LICENSE_KEY=add-yours-here

# Get the rspm version
echo $RSPM_VERSION > /tmp/rspm.current.ver

#Might be able to switch to doing this
#From johnyoder: [https://github.com/rstudio/package-manager/blob/5566bb5a74148b083ea30eb0b301a0964c52c2df/scripts/install.sh#L14](https://github.com/rstudio/package-manager/blob/5566bb5a74148b083ea30eb0b301a0964c52c2df/scripts/install.sh#L14)
#bash -c "$(curl -L https://rstd.io/rspm-quickinstall)"

#sed -i -e 's/+/%2b/g' /tmp/rspm.current.ver

# TODO: fetch latest stable version number, or use one that is defined - this is workbench
#if [ -n "$RSP_VERSION" ]; then
#  echo "$RSP_VERSION" > /tmp/rsp.current.ver
#else
#  wget -q https://download2.rstudio.org/current.ver -O /tmp/rsp.current.ver
#fi

# Warning - the link below needs to be updated to pull the correct OS (in case a different AMI is chosen)

# Install R 
# curl -O https://cdn.rstudio.com/r/ubuntu-2004/pkgs/r-${R_VERSION}_1_amd64.deb 
curl -O https://cdn.rstudio.com/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb 
gdebi r-${R_VERSION}_1_amd64.deb

#/opt/R/${R_VERSION}/bin/R --version
ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R 
ln -s /opt/R/${R_VERSION}/bin/Rscript 

# Test R
R --version
#/opt/R/${R_VERSION}/bin/R
# View R installations 
ls -ld /opt/R/*

# Test Python 
python --version
#/opt/python/"${PYTHON_VERSION}"/bin
# View Python installations 
ls -ld /opt/python/*

#Optional: 
#sudo /opt/R/${R_VERSION}/bin/Rscript -e 'install.packages(c("haven","forcats","readr","lubridate","shiny", "DBI", "odbc", "rvest", "plotly","rmarkdown", "rsconnect","pins","png","tidyverse", "Rcpp"), repos = "http://cran.us.r-project.org")'

# Install Python 
curl -O https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb

gdebi python-${PYTHON_VERSION}_1_amd64.deb
/opt/python/"${PYTHON_VERSION}"/bin/pip install --upgrade \ pip setuptools wheel
PATH=/opt/python/"${PYTHON_VERSION}"/bin:$PATH
/opt/python/${PYTHON_VERSION}/bin/pip install ipykernel
/opt/python/${PYTHON_VERSION}/bin/python -m ipykernel install --name py${PYTHON_VERSION} --display-name "Python ${PYTHON_VERSION}"

# If we want to host developed packages we need to also do this: 
/opt/python/${PYTHON_VERSION}/bin/pip install build virtualenv

# Install package manager
# fetch latest deb package
wget -q https://cdn.rstudio.com/package-manager/deb/amd64/rstudio-pm_$(cat /tmp/rspm.current.ver)_amd64.deb -O /tmp/rstudio-pm.deb

# install latest deb package
gdebi -n /tmp/rstudio-pm.deb

# start with a blank configuration
cat /dev/null > /etc/rstudio-pm/rstudio-pm.gcfg

# [Server] section
cat >> /etc/rstudio-pm/rstudio-pm.gcfg <<EOF
[Server]
Address = http://localhost/pkg/
RVersion = /opt/R/${DEFAULT_R_VERSION}
PythonVersion = /opt/python/${DEFAULT_PYTHON_VERSION}/bin/python
EOF

# [Http] section
cat >> /etc/rstudio-pm/rstudio-pm.gcfg <<EOF
[Http]
NoWarning = true
Listen = :4242
EOF

# Activate the license
/opt/rstudio-pm/bin/license-manager activate $RSPM_LICENSE_KEY

# add admin
useradd -m lisa
usermod -aG rstudio-pm lisa

if [ -z "$RSPM_NO_RESTART" ]; then
  # restart to reload configuration
  systemctl restart rstudio-pm
fi

# Check logs
sudo systemctl status rstudio-pm 2>&1 | tee status.txt
sudo tail -n 50 /var/log/rstudio/rstudio-pm/rstudio-pm.log

# visit it at: http://ec2-3-22-168-28.us-east-2.compute.amazonaws.com:4242

# Ensure Package Manager has started up
#curl --retry 5 --retry-connrefused https://localhost/pkg/__api__/status
curl --retry 5 --retry-connrefused http://localhost:4242/__api__/status

# clean up
rm /tmp/rspm.current.ver /tmp/rstudio-pm.deb

