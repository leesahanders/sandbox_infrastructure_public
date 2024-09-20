# Connect on AWS with Ubuntu Jammy 

These scripts use the AWS CLI and bash to set up a connect instance.  

Order: 

- stand-up-server.sh
- install-and-config-connect.sh

## Troubleshooting 

```
sudo systemctl restart rstudio-connect
sudo systemctl stop rstudio-connect
sudo systemctl start rstudio-connect
sudo systemctl status rstudio-connect
sudo systemctl status rstudio-connect 2>&1 | tee status.txt
sudo rstudio-connect status 2>&1 | tee status.txt
```
 - sudo nano /etc/rstudio-connect/rstudio-connect.gcfg
 - View logs with sudo tail -n 50 /var/log/rstudio-connect.log
 - `sudo tail -n 50 /var/log/rstudio-connect.log | grep error*`
 - `sudo tail -n 50 /var/log/rstudio-connect/rstudio-connect.log | grep error*`
 - `sudo tail -n 50 /var/log/rstudio/rstudio-connect/rstudio-connect.log | grep error*`

sssd Cheat Sheet: 
```
sudo systemctl stop sssd.service
sudo systemctl start sssd.service
sudo systemctl status sssd.service
```
 - sudo nano /etc/sssd/sssd.conf
 - sudo tail -n 50 /var/log/sssd/sssd_LDAP.log
Connect: `sudo /opt/rstudio-connect/bin/license-manager status`

sudo /opt/rstudio-connect/bin/rstudio-connect status

Download a previous version: https://docs.posit.co/previous-versions/

## Checking product version

**Connect**  
- `/opt/rstudio-connect/bin/connect --version`
- `/opt/rstudio/rstudio-connect/bin/connect --version
- [https://colorado.posit.co/rsc/__docs__/admin/server-management/#determine-version-installed](https://colorado.posit.co/rsc/__docs__/admin/server-management/#determine-version-installed) / https://docs.posit.co/connect/admin/server-management/index.html#determine-version-installed


