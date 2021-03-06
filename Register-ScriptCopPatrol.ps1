function Register-ScriptCopPatrol
{    
    <#
    .Synopsis
        Registers a ScriptCop patrol, or logical group of rules.
    .Description
        Registers a ScriptCop patrol, or logical group of rules.
        A patrol links command rules and modules rules so that you
        can quickly and easily check for a set of problems, and incrementally
        improve your code.
    .Example    
        Register-ScriptCopPatrol -Name Test-BasicDocs -Description "Checks for basic documentation" -CommandRule Test-Help -ModuleRule Test-ModuleHasAnAboutTopic
    .Link
        Unregister-ScriptCopPatrol
    #>
    param(
    # The name of the script cop patrol
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    
    # The command rules to include in the patrol
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $CommandRule,
    
    # The module rules to include in the patrol
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $ModuleRule,
    
    # The description of the scriptcop patrol
    [string]
    $Description
    )
    
    begin {
        if (-not ($script:ScriptCopPatrols)) {
            $script:ScriptCopPatrols = @{}            
        }
    }
        
    process {
        if (-not ($script:ScriptCopPatrols[$name])) {
            $script:ScriptCopPatrols[$name] = @{
                CommandRule = @()
                ModuleRule = @()
                Description = ""
            }
        }
        if ($moduleRule) {    
            $ScriptCopPatrols[$name].ModuleRule += $ModuleRule
        }
        if ($commandrule) {
            $ScriptCopPatrols[$name].CommandRule += $CommandRule
        }
        
        if ($description) {
            $ScriptCopPatrols[$name].Description = $description
        }
    }
} 
 
