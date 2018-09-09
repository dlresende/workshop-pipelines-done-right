# Deployment pipeline

## Context

## Requirements
In order to run this workshop you will need to have the following tools available in your local workstation:
- [fly](https://concourse-ci.org/download.html]

## 1st step: create a job called `build`
In this step we are going to create a `build` job that will compile the application and run unit tests.

1. Create a file called pipeline.yml that you will use to create all your pipeline configuration
1. Create a [Job](https://concourse-ci.org/jobs.html) called `build` with an empty [Plan](https://concourse-ci.org/jobs.html#job-plan)
1. Set the pipeline with `fly -t <target> set-pipeline -p <pipeline name> -c pipeline.yml`
1. Run `fly -t <target> pipelines` and observe that your pipeline was successfully created
1. Create a [ Git Resource ](https://github.com/concourse/git-resource) for `https://github.com/spring-projects/spring-petclinic` (more about Resources [here](https://concourse-ci.org/resources.html))
1. Add a Task called `package` to `build` that will run `./mvnw package` inside a `openjdk:8-jdk-slim` Docker container
1. Trigger the `build` and make sure it is green: `fly -t comandante <target> -j <pipeline name>/build`

## 2nd step: create a Job called `perf-test`

## 3tr step: create a Job called `deploy`
