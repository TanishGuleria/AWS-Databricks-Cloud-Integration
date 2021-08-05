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
   - Step 3: Create build project using CodeBuild.
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

     This Buildspec file call's the databrickscli.ps1 and run the powershell script 

   - Step 6: start the build 

## powershell script Functionality

```
#Installing the databricks cli on the agent  
pip install databricks-cli --upgrade
#--------------------------------------------
#Databricks authentication using token 
$DatabricksUrl = 'workspace url'
$dapiToken ='<your token>'

$args = @"
$DatabricksUrl
$dapiToken
"@

Write-Output $args | & databricks configure --token 

Write-Output "`nDatabricks workspace list:"
& databricks workspace list

databricks -v 
#------------------------------------------------------
#updating value of config.json file to be used inside the notebooks 
$EventHubConnstring  = "test"
$Consumer_group = "test"
$EventHub_name = "test"

$original_file = "config.json"
$destination_file =  "config_withdata.json"

(Get-Content $original_file).replace('@@@EventHubConnstring', $EventHubConnstring) | Foreach-Object {
    $_ -replace '@@@Consumer_group', $Consumer_group 
    } | Set-Content $destination_file

Get-Content $destination_file
#adding config.json to dbfs
databricks fs cp --overwrite config_withdata.json dbfs:/FileStore/tables/config.json

#importing notebook to databrick shared workspace 
databricks workspace import SourceCode/Notebook_test.py //Shared/Notebook_test -l PYTHON -o
databricks workspace list //Shared

#------------------------------------------------------------------------------------
#Creating Single node Cluster in databricks workspace  
$zone_id = "us-west-1b" 
$cluster_name = "databrick-cluster"

$original_file = "deployment/cluster_config.json"
$destination_file =  "deployment/cluster_config_withdata.json"

(Get-Content $original_file).replace('@@@zone_id', $zone_id) | Foreach-Object {
    $_ -replace '@@@cluster_name', $cluster_name 
    } | Set-Content $destination_file

Get-Content $destination_file

$tempclusterid = databricks clusters list --output JSON
$tempclusterid
$clusterid_temp = $tempclusterid | ConvertFrom-Json
$clusterid_temp
$cluster_id = $clusterid_temp.clusters.cluster_id
$cluster_id
if($cluster_id -eq $null)
{
write-host("creating cluster....")    
$cluster_id_temp = databricks clusters create --json-file "deployment/cluster_config_withdata.json" | ConvertFrom-Json
$cluster_id=$cluster_id_temp.cluster_id
}
else{
write-host("cluster already exist")
}

write-host("cluster id - $cluster_id")
#----------------------------------------------------------------------------------------------------------------------------
#Creating a job and running the new notebook job
$existing_cluster_id = $cluster_id
$jobname = "job01"
$notebook_path = "/Shared/Notebook_test"
$original_file = "deployment/job01.json"
$destination_file =  "deployment/job01_withdata.json"

(Get-Content $original_file).replace('@@@existing_cluster_id', $existing_cluster_id) | Foreach-Object {
    $_ -replace '@@@name', $jobname `
       -replace '@@@notebook_path', $notebook_path 
    } | Set-Content $destination_file

Get-Content $destination_file

$tempJOBs= databricks jobs list --output JSON 
$tempJOBs
$tempjobs_id = $tempJOBs | ConvertFrom-Json
$jobid = $tempjobs_id.jobs.job_id
$count = $jobid.Count
if($count -ne 0)
{
for($i=0;$i -lt $count;$i++)
{
 write-host("deleting job with job-id")
 $jobid[$i]
 databricks jobs delete  --job-id $jobid[$i] 
}
}
else{
    write-host("no jobs found")
}

write-host("creating job with job-id")
$jobid = databricks jobs create --json-file "deployment/job01_withdata.json"
$jobid
$jobid = $jobid | ConvertFrom-Json
$jobid = $jobid.job_id 
databricks jobs run-now --job-id $jobid

```