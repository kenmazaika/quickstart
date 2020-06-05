# Metropolis
## Quickstart Guide

This project contains the quickstart guide to integrating with Metropolis.

This project is configured with two projects, a React front-end and a Ruby on Rails backend, and deployments are sent out via Kubernetes and helm, however using any other tools is possible and encouraged, too.

Once setup, pull requests will automatically provision sandbox environments for testing and use the GitHub Deployment API to expose the environment to you during development.


### Teardown

```
state rm google_sql_user.users
terraform destroy
```
