# Workbench on AWS with RHEL9

Maintainer: Lisa Anders (lisa.anders@posit.co)

These scripts use the AWS CLI and bash to set up a workbench instance.  

Order: 

- stand-up-server.sh
- install-and-config-workbench.sh

## Troubleshooting 

```
sudo rstudio-server restart
sudo rstudio-server start
sudo rstudio-server stop
sudo rstudio-server start
sudo rstudio-launcher restart
sudo rstudio-launcher stop
sudo rstudio-launcher start

sudo systemctl status rstudio-server
sudo systemctl status rstudio-launcher
rstudio-server status 2>&1 | tee status.txt
rstudio-launcher status 2>&1 | tee status.txt

sudo rstudio-server verify-installation --verify-user=ubuntu --verify-test=jupyter-sessions
sudo rstudio-server verify-installation
sudo rstudio-server verify-installation --verify-user ubuntu
sudo rstudio-server verify-installation --verify-user=ubuntu --verify-test=jupyter-sessions
sudo rstudio-server verify-installation --verify-user=ubuntu --verify-test=r-sessions
sudo rstudio-server verify-installation --verify-user=ubuntu --verify-test=vscode-sessions
```

Verify installation docs: [https://docs.posit.co/ide/serverpro/job_launcher/troubleshooting.html#troubleshooting](https://docs.posit.co/ide/serverpro/job_launcher/troubleshooting.html#troubleshooting) and for k8s [https://docs.posit.co/troubleshooting/launcher-kubernetes/verify-installation/](https://docs.posit.co/troubleshooting/launcher-kubernetes/verify-installation/)

Add account to rstudio-server group: `sudo usermod -aG rstudio-server ubuntu`
For admin access add user to `rstudio-admin` group

For a cluster: 
- Restart the Workbench service (run on both nodes): `sudo systemctl restart rstudio-server`
- Restart the Launcher service (run on both nodes): `sudo systemctl restart rstudio-launcher`
- Reset the cluster (run on any one node): `sudo rstudio-server reset-cluster`
- Debugging: `sudo rstudio-server list-nodes`
- See the sessions running: `curl http://localhost:8787/load-balancer/status`

Check if there are any active sessions running: ` sudo rstudio-server active-sessions`
If there are active sessions, then [suspend all](https://docs.posit.co/ide/server-pro/server_management/core_administrative_tasks.html#managing-active-sessions) active user sessions: `sudo rstudio-server suspend-all`

Configs: 
sudo nano /etc/rstudio/rserver.conf
sudo nano /etc/rstudio/jupyter.conf
sudo nano /etc/rstudio/vscode.conf
sudo nano /etc/rstudio/launcher.conf
sudo nano /etc/pip.conf
sudo nano /etc/rstudio/rsession.conf
sudo nano /etc/rstudio/load-balancer
sudo nano /etc/rstudio/secure-cookie-key
sudo nano /etc/rstudio/database.conf 
https://gist.github.com/colearendt/4062c423d182e8f6707b938fd23bf556

View logs with `sudo tail -n 50 /var/log/rstudio/rstudio-server/rserver.log`
View logs with `sudo tail -n 50 /var/log/rstudio/launcher/rstudio-launcher.log`
View logs only errors with `sudo tail -n 50 /var/log/rstudio/launcher/rstudio-launcher.log | grep error*`
Or, alternatively, you can also look for the rstudio process `ps -ef | grep rstudio`. For errors, it's also useful to `cat /var/log/syslog` in addition to the rstudio specific log files.
Workbench you can do `sudo rstudio-server license-manager status` I believe

Please adjust the permissions on the jupyter configuration (or others) using the command below; this will allow the `rstudio-server` to read the file:  

```
chmod 644 /etc/rstudio/jupyter.conf
```

Download a previous version: https://docs.posit.co/previous-versions/

## Checking product version

- `rstudio-server version` -> [https://docs.posit.co/ide/server-pro/reference/rstudio_server_cli.html#diagnostics](https://docs.posit.co/ide/server-pro/reference/rstudio_server_cli.html#diagnostics)
- `/opt/rstudio-server version`
- What version of code server: `/opt/code-server/bin/code-server --version`


## Make sure groups exist 

Make ure groups exist on server (workbench-users and workbench-admins): 

```
cat /etc/group | grep workbench*
```

## Verify jupyter 

Start jupyter sessions from command line: 
```
/opt/python/3.7.13/bin/jupyter notebook --no-browser --allow-root --ip=0.0.0.0 --debug
/opt/python/3.7.13/bin/jupyter lab --no-browser --allow-root --ip=0.0.0.0 --debug
```

```
/opt/python/${JUPYTER_PYTHON_VERSION}/bin/jupyter notebook
```

## Check on se linux and other server hardening 

Another thing to check is whether [SELinux is enabled on the system](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/changing-selinux-states-and-modes_using-selinux). Check the mode with `getenforce`

This can result in user specific errors, in that case compare the SELinux context for a user that has successfully package installations to the one that is having errors.

Often the following command will work to fix SELinux context issues: `restorecon -Rv /home/users/username`

Great article from our support team discussing [how to use selinux](https://support.posit.co/hc/en-us/articles/4579112985751-SELinux-a-quick-primer-and-troubleshooter)

Disable SELINUX (RHEL only): `setenforce 0 && sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config`

Check for [FIPS being enabled](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_hardening/assembly_installing-the-system-in-fips-mode_security-hardening): `fips-mode-setup --check`

[This article from redhat on FIPS mode](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_hardening/assembly_installing-the-system-in-fips-mode_security-hardening) is also very useful.


