# Deployment pipeline

- Build: Commit stage (compile, unit tests, analysis, build installers)
    Resources, tasks, job
    ```sh
    $ fly -t comandante set-pipeline -p pet-clinic -c pipeline.yml
    $ fly -t comandante pipelines
    ```
- Automated acceptance testing
- Automated capacity testing
- [optional] Manual testing
- Release
