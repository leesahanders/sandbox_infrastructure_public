#!bin/bash

# Inspired by: https://github.com/rstudio/evaluations/blob/main/src/scripts/install_rspm.sh

# Become root (passwordless)
sudo -s

# Define vars
export R_VERSION=4.2.0
export PYTHON_VERSION=3.12.4
export DEFAULT_R_VERSION=4.2.0
export DEFAULT_PYTHON_VERSION=3.12.4
export JUPYTER_PYTHON_VERSION=3.12.4
export VSCODE_EXTENSIONS="quarto.quarto,REditorSupport.r,RDebugger.r-debugger,ms-python.python,ms-toolsai.jupyter,posit.shiny-python"
export RSW_LICENSE=add-yours-here

#TODO: The below vars aren't currently used, but could be useful to pin
export JUPYTERLAB_VERSION=4.1.4
export WORKBENCH_JUPYTERLAB_VERSION=1.0

# Setup system libs
# Not all of these are likely needed
sudo apt-get update
sudo apt-get upgrade

sudo apt install -y libssl-dev libcurl4-openssl-dev openssl nano libxml2 libxml2-dev libuser1-dev libgdal-dev libgeos-dev libproj-dev libudunits2-dev unixodbc unixodbc-dev gdebi-core
sudo apt-get install -y libpng-dev

#sudo apt-get install realmd sssd sssd-tools samba-common  samba-common-bin samba-libs adcli ntp nfs-common

# Set an Workbench version 
# Download a previous version: https://docs.posit.co/previous-versions/
export WORKBENCH_VERSION=2024.04.2 

# TODO: figure out how to fix this, fetch latest stable version number
# cat /tmp/rsp.current.ver
# It's giving a weird version: 2024.04.2%2b764.pro1

if [ -n "$WORKBENCH_VERSION" ]; then
  echo "$WORKBENCH_VERSION" > /tmp/rsp.current.ver
else
  wget -q https://download2.rstudio.org/current.ver -O /tmp/rsp.current.ver
fi

sed -i -e 's/+/%2b/g' /tmp/rsp.current.ver

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

#Optional: TODO: set repo first for binaries, takes forever
#sudo /opt/R/${R_VERSION}/bin/Rscript -e 'install.packages(c("haven","forcats","readr","lubridate","shiny", "DBI", "odbc", "rvest", "plotly","rmarkdown", "rsconnect","pins","png","tidyverse", "Rcpp"), repos = "http://cran.us.r-project.org")'

# Install Python 
curl -O https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb
gdebi python-${PYTHON_VERSION}_1_amd64.deb

/opt/python/"${PYTHON_VERSION}"/bin/pip install --upgrade \ pip setuptools wheel
PATH=/opt/python/"${PYTHON_VERSION}"/bin:$PATH
/opt/python/${PYTHON_VERSION}/bin/pip install ipykernel
/opt/python/${PYTHON_VERSION}/bin/python -m ipykernel install --name py${PYTHON_VERSION} --display-name "Python ${PYTHON_VERSION}"

# install Jupyter and enable extensions
/opt/python/"${JUPYTER_PYTHON_VERSION}"/bin/pip install jupyterlab==4.1.4 notebook pwb_jupyterlab~=1.0

# rename the default Jupyter kernel
sed -i "s/Python 3 (ipykernel)/Python ${JUPYTER_PYTHON_VERSION}/g" /opt/python/${JUPYTER_PYTHON_VERSION}/share/jupyter/kernels/python3/kernel.json

# register additional python versions as kernels
#for EACH_PYTHON_VERSION in $(echo $PYTHON_VERSIONS | awk 'BEGIN {RS=","} {print $1}'); do
#  # only register if not the Jupyter default version (that is registered when jupyter is installed)
#  if [ "${EACH_PYTHON_VERSION}" != "${JUPYTER_PYTHON_VERSION}" ]; then
#    /opt/python/${EACH_PYTHON_VERSION}/bin/python -m ipykernel install --name py${EACH_PYTHON_VERSION} --display-name "Python ${EACH_PYTHON_VERSION}"
#  fi
#done

# Test Python 
#python --version
#/opt/python/"${PYTHON_VERSION}"/bin
# View Python installations 
#ls -ld /opt/python/*

# fetch latest deb package TODO: Fix this
#wget -q "https://download2.rstudio.org/server/jammy/amd64/rstudio-workbench-$(cat /tmp/rsp.current.ver)-amd64.deb" -O /tmp/rstudio-server.deb
wget -q "https://download2.rstudio.org/server/jammy/amd64/rstudio-workbench-${WORKBENCH_VERSION}-amd64.deb" -O /tmp/rstudio-server.deb

# install latest deb package
gdebi -n /tmp/rstudio-server.deb

