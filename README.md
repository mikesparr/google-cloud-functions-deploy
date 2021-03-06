# Google Cloud Functions Auto Deploy
This repo includes a deployment script that will detect which files changed 
and only deploy those cloud functions, supporting multiple function directories 
in a single repo. It's not perfect, but it does support deploying only the functions 
that changed to minimize downtime.

## Background
I synchronized my Github repo with GCloud's source repository and linked the functions to their 
respective directories. My expectation would be that any commits to that directory would trigger a 
deploy automatically. When I discovered that wasn't the case, and would need Cloud Builds, it 
felt a little too much like "vendor lock in" so decided to script this using Travis CI instead so 
our apps are more "portable". See: https://cloud.google.com/functions/docs/deploying/repo

# .travis.yml
```yaml
sudo: false
language: node_js
node:
- '9'
script:
- echo "Amazing!"
env:
  global:
  - GOOGLE_APPLICATION_CREDENTIALS="${PWD}/client-secret.json"
  - PROJECT_NAME_PRD=my-project
  - CLUSTER_NAME_PRD=my-cluster
  - REPOSITORY_ID=my-repo-name
  - CLOUDSDK_COMPUTE_ZONE=us-central1-b
before_deploy:
- if [ ! -d "$HOME/google-cloud-sdk/bin" ]; then rm -rf $HOME/google-cloud-sdk; export
  CLOUDSDK_CORE_DISABLE_PROMPTS=1; curl https://dl.google.com/dl/cloudsdk/channels/rapid/install_google_cloud_sdk.bash
  | sed 's/zxvf/zxf/' | bash; fi
- source /home/travis/google-cloud-sdk/path.bash.inc
- gcloud --quiet version
- gcloud --quiet components update
deploy:
- provider: script
  script: "./deploy/deploy.sh"
  skip_cleanup: true
  on:
    branch: master
```

# Dependencies
 * Github
 * Travis CI
 * Google Cloud Functions
   * optionally enable Cloud PubSub if you don't want `http` triggers
 * Bash 4 (should exist in Travis CI but to test locally you'll need)

# Setup
1. Create a new service account key and download it, renaming to `client-secret.json`
   * **Roles:** `Cloud Functions Editor`, `Source Editor`, `Service Account Actor`
2. Use the `travis` CLI tool and encrypt `travis encrypt-file client-secret.json --add`
3. Place your functions in a `functions/functionName/` folder
4. Add function to the `functions.sh` file with either http trigger or pub-sub topic
5. Add `client-secret.json` to your `.gitignore` file
6. Add your project files, commit, and push (assuming you linked repo to Travis CI)

# Best Practices
 * Testing: https://cloud.google.com/functions/docs/bestpractices/testing
 * Security: I suggest you place any `http` trigger functions behind an API Gateway. I use Kong, 
   but others would work just as fine. You may also simply reverse proxy with a web server and 
   add authentication.

# TODO
 * Avoid deploying function multiple times if multiple files in directory edited
