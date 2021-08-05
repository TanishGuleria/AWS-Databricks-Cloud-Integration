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
