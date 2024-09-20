#!/bin/bash

# Influenced by: - <https://github.com/rstudio/evaluations/blob/main/src/scripts/config_rspm.sh>
# https://github.com/sol-eng/proxyplayground/blob/main/config/configure-ppm.qmd

set -xe

rspm=/opt/rstudio-pm/bin/rspm

echo 'Start'

systemctl start rstudio-pm

# Ensure Package Manager has started up
#curl --retry 5 --retry-connrefused https://localhost/pkg/__api__/status #when hosted on https
curl --retry 5 --retry-connrefused http://localhost:4242/__api__/status #when hosted on http
cat /var/log/rstudio/rstudio-pm/rstudio-pm.log

# Create repositories and sync the three mirror sources: CRAN, Bioconductor, and PyPI
${rspm} create repo --name=cran --description='Access CRAN packages'
${rspm} subscribe --repo=cran --source=cran
${rspm} sync --wait

${rspm} create repo --type=bioconductor --name=bioconductor --description='Access Bioconductor packages'
${rspm} sync --type=bioconductor

${rspm} create repo --name=pypi --type=python --description='Access PyPI packages'
${rspm} subscribe --repo=pypi --source=pypi
${rspm} sync --type=pypi --wait

echo "Listing..."
${rspm} list

# R ---------------------------------------------------------------------------

# curated cran
echo -e 'dplyr\nggplot2' > /tmp/package_subset.csv
${rspm} create source --type=curated-cran --name=subset
resp=`${rspm} add --source=subset --file-in='/tmp/package_subset.csv'`
echo "${resp}"

# This will match the stdout pattern:
# "To complete this operation, execute this command with the --commit and --snapshot=2021-04-05 flags."
# and pull out the --snapshot=yyyy-mm-dd part to successfully commit the transaction below.
snapshot=$(echo "${resp}" | grep -oP '\-\-snapshot\=\d{4}-\d{2}-\d{2}')

echo "Got Snapshot: ${snapshot}"
sleep 1
${rspm} add --source=subset --file-in='/tmp/package_subset.csv' --commit "${snapshot}"

${rspm} create repo --name=curated-cran --description='Only approved packages from CRAN (dplyr, ggplot2, and dependencies)'
${rspm} subscribe --repo=curated-cran --source=subset

echo "Listing..."
${rspm} list

# git builder -- R
${rspm} create source --type=git --name=github-internal-r
${rspm} create git-builder --source=github-internal-r --url=https://github.com/rstudio/package-manager-demo.git --sub-dir=r-package-manager-demo --build-trigger=commits
${rspm} create repo --name=internal-r --description='Internal R packages'
${rspm} subscribe --repo=internal-r --source=github-internal-r

# blended
${rspm} create repo --name=blended-r --description='Blended repo of CRAN and internal R packages'
${rspm} subscribe --repo=blended-r --source=github-internal-r
${rspm} subscribe --repo=blended-r --source=cran

# blocked packages -- R
${rspm} create source --type=curated-cran --name=blocked-packages-r
${rspm} create blocklist-rule --source=blocked-packages-r --vulns
${rspm} create blocklist-rule --source=blocked-packages-r --package-name=ggplot2 --description="Installation of 'ggplot2' is blocked"
${rspm} add --source=blocked-packages-r --file-in='/tmp/package_subset.csv' --commit "${snapshot}"
${rspm} create repo --name=blocked-r --description="Curated CRAN with vulnerability blocking enabled. Downloads of ggplot2 are also disallowed."
${rspm} subscribe --repo=blocked-r --source=blocked-packages-r

echo "Listing..."
${rspm} list

# Python ----------------------------------------------------------------------

# curated pypi
echo -e 'plotnine\npolars\n' > /tmp/curated-requirements.txt
## resolve dependencies
/opt/python/"${DEFAULT_PYTHON_VERSION}"/bin/python -m pip install -r /tmp/curated-requirements.txt --dry-run -I --quiet --report - | jq -r '.install[].metadata.name' > /tmp/requirements-resolved.txt

${rspm} create source --name=pypi-subset --type=curated-pypi
${rspm} update --source=pypi-subset --file-in=/tmp/requirements-resolved.txt "${snapshot}" --commit
${rspm} create repo --name=curated-pypi --type=python --description='Only approved packages from PyPI (polars, plotnine, and dependencies)'
${rspm} subscribe --repo=curated-pypi --source=pypi-subset

# git builder -- Python
${rspm} create source --type=git-python --name=github-internal-python
${rspm} create git-builder --source=github-internal-python --url=https://github.com/rstudio/package-manager-demo.git --sub-dir=python-package-manager-demo --build-trigger=commits --name=internal-pkg
${rspm} create repo --name=internal-python --type=python --description="Internal Python packages"
${rspm} subscribe --repo=internal-python --source=github-internal-python

# blended
${rspm} create repo --name=blended-python --type=python --description="Blended repo of PyPI and internal Python packages"
${rspm} subscribe --repo=blended-python --source=github-internal-python
${rspm} subscribe --repo=blended-python --source=pypi

# blocked packages -- python
${rspm} create source --name=blocked-packages-python --type=curated-pypi
${rspm} create blocklist-rule --source=blocked-packages-python --vulns
${rspm} create blocklist-rule --source=blocked-packages-python --package-name=plotnine --description="Installation of 'plotnine' is blocked."
${rspm} update --source=blocked-packages-python --file-in=/tmp/requirements-resolved.txt "${snapshot}" --commit
${rspm} create repo --name=blocked-python --type=python --description="Curated PyPI with vulnerability blocking enabled. Downloads of plotnine are also disallowed."
${rspm} subscribe --repo=blocked-python --source=blocked-packages-python

echo "Listing..."
${rspm} list

# Status ----------------------------------------------------------------------

echo "Is RSPM Up?"
curl -iIL http://localhost/pkg/
curl -iIL http://localhost/pkg/cran/__linux__/jammy/latest/src/contrib/PACKAGES
netstat -lntp
systemctl status

echo "Done!"


