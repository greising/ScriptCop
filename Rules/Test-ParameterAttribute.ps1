function Test-ParameterAttribute
{
    #region     ScriptTokenValidation Parameter Statement
    param(
    <#    
    This parameter will contain the scriptToken in the script, and will be automatically 
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
       
        for ($tokenIndex = 0; $tokenIndex -lt $scriptToken.Count; $tokenIndex++) 
        {
            $token = $scriptToken[$tokenIndex]
            if ($token.Type -eq 'Attribute' -and $token.Content -eq 'Parameter') {
               $parameterAttributeStart = $tokenIndex - 1
               $foundGrouping = $false
               for ($parameterBalanceIndex = $parameterAttributeStart; 
                    $parameterBalanceIndex -lt $scriptToken.Count;
                    $parameterBalanceIndex++) 
                {
                    $parameterToken = $scriptToken[$parameterBalanceIndex]
                    if ($parameterToken.Type -eq 'Operator') {
                        if ($parameterToken.Content -eq '[') {
                            $foundGrouping = $true
                            $groupingCount++
                        } elseif ($parameterToken.Content -eq ']') {
                            $groupingCount--
                        }
                    }
                    
                    if ($GroupingCount -eq 0 -and $foundGrouping) {
                        # Once the grouping count has reached zero, 
                        # we're balanced.  Now, check for bugs
                        $parameterAttributes = $scriptToken[$parameterAttributeStart..$parameterBalanceIndex]
                        
                        if ($parameterAttributes.Count -eq 5) {
                            # The only valid [Parameter()] attribute with 5 tokens is an empty attribute
                            Write-Error "Empty [Parameter()] attributes do very little.  Please fill the attribute in or remove it."                            
                        }
                        
                        for ($findBadTriplet = 0; 
                            $findBadTriplet -lt ($parameterAttributes.Count - 3); 
                            $findBadTriplet++) {
                            
                            $triplet = ($parameterAttributes[($findBadTriplet), ($findBadTriplet + 1), ($findBadTriplet + 2)] | 
                                Select-Object -ExpandProperty Content) -join ''
                                                        
                            if ($triplet -ieq 'ValueFromPipeline=false') {
                                $ErrorRecord = @{
                                    ErrorId='TestParameterAttribute.OverAttributedValueFromPipeline'
                                    Message='Over-attribution can be confusing.  ValueFromPipeline=$false is the default, so please remove it.'
                                }
                                Write-Error @ErrorRecord
                            } elseif ($triplet -ieq 'ValueFromPipelineByPropertyName=false') {
                                $ErrorRecord = @{
                                    ErrorId='TestParameterAttribute.OverAttributedValueFromPipelineByPropertyName'
                                    Message='Over-attribution can be confusing.  ValueFromPipelineByPropertyName=$false is the default, so please remove it.'
                                }
                                Write-Error @ErrorRecord
                            } elseif ($triplet -ieq 'Mandatory=false') {
                                $ErrorRecord = @{
                                    ErrorId='TestParameterAttribute.OverAttributedMandatory'
                                    Message='Over-attribution can be confusing.  Mandatory=$false is the default, so please remove it.'
                                }
                                Write-Error @ErrorRecord
                            }
                        }
                        
                        break
                    }                     
                }
            }
        }            
    }
} 
 
