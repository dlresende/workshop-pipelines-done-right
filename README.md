## Continuous Delivery Best Practices
- Only build your binaries once
  - Covered by uploading jar to github in the end of the `build` Job
- Deploy the same way to every environment
  - Covered by using the same script to deploy both test and prod
- Smoke-test your deployments
  - Covered by running the smoke-tests after deploying to staging and prod
- Deploy into a copy of production
  - Covered by deploying to a CF, but different space
- Each change should propagate through the pipeline instantly
  - Covered by using the `serial` keyword on jobs
- If any part of the pipeline fails, stop the line
  - Covered by using the keyword `passed` when getting resources from previous jobs

# Deployment pipeline

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

1. Clone this repository and create a file called `pipeline.yml` that you will use to create all your pipeline configuration
1. Edit the `secrets.yml` file and add your team name in there. You will need it in order to distiguish your pipeline in Concourse.
1. Create a [Job](https://concourse-ci.org/jobs.html) called `build` with an empty [Plan](https://concourse-ci.org/jobs.html#job-plan).
1. Set the pipeline with `fly -t comandante set-pipeline -p <pipeline name> -c pipeline.yml -l secrets.yml`.
1. Run `fly -t comandante pipelines` and observe that your pipeline was successfully created.
1. By default, pipelines are paused in Concourse when they are created. Run `fly -t comandante unpause-pipeline -p <pipeline name>` to unpause the pipeline.
1. Create a [ Git Resource ](https://github.com/concourse/git-resource) for `https://github.com/spring-projects/spring-petclinic` (more about Resources [here](https://concourse-ci.org/resources.html)).
1. Add a Task called `package` to the `build` Job. That task will run `./mvnw package` inside a `openjdk:8-jdk-slim` Docker container.
1. Trigger the `build` Job and make sure it is green: `fly -t comandante -j <pipeline name>/build`
1. Create an [`output`](https://concourse-ci.org/tasks.html#task-outputs) in the `package` Task to save the jar to our S3-compatible server using the [s3-resource](https://github.com/concourse/s3-resource):
  - You will need to declare the Resource in `pipelines.yml` and use:
```yaml
regexp: ((team))/packages/spring-petclinic-(.*).jar
```
  - You will need to create a [ `put` Step ](https://concourse-ci.org/put-step.html) in the `build` Job which will upload the jar
  - Then create the `output` that will make the jar inside the Task container available to the `put` Step
  - You will find the credentials to an S3 bucket-like service in `secrets.yml`

## 2nd step: create a Job called `deploy`
In this step, we are going to deploy the app to a staging environment and run smoke-tests.

1. Create a Task called `push-to-staging` that will download the jar and deploy to a CloudFoundry staging environment:
  - You will need to pass the jar produced in the previous Job (use the [`get` Step](https://concourse-ci.org/get-step.html) and use the [ `passed` Parameter](https://concourse-ci.org/get-step.html#get-step-passed) to instruct Concourse to use the Resource used by the previous Job)
  - Use the [`governmentpaas/cf-cli`](https://hub.docker.com/r/governmentpaas/cf-cli/) Docker image (the `cf` CLI is available there)
  - [Here](http://cli.cloudfoundry.org/en-US/cf/push.html) you can find some intructions on how to deploy an app to CF (use `petclinic-((cf_staging_space))-((team))` as your app name
  - You will find the CF credentials you need in `secrets.yml` (use [ `params` ](https://concourse-ci.org/task-step.html#task-step-params) to pass the credentials to your Task commands).
1. Create a Task called `smoke-test` that will run smoke tests against the deployed application (this can be a `curl` call for now hitting the URL `http://petclinic-((cf_staging_space))-((team)).((cf_app_domain))`)
1. Set the pipeline and make sure it is green

## 3nd step: create a Job called `test`
In this step we are going to run acceptance/performance tests.

1. Create a Job called `test`. You will need to pass the jar we deployed to staging and the source code.
  - We are not going to use the jar on this Job actually, but it needs to be here so we can pass it the the downstream Jobs
  - We need the sourse code because the test plan we will use lives there
1. Create a Task to run the performance tests using `PETCLINIC_HOST=localhost PETCLINIC_PORT=8080 jmeter -n -t src/test/jmeter/petclinic_test_plan.jmx -l $TMPDIR/log.jtl`
1. Set the pipeline and make sure it is green

## 4th step: create a Job called `deploy`
In this step we are going to deploy the app to production.

1. Create a Job called `deploy` and get the jar from the previous Job
1. Create a Task called `push-to-prod` and push the jar to the prod Space in CloudFoundry (you will find the credentials in `secrets.yml`)
1. Set the pipeline and make sure it is green
