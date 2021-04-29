# chrome-remote-index

## Repo Layout

[deployment](deployment/) contains the script used to deploy a remote-index
serving instance to GCP. It takes care of VM creation and deploying new docker
containers.

[docker](docker/) contains the scripts used by remote-index serving instance to
fetch new index files and startup the clangd-index-server. It also contains the
Dockerfile that containerizes this process.
