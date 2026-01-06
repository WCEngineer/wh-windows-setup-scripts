Write-Host 'Configuring Chocolatey to use local Nexus repository'
# choco source disable --name='chocolatey'
choco source add --name='nexus' --source='http://nexus.whittet-higgins.com/repository/chocolatey-group/' --priority=0
choco config set --name="commandExecutionTimeoutSeconds" --value="14400"
