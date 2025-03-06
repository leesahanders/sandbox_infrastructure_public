## Package Manager CRAN repository configuration

For configuring a repository in Package Manager I'd recommend referring to these two pages: 
Quick start: https://docs.posit.co/rspm/admin/getting-started/configuration/ 
Package blocking for vulnerabilities: https://docs.posit.co/rspm/admin/security/package/#rules-system

The steps might end up looking something like this (but tweak based on your needs): 

```
# Make sure that after SSH-ing in to the Package manager server that the user running these commands are a part of the rstudio-pm group
sudo usermod -aG rstudio-pm <USER>

# Set the var
rspm=/opt/rstudio-pm/bin/rspm

# check that package manager is up
curl --retry 5 --retry-connrefused https://localhost/pkg/__api__/status

# Verify that you are able to run commands
${rspm} verify

# Create repositories and sync CRAN
${rspm} create repo --name=cran --description='Access CRAN packages'
${rspm} subscribe --repo=cran --source=cran
${rspm} sync --wait

# Create blocklist rule to block vulnerable packages, this will apply across all repositories and sources
${rspm} rspm create blocklist-rule --vulns

# Alternatively we could block just the specific source or repository
${rspm} create blocklist-rule --source=cran --vulns
```

Verify that it works by going through the UI and seeing that the repository is listed in the drop down. Additional repositories can be added for curated package sets, python, project specific libraries, internal packages, etc. 