# Package Manager on Ubuntu Jammy

This container runs docker using the provided images from Posit, but mounting in a config file and instructions for the configurations steps. Runs on [localhost:4242](http://localhost:4242).

## Running the docker file

### Update with valid license

Export the license into your environment. This example uses a license key.

```bash
export RSPM_LICENSE=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
echo $RSPM_LICENSE
```

### Run image from posit

```bash
docker run -it --privileged \
    -p 4242:4242 \
    -e RSPM_LICENSE=$RSPM_LICENSE \
    rstudio/rstudio-package-manager:ubuntu2204

# Run with persistent data and using an external configuration
docker run -it --privileged \
    -p 4242:4242 \
    -v $PWD/data/rsc:/data \
    -v $PWD/pm/rstudio-pm.gcfg:/etc/rstudio/rstudio-pm/rstudio-pm.gcfg \
    -e RSPM_LICENSE=$RSPM_LICENSE \
    rstudio/rstudio-package-manager:ubuntu2204
```

Open [localhost:4242](http://localhost:4242) to access RStudio Package Manager UI.

### Build and run dockerfile image

Right click on the Dockerfile and `Build Image`.

Make sure it built correctly with `docker images`.

Compose and run the image:

```
docker run -it --privileged \
    -p 4242:4242 \
    -e RSPM_LICENSE=$RSPM_LICENSE \
    -v rstudio-pm.gcfg:/etc/rstudio/rstudio-pm/rstudio-pm.gcfg \
    sandboxdockerpm:latest
```

But we also might want to enable systemctl so we can treat the container like a real VM, referencing <https://blog.devops.dev/running-systemctl-inside-docker-container-a-comprehensive-guide-d679852ecd29>. Note that I'm still running into issues with restarting services (error: "Failed to restart opt-rstudio\x2dpm-bin-rspm.mount: Unit opt-rstudio\x2dpm-bin-rspm.mount not found."). Might need to also add: `bash -c "ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5 && bash""`

```
docker run -it --privileged \
    -p 4242:4242 \
    -e RSPM_LICENSE=$RSPM_LICENSE \
    -v rstudio-pm.gcfg:/etc/rstudio/rstudio-pm/rstudio-pm.gcfg \
    -v /run/systemd/system:/run/systemd/system \
    -v /bin/systemctl:/bin/systemctl \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -v /usr/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu \
    -v /lib/systemd:/lib/systemd \
    sandboxdockerpm:latest
```

Open [localhost:4242](http://localhost:4242) to access RStudio Package Manager UI.

## Log into the container and change things

Verify the container is running:
```bash
docker container ls
```

Exec into the container:
```bash
docker exec -it 4a84510f12f6 bash
```

You can use passwordless `sudo -s` to become root and then `su - ubuntu` to become `ubuntu`. In this case it will prompt for the password of rstudio-pm, unfortunately.

Instead we can exec in using the root user with

```bash
docker exec -it -u root 4a84510f12f6 bash
```

Do some things:

```bash
# Sudo
sudo -s
/bin/bash

# Activate the license - optional, and restarting is let's say tricky, but just an example
sudo /opt/rstudio-pm/bin/license-manager activate <license-key>
sudo systemctl restart rstudio-pm # Doesn't work
sudo systemctl restart /opt/rstudio-pm/bin/rspm # Doesn't work

# Without an alias call the CLI directly:
/opt/rstudio-pm/bin/rspm --help

# Verify the installation
sudo systemctl status rstudio-pm 2>&1 | tee status.txt
```

(optional) Exit the ssh session: `exit`

## Setting up repositories

Run the commands from [`config_rspm.sh`](https://github.com/rstudio/evaluations/blob/main/src/scripts/config_rspm.sh) one at a time.

```bash
rspm=/opt/rstudio-pm/bin/rspm

# Ensure Package Manager has started up
curl --retry 5 --retry-connrefused http://localhost:4242/__api__/status
cat /var/log/rstudio/rstudio-pm/rstudio-pm.log

# Create repositories and sync the three mirror sources: CRAN, Bioconductor, and PyPI
/opt/rstudio-pm/bin/rspm create repo --name=cran --description='Access CRAN packages'
/opt/rstudio-pm/bin/rspm subscribe --repo=cran --source=cran
/opt/rstudio-pm/bin/rspm sync --wait

#/opt/rstudio-pm/bin/rspm create repo --type=bioconductor --name=bioconductor --description='Access Bioconductor packages'
#/opt/rstudio-pm/bin/rspm sync --type=bioconductor

/opt/rstudio-pm/bin/rspm create repo --name=pypi --type=python --description='Access PyPI packages'
/opt/rstudio-pm/bin/rspm subscribe --repo=pypi --source=pypi
/opt/rstudio-pm/bin/rspm sync --type=pypi --wait

echo "Listing..."
/opt/rstudio-pm/bin/rspm list

# R ---------------------------------------------------------------------------

# curated cran
echo -e 'dplyr\nggplot2' > /tmp/package_subset.csv
/opt/rstudio-pm/bin/rspm create source --type=curated-cran --name=subset
resp=`${rspm} add --source=subset --file-in='/tmp/package_subset.csv'`
echo "${resp}"

# This will match the stdout pattern:
# "To complete this operation, execute this command with the --commit and --snapshot=2021-04-05 flags."
# and pull out the --snapshot=yyyy-mm-dd part to successfully commit the transaction below.
snapshot=$(echo "${resp}" | grep -oP '\-\-snapshot\=\d{4}-\d{2}-\d{2}')

echo "Got Snapshot: ${snapshot}"
# sleep 1
/opt/rstudio-pm/bin/rspm add --source=subset --file-in='/tmp/package_subset.csv' --commit "${snapshot}"

/opt/rstudio-pm/bin/rspm create repo --name=curated-cran --description='Only approved packages from CRAN (dplyr, ggplot2, and dependencies)'
/opt/rstudio-pm/bin/rspm subscribe --repo=curated-cran --source=subset

echo "Listing..."
/opt/rstudio-pm/bin/rspm list

# git builder -- R
/opt/rstudio-pm/bin/rspm create source --type=git --name=github-internal-r
/opt/rstudio-pm/bin/rspm create git-builder --source=github-internal-r --url=https://github.com/rstudio/package-manager-demo.git --sub-dir=r-package-manager-demo --build-trigger=commits
/opt/rstudio-pm/bin/rspm create repo --name=internal-r --description='Internal R packages'
/opt/rstudio-pm/bin/rspm subscribe --repo=internal-r --source=github-internal-r

# blended
/opt/rstudio-pm/bin/rspm create repo --name=blended-r --description='Blended repo of CRAN and internal R packages'
/opt/rstudio-pm/bin/rspm subscribe --repo=blended-r --source=github-internal-r
/opt/rstudio-pm/bin/rspm subscribe --repo=blended-r --source=cran

# blocked packages -- R
/opt/rstudio-pm/bin/rspm create source --type=curated-cran --name=blocked-packages-r
/opt/rstudio-pm/bin/rspm create blocklist-rule --source=blocked-packages-r --vulns
/opt/rstudio-pm/bin/rspm create blocklist-rule --source=blocked-packages-r --package-name=ggplot2 --description="Installation of 'ggplot2' is blocked"
/opt/rstudio-pm/bin/rspm add --source=blocked-packages-r --file-in='/tmp/package_subset.csv' --commit "${snapshot}"
/opt/rstudio-pm/bin/rspm create repo --name=blocked-r --description="Curated CRAN with vulnerability blocking enabled. Downloads of ggplot2 are also disallowed."
/opt/rstudio-pm/bin/rspm subscribe --repo=blocked-r --source=blocked-packages-r

echo "Listing..."
/opt/rstudio-pm/bin/rspm list

# Python ----------------------------------------------------------------------

# curated pypi
echo -e 'plotnine\npolars\n' > /tmp/curated-requirements.txt
## resolve dependencies
/opt/python/"${DEFAULT_PYTHON_VERSION}"/bin/python -m pip install -r /tmp/curated-requirements.txt --dry-run -I --quiet --report - | jq -r '.install[].metadata.name' > /tmp/requirements-resolved.txt

/opt/rstudio-pm/bin/rspm create source --name=pypi-subset --type=curated-pypi
/opt/rstudio-pm/bin/rspm update --source=pypi-subset --file-in=/tmp/requirements-resolved.txt "${snapshot}" --commit
/opt/rstudio-pm/bin/rspm create repo --name=curated-pypi --type=python --description='Only approved packages from PyPI (polars, plotnine, and dependencies)'
/opt/rstudio-pm/bin/rspm subscribe --repo=curated-pypi --source=pypi-subset

# git builder -- Python
/opt/rstudio-pm/bin/rspm create source --type=git-python --name=github-internal-python
/opt/rstudio-pm/bin/rspm create git-builder --source=github-internal-python --url=https://github.com/rstudio/package-manager-demo.git --sub-dir=python-package-manager-demo --build-trigger=commits --name=internal-pkg
/opt/rstudio-pm/bin/rspm create repo --name=internal-python --type=python --description="Internal Python packages"
/opt/rstudio-pm/bin/rspm subscribe --repo=internal-python --source=github-internal-python

# blended
/opt/rstudio-pm/bin/rspm create repo --name=blended-python --type=python --description="Blended repo of PyPI and internal Python packages"
/opt/rstudio-pm/bin/rspm subscribe --repo=blended-python --source=github-internal-python
/opt/rstudio-pm/bin/rspm subscribe --repo=blended-python --source=pypi

# blocked packages -- python
/opt/rstudio-pm/bin/rspm create source --name=blocked-packages-python --type=curated-pypi
/opt/rstudio-pm/bin/rspm create blocklist-rule --source=blocked-packages-python --vulns
/opt/rstudio-pm/bin/rspm create blocklist-rule --source=blocked-packages-python --package-name=plotnine --description="Installation of 'plotnine' is blocked."
/opt/rstudio-pm/bin/rspm update --source=blocked-packages-python --file-in=/tmp/requirements-resolved.txt "${snapshot}" --commit
/opt/rstudio-pm/bin/rspm create repo --name=blocked-python --type=python --description="Curated PyPI with vulnerability blocking enabled. Downloads of plotnine are also disallowed."
/opt/rstudio-pm/bin/rspm subscribe --repo=blocked-python --source=blocked-packages-python

echo "Listing..."
/opt/rstudio-pm/bin/rspm list

# Status ----------------------------------------------------------------------

#echo "Is RSPM Up?"
#curl -iIL http://localhost/pkg/
#curl -iIL http://localhost/pkg/cran/__linux__/jammy/latest/src/contrib/PACKAGES
#netstat -lntp
#systemctl status

echo "Done!"

```

## Working with the container

Verify the container is running:
```
docker container ls
docker ps
```

Exec into the container:
```
docker exec -it 4a84510f12f6 bash
docker exec -it -u root 4a84510f12f6 bash
```

View container logs:
```
docker logs instance_name
docker logs 4a84510f12f6
```

Shutdown the container:
```
docker stop 4a84510f12f6
```

## References

- <https://github.com/lagerratrobe/docker_recipes/tree/main/PkgManager_Docker>
- <https://github.com/rstudio/rstudio-docker-products/tree/dev/package-manager>
- <https://github.com/rstudio/evaluations/blob/main/src/scripts/config_rspm.sh>

