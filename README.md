# Deployment pipeline

## Context

## Requirements
In order to run this workshop you will need to have the following tools available in your local workstation:
- [fly](https://concourse-ci.org/download.html)

## Setup
`fly` is a command line interface that allows you to interact with Concourse.

Follow the steps below in order to configure `fly`:
1. Log into Concourse and add the Concourse server to your fly CLI target's list: `fly -t comandante login --concourse-url https://play.comandante.ci/`
1. Check that you have logged in successfully and your fly CLI can talk to Concourse: `fly -t comandante status`

## 1st step: create a job called `build`
In this step we are going to create a `build` job that will compile the application and run unit tests.

Continuous delivery best practices:
- Only build binaries once

1. Create a file called pipeline.yml that you will use to create all your pipeline configuration
1. Create a [Job](https://concourse-ci.org/jobs.html) called `build` with an empty [Plan](https://concourse-ci.org/jobs.html#job-plan)
1. Set the pipeline with `fly -t comandante set-pipeline -p <pipeline name> -c pipeline.yml -l secrets.yml`
1. Run `fly -t comandante pipelines` and observe that your pipeline was successfully created
1. Create a [ Git Resource ](https://github.com/concourse/git-resource) for `https://github.com/spring-projects/spring-petclinic` (more about Resources [here](https://concourse-ci.org/resources.html))
1. Add a Task called `package` to `build` that will run `./mvnw package` inside a `openjdk:8-jdk-slim` Docker container
1. Trigger the `build` and make sure it is green: `fly -t comandante -j <pipeline name>/build`
1. Create an Output to save the jar to our S3-compatible server:

```yaml
- name: compiled-jar
  type: s3
    source:
    bucket: devopsdayberlin
    endpoint: http://35.240.36.56:9000
    disable_ssl: true
    access_key_id: admin
    secret_access_key: devopsdayberlin2018
    regexp: spring-petclinic-(.*).jar
```
1. Create a semver Resource that will store the version to be used in our S3-compatible server:

```yaml
- name: version
  type: semver
  source:
    driver: s3
    bucket: devopsdayberlin
    endpoint: http://35.240.36.56:9000
    disable_ssl: true
    access_key_id: admin
    secret_access_key: devopsdayberlin2018
    key: workshop/release-version
```
1. Modify the `package` Task to create a jar using the version from the semver Resource

## 2nd step: create a Job called `perf-test`
In this step we are going to deploy the app to a staging environment and run performance tests

1. Create a Job called `perf-test` and pass the `compiled-jar` Resource to it using the `passed` in the `get` Step
1. Create a Task called `deploy-to-perf-env` that will download the jar and deploy to a CloudFoundry test environment 

```yaml
- task: deploy-to-perf-env
  config:
    platform: linux
    image_resource:
      type: docker-image
      source:
        repository: governmentpaas/cf-cli
    inputs:
      - name: compiled-jar
    params:
      CF_API: ((cf_api))
      CF_USERNAME: ((cf_user))
      CF_PASSWORD: ((cf_password))
      CF_SPACE: system
      CF_ORG: system
    run:
      path: /bin/sh
      args:
        - -c
        - |
            set -eu
            cf api $CF_API --skip-ssl-validation
            cf auth $CF_USERNAME $CF_PASSWORD
            cf target -o $CF_ORG -s $CF_SPACE
            cf push pet-clinic1 -p compiled-jar/*.jar
```
1. Create a Task to run the performance tests `PETCLINIC_HOST=localhost PETCLINIC_PORT=8080 jmeter -n -t src/test/jmeter/petclinic_test_plan.jmx -l $TMPDIR/log.jtl`
1. Create a Ensure Step to guarantee that the pushed app will be deleted in case of success or failure

## 3tr step: create a Job called `deploy`
In this step we are going to deploy the app to production.

1. Create a Job called `deploy` and pass the `compiled-jar`
1. Create a Task called `push-to-prod` and push the `compiled-jar` to the prod org and space
