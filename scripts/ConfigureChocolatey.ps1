Write-Host 'Configuring Chocolatey to use local Nexus repository'
# choco source disable --name='chocolatey'
choco source add --name='nexus' --source='http://192.168.1.200:8081/repository/chocolatey-group/' --priority=0
choco config set --name="commandExecutionTimeoutSeconds" --value="14400"