# jupyter.conf
cat > /etc/rstudio/jupyter.conf <<EOF
jupyter-exe=/opt/python/${JUPYTER_PYTHON_VERSION}/bin/jupyter
labs-enabled=1
default-session-cluster=Local
EOF

# launcher.conf
cat > /etc/rstudio/launcher.conf <<EOF
[server]
address=127.0.0.1
port=5559
server-user=rstudio-server
admin-group=rstudio-server
authorization-enabled=1
enable-debug-logging=1

[cluster]
name=Local
type=Local
EOF

# login.html
cat > /etc/rstudio/login.html <<EOF
<div style="text-align: center;"><b>You can login using user/password</b></div>
EOF

# profiles
cat > /etc/rstudio/profiles <<EOF
[*]
r-version = /opt/R/${DEFAULT_R_VERSION}
EOF

# repos.conf
cat > /etc/rstudio/repos.conf <<EOF
CRAN=http://localhost/pkg/cran/__linux__/jammy/latest
EOF

# pip.conf
cat > /etc/pip.conf <<EOF
[global]
timeout = 60
index-url = https://packagemanager.posit.co/pypi/latest/simple
trusted-host = packagemanager.posit.co
EOF

# rserver.conf
cat > /etc/rstudio/rserver.conf <<EOF
admin-enabled=1
admin-superuser-group=workbench-admins
auth-required-user-group=workbench-users,workbench-admins

www-port=8787
server-health-check-enabled=1
auth-minimum-user-id=100

server-project-sharing=1

r-versions-scan=0

audit-r-sessions=1

databricks-enabled=1

launcher-sessions-enabled=1
launcher-address=127.0.0.1
launcher-port=5559
launcher-sessions-callback-address=http://localhost/dev/
launcher-default-cluster=Local
EOF

# rsession.conf
cat > /etc/rstudio/rsession.conf <<EOF
default-rsconnect-server=http://localhost/pub/
allow-r-cran-repos-edit=0
copilot-enabled=1
session-save-action-default=no
EOF

# r-versions
R_PATH=${R_PATH:-/opt/R}
for EACH_R_VERSION in $(echo $R_VERSIONS | awk 'BEGIN {RS=","} {print $1}'); do
  cat >> /etc/rstudio/r-versions <<EOF
${R_PATH}/$EACH_R_VERSION
EOF
done

# vscode.extensions.conf
for EACH_EXT in $(echo $VSCODE_EXTENSIONS | awk 'BEGIN {RS=","} {print $1}'); do
  cat >> /etc/rstudio/vscode.extensions.conf <<EOF
$EACH_EXT
EOF
done

## pre-install these extensions for each user
ALL_USERS="${ADMIN_USERS},${PUBLISHER_USERS},${VIEWER_USERS}"
for EACH_USER in $(echo $ALL_USERS | awk 'BEGIN {RS=","} {print $1}'); do
  echo "Pre-installing VS Code extensions for user: ${EACH_USER}"
  su - $EACH_USER -c "mkdir -p \"/home/${EACH_USER}/.local/share/rstudio\""
  for EACH_EXT in $(echo $VSCODE_EXTENSIONS | awk 'BEGIN {RS=","} {print $1}'); do
    echo "Pre-installing VS Code extension: ${EACH_EXT} for user: ${EACH_USER}"
      su - $EACH_USER -c "cd \"/home/${EACH_USER}/.local/share/rstudio\" && /usr/lib/rstudio-server/bin/code-server/bin/code-server --install-extension ${EACH_EXT}"
  done
done

sudo rstudio-server configure-vs-code --overwrite yes

# vscode-user-settings.json
cat > /etc/rstudio/vscode-user-settings.json <<EOF
{
      "terminal.integrated.shell.linux": "/bin/bash",
      "extensions.autoUpdate": false,
      "extensions.autoCheckUpdates": false,
      "security.workspace.trust.startupPrompt": "never",
      "security.workspace.trust.enabled": false,
      "security.workspace.trust.banner": "never",
      "security.workspace.trust.emptyWindow": false
}
EOF

# Activate the license 
sudo rstudio-server license-manager activate ${RSW_LICENSE}

# Provision users 
sudo adduser lisa
sudo adduser admin2

# Add users to Workbench group
sudo groupadd workbench-users
sudo usermod -aG workbench-users lisa
sudo usermod -aG workbench-users admin2

# Add admin to Workbench admin group
sudo groupadd workbench-admins
sudo usermod -aG workbench-admins admin2

# Restart
if [ -z "$RSP_NO_RESTART" ]; then
  systemctl restart rstudio-server # restart to make config active
fi

# clean up
rm -rf /tmp/rsp.current.ver /tmp/rstudio-server.deb /var/lib/.local /var/lib/.prof
rm https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-3.12.4_1_amd64.deb

