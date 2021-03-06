function Test-ForUnusableFunction 
{
    #region     ScriptTokenValidation Parameter Statement
    param(
    <#    
    This parameter will contain the tokens in the script, and will be automatically 
    provided when this command is run within ScriptCop.
    
    This parameter should not be used directly, except for testing purposes.        
    #>
    [Parameter(ParameterSetName='TestScriptToken',
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSToken[]]
    $ScriptToken,
    
    <#   
    This parameter will contain the command that was tokenized, and will be automatically
    provided when this command is run within ScriptCop.
    
    This parameter should not be used directly, except for testing purposes.
    #>
    [Parameter(ParameterSetName='TestScriptToken',Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.CommandInfo]
    $ScriptTokenCommand,
    
    <#
    This parameter contains the raw text of the script, and will be automatically
    provided when this command is run within ScriptCop
    
    This parameter should not be used directly, except for testing purposes.    
    #>
    [Parameter(ParameterSetName='TestScriptToken',Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]
    $ScriptText
    )
    #endregion  ScriptTokenValidation Parameter Statement
    
    
    process {              
        $hasWriteHost = $ScriptToken |
            Where-Object { $_.Type -eq "Command" -and $_.Content -eq "Write-Host" }
        
        if ($hasWriteHost) {
            Write-Error "$ScriptTokenCommand uses Write-Host.  Write-Host makes your scripts unsuable inside of other scripts.  If you need to add tracing, consider Write-Verbose and Write-Debug"            
        }
        
        $hasReadHost = $ScriptToken |
            Where-Object { $_.Type -eq "Command" -and $_.Content -eq "Read-Host" }
        
        if ($hasReadHost) {
            Write-Error "$ScriptTokenCommand uses Read-Host.  Read-Host makes your scripts unsuable inside of other scripts, because it means part of your script cannot be controlled by parameters.  If you need to prompt for a value, you should create a mandatory parameter."            
        }
        
        
        $hasConsoleAPI = $ScriptToken |
            Where-Object { $_.Type -eq "Type" -and 
                ($_.Content -eq "Console" -or
                $_.Content -eq "System.Console")
                }

        if ($hasConsoleAPI) {
            Write-Error "$ScriptTokenCommand uses the console API.  Using the console API ensures your script will only work in PowerShell.exe."            
        }

    }
} 
