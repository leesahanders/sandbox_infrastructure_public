#!bin/bash

# Inspired by: https://github.com/rstudio/evaluations/blob/main/src/scripts/install_rsp.sh

# Become root (passwordless)
sudo -s

# Define vars
export R_VERSION=4.3.0
export PYTHON_VERSION=3.12.4
export DEFAULT_R_VERSION=4.3.0
export DEFAULT_PYTHON_VERSION=3.12.4
export JUPYTER_PYTHON_VERSION=3.12.4
export VSCODE_EXTENSIONS="quarto.quarto,REditorSupport.r,RDebugger.r-debugger,ms-python.python,ms-toolsai.jupyter,posit.shiny-python"
export RSW_LICENSE=add-yours-here
export JUPYTERLAB_VERSION=4.1.4
export WORKBENCH_JUPYTERLAB_VERSION=1.0

# Set an Workbench version 
# Download a previous version: https://docs.posit.co/previous-versions/
export WORKBENCH_VERSION=2024.04.2 

# TODO: figure out how to fix this, fetch latest stable version number
#if [ -n "$WORKBENCH_VERSION" ]; then
#  echo "$WORKBENCH_VERSION" > /tmp/rsp.current.ver
#else
#  wget -q https://download2.rstudio.org/current.ver -O /tmp/rsp.current.ver
#fi

#sed -i -e 's/+/%2b/g' /tmp/rsp.current.ver

# Update OS
# Updating requires an active subscription with rhel
#RUN dnf update
#RUN yum install -y epel-release
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y dnf-plugins-core
yum install -y yum-utils
yum install -y nano

# Enable the Extra Packages for Enterprise Linux (EPEL) repository:
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# enable the CodeReady Linux Builder repository from Red Hat Update Infrastructure (RHUI) 
sudo dnf install dnf-plugins-core
sudo dnf config-manager --set-enabled codeready-builder-for-rhel-9-*-rpms

# Disable selinux 
setenforce 0 && sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

# Install Docker
#RUN yum install -y yum-utils
#RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#RUN dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
#RUN systemctl start docker
#RUN usermod -aG docker $USER

# Install git
dnf install -y git

# Create user 
useradd -m lisa
echo -e 'password\npassword' | passwd lisa

# Provision users 
sudo useradd lisa
passwd lisa 

# Add users to Workbench group
sudo groupadd workbench-users
sudo usermod -aG workbench-users lisa
sudo usermod -aG workbench-users admin2
sudo usermod -aG workbench-users lisa

# Add admin to Workbench admin group
sudo groupadd workbench-admins
sudo usermod -aG workbench-admins admin2
sudo usermod -aG workbench-admins lisa

# Install R: https://github.com/rstudio/r-builds 

# CentOS / RHEL 7
#curl -O https://cdn.posit.co/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm

# RHEL 8 / Rocky Linux 8 / AlmaLinux 8
#curl -O https://cdn.posit.co/r/centos-8/pkgs/R-${R_VERSION}-1-1.x86_64.rpm

# RHEL 9 / Rocky Linux 9 / AlmaLinux 9
#RUN cd /opt && curl -O https://cdn.posit.co/r/rhel-9/pkgs/R-4.3.0-1-1.x86_64.rpm 
#RUN yum install -y /opt/R-4.3.0-1-1.x86_64.rpm
curl -O https://cdn.posit.co/r/rhel-9/pkgs/R-${R_VERSION}-1-1.x86_64.rpm 
dnf install -y R-core R-core-devel

# Install R
yum install -y R-${R_VERSION}-1-1.x86_64.rpm

# Create a symlink to R
sudo ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R
sudo ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Install Python
curl -O https://cdn.rstudio.com/python/rhel-9/pkgs/python-${PYTHON_VERSION}-1-1.x86_64.rpm
sudo yum install python-${PYTHON_VERSION}-1-1.x86_64.rpm

# Upgrade required Python tools
sudo /opt/python/"${PYTHON_VERSION}"/bin/pip install \
    --upgrade pip setuptools wheel

# Add Python to the system PATH
PATH=/opt/python/"${PYTHON_VERSION}"/bin:$PATH

## Install Jupyter 
# sudo -E /opt/python/{{python_version}}/bin/pip install jupyter notebook==6.5.6 jupyterlab==3.6.5 rsp_jupyter rsconnect_jupyter workbench_jupyterlab==1.1.1 
# Alternatively, the google workstations image is pinning versions too (JUPYTERLAB_VERSION=3.6.7): https://github.com/rstudio/rstudio-docker-products/blob/2e6f904ae8166ab01eaa8fe89e[…]6/workbench-for-google-cloud-workstations/Dockerfile.ubuntu2004
sudo /opt/python/"${JUPYTER_PYTHON_VERSION}"/bin/pip install jupyterlab=="${JUPYTERLAB_VERSION}" notebook pwb_jupyterlab~="${WORKBENCH_JUPYTERLAB_VERSION}"

# Make Python available as a Jupyter Kernel
sudo /opt/python/${PYTHON_VERSION}/bin/pip install ipykernel
sudo /opt/python/${PYTHON_VERSION}/bin/python -m ipykernel install --name py${PYTHON_VERSION} --display-name "Python ${PYTHON_VERSION}"

# Install Workbench
curl -O https://download2.rstudio.org/server/rhel9/x86_64/rstudio-workbench-rhel-${WORKBENCH_VERSION}-x86_64.rpm
sudo yum install rstudio-workbench-rhel-${WORKBENCH_VERSION}-x86_64.rpm

# Activate the license 
sudo rstudio-server license-manager activate ${RSW_LICENSE}

# jupyter.conf
cat > /etc/rstudio/jupyter.conf <<EOF
jupyter-exe=/opt/python/${JUPYTER_PYTHON_VERSION}/bin/jupyter
labs-enabled=1
notebooks-enabled=1
default-session-cluster=Local
# jupyter-exe=/usr/local/bin/jupyter
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

## pre-install these extensions for each user - TODO 
#ALL_USERS="${ADMIN_USERS},${PUBLISHER_USERS},${VIEWER_USERS}"
#for EACH_USER in $(echo $ALL_USERS | awk 'BEGIN {RS=","} {print $1}'); do
#  echo "Pre-installing VS Code extensions for user: ${EACH_USER}"
#  su - $EACH_USER -c "mkdir -p \"/home/${EACH_USER}/.local/share/rstudio\""
#  for EACH_EXT in $(echo $VSCODE_EXTENSIONS | awk 'BEGIN {RS=","} {print $1}'); do
#    echo "Pre-installing VS Code extension: ${EACH_EXT} for user: ${EACH_USER}"
#      su - $EACH_USER -c "cd \"/home/${EACH_USER}/.local/share/rstudio\" && /usr/lib/rstudio-server/bin/code-server/bin/code-server --install-extension ${EACH_EXT}"
#  done
#done

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

# Restart
if [ -z "$RSP_NO_RESTART" ]; then
  systemctl restart rstudio-server # restart to make config active
fi

# clean up
rm -rf /tmp/rsp.current.ver /tmp/rstudio-server.deb /var/lib/.local /var/lib/.prof


