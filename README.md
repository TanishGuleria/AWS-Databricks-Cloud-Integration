# AWS-Databricks-Cloud-Integration
Complete Integration of Databricks on aws cloud platform with databricks managed vpc 


## Note
Check the below repo for creating the AWS configuration for your Databricks workspaces creation using cloud formation,aws cli and powershell.
- ⚡ (https://github.com/TanishGuleria/Databricks-setup-on-aws)

## Steps

* Make sure all the prerequisite Steps required for AWS configuration for your Databricks is done , if not - ⚡ (https://github.com/TanishGuleria/Databricks-setup-on-aws) navigate to the link for architectural details and  step-by-step instructions.

 - login to aws account 
   - Step 1: Create a CodeCommit repository
   - Step 2: Add these files to your repository

    update the value with your own databrick url and token in databrickscli.ps1 file
     ```
    pip install databricks-cli --upgrade
    $DatabricksUrl = 'Your workspace Url'
    $dapiToken ='update the token'

    $args = @"
    $DatabricksUrl
    $dapiToken
    "@

    Write-Output $args | & databricks configure --token 

    Write-Output "`nDatabricks workspace list:"
    & databricks workspace list
     ``` 
     Before you can run CLI commands, you must set up authentication. To authenticate to the CLI you use a Databricks personal access token. (A Databricks username and password are also supported but not recommended.)
    the above code configure the CLI to use a personal access token during code build.
   - Step 3: Create Create build project using CodeBuild.
   - Step 4: Specify the project configuration,IAM service role and repository to be used (make sure Iam role has all necessary permission).
   - Step 5: in buildspec file mentioned the buildspec.yml
     ```
     version: 0.2
     phases:
        pre_build:
            commands:
                - echo starting deployment `date`
        build:
            commands:
                - echo deployment started on `date`
                - ls
                - pwsh databrickscli.ps1
        post_build:
            commands:
                - echo Completed...
     ```
     This Buildspec file call the databrickscli.ps1 and run the powershell script 