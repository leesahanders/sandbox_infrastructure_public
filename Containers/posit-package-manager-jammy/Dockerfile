#FROM rstudio/rstudio-package-manager:bionic-2023.04.0
FROM rstudio/rstudio-package-manager:ubuntu2204
LABEL maintainer="Lisa Anders <lisa.anders@posit.co"

# Copy our configuration over the default install configuration
# COPY rstudio-pm.gcfg /etc/rstudio-pm/rstudio-pm.gcfg

# Copy our license key into the container (note that with a key, follow docker hub instructions)
# COPY RSPM_2023-06-14.lic /etc/rstudio-pm/license.lic

# Activate the license
# RUN /opt/rstudio-pm/bin/license-manager activate-file /etc/rstudio-pm/license.lic

# Update the timezone
USER root
ENV TZ=America/Los_Angeles
RUN sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Add systemctl commands so we can treat this docker file like a real VM
#RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d
#RUN apt-get install -y systemd systemd-sysv dbus dbus-user-session
#RUN printf "systemctl start systemd-logind" >> /etc/profile
#ENTRYPOINT ["/sbin/init"]

## Utilities
## install just
#curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
## install gh
## https://github.com/cli/cli/blob/trunk/docs/install_linux.md
#type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
#curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
#&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
#&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
#&& sudo apt update \
#&& sudo apt install gh -y
## install rig
#curl -Ls https://github.com/r-lib/rig/releases/download/latest/rig-linux-$(arch)-latest.tar.gz |
#  `which sudo` tar xz -C /usr/local

USER rstudio-pm

#RUN useradd -m lisa
#USER lisa
#CMD /bin/bash

