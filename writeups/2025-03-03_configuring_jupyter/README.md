## Configuring Jupyter 

Ticket: 114912

Try following these steps for installing jupyter: <https://docs.posit.co/ide/server-pro/integration/jupyter-standalone.html>

```
## Set variables 
export JUPYTER_PYTHON_VERSION=3.12.4
export JUPYTERLAB_VERSION=4.2.5
export WORKBENCH_JUPYTERLAB_VERSION=1.0

## Install Jupyter 
sudo /opt/python/"${JUPYTER_PYTHON_VERSION}"/bin/pip install jupyterlab=="${JUPYTERLAB_VERSION}" notebook pwb_jupyterlab~="${WORKBENCH_JUPYTERLAB_VERSION}"

## Set the jupyter.conf to the jupyter-exe location
# jupyter.conf
cat > /etc/rstudio/jupyter.conf <<EOF
jupyter-exe=/opt/python/${JUPYTER_PYTHON_VERSION}/bin/jupyter
labs-enabled=1
notebooks-enabled=1
default-session-cluster=Local

EOF
```
