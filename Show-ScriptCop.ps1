function Show-ScriptCop 
{            
    <#
    .Synopsis
        Shows a tool for helping you walk thru ScriptCop results
    .Description
        Shows a tool for helping you walk thru ScriptCop results.  
        
        Show-ScriptCop was written using ShowUI.  http://ShowUI.Codeplex.Com
    .Example
        Show-ScriptCop -AsJob
    .Link
        http://showui.codeplex.com/
    #>
    [OutputType([Windows.Controls.Border])]            
    param(
    # If set, runs ScriptCop full screen                                
    [Switch]$FullScreen,             
                
    # The name of the control            
    [string]$Name,            
    # If the control is a child element of a Grid control (see New-Grid),            
    # then the Row parameter will be used to determine where to place the            
    # top of the control.  Using the -Row parameter changes the            
    # dependency property [Windows.Controls.Grid]::RowProperty            
    [Int]$Row,            
    # If the control is a child element of a Grid control (see New-Grid)            
    # then the Column parameter will be used to determine where to place            
    # the left of the control.  Using the -Column parameter changes the            
    # dependency property [Windows.Controls.Grid]::ColumnProperty            
    [Int]$Column,            
    # If the control is a child element of a Grid control (see New-Grid)            
    # then the RowSpan parameter will be used to determine how many rows            
    # in the grid the control will occupy.   Using the -RowSpan parameter            
    # changes the dependency property [Windows.Controls.Grid]::RowSpanProperty            
    [Int]$RowSpan,            
    # If the control is a child element of a Grid control (see New-Grid)            
    # then the RowSpan parameter will be used to determine how many columns            
    # in the grid the control will occupy.   Using the -ColumnSpan parameter            
    # changes the dependency property [Windows.Controls.Grid]::ColumnSpanProperty            
    [Int]$ColumnSpan,            
    # The -Width parameter will be used to set the width of the control            
    [Int]$Width,             
    # The -Height parameter will be used to set the height of the control            
    [Int]$Height,            
    # If the control is a child element of a Canvas control (see New-Canvas),            
    # then the Top parameter controls the top location within that canvas            
    # Using the -Top parameter changes the dependency property            
    # [Windows.Controls.Canvas]::TopProperty            
    [Double]$Top,            
    # If the control is a child element of a Canvas control (see New-Canvas),            
    # then the Left parameter controls the left location within that canvas            
    # Using the -Left parameter changes the dependency property            
    # [Windows.Controls.Canvas]::LeftProperty            
    [Double]$Left,            
    # If the control is a child element of a Dock control (see New-Dock),            
    # then the Dock parameter controls the dock style within that panel            
    # Using the -Dock parameter changes the dependency property            
    # [Windows.Controls.DockPanel]::DockProperty            
    [Windows.Controls.Dock]$Dock,            
    # If Show is set, then the UI will be displayed as a modal dialog within the current            
    # thread.  If the -Show and -AsJob parameters are omitted, then the control should be            
    # output from the function            
    [Switch]$Show,            
    # If AsJob is set, then the UI will displayed within a WPF job.            
    [Switch]$AsJob            
            
    )            
                
    process {            
        $uiParameters = @{} + $psBoundParameters
        $uiParameters.Remove('FullScreen')
        $psBoundParameters.FullScreen  =$fullScreen    
        
        $globalLoadedModules = Get-Module | 
            Where-Object { 
                $env:PSModulePath -split ";" -contains (Split-Path (Split-Path -Path $_.Path))        
            } | Select-Object -ExpandProperty Name
       
            
        New-Border @uiParameters -ControlName Show-ScriptCop -HorizontalAlignment Stretch -VerticalAlignment Stretch -Resource @{                       
            ErrorUpdater = {
                $errors = Get-PowerShellOutput -ErrorOnly -Last
                $ErrorHolder.Visibility = 'Visible'
                $ErrorHolder.Content = $errors | Out-String -Width 1kb
            }
            GlobalLoadedModules = $globalLoadedModules
            Powershell_Ise = $psise
            PowerGui = $PGSE
        } -On_SizeChanged {                      
            if ($_.PreviousSize.Width -ne 0 -or $_.PreviousSize.Height -ne 0) {
                return
            }
            $sb= {param([string[]]$globalLoadedModules)
                Import-Module $globalLoadedModules
                Import-Module ScriptCop
                New-Object PSObject -Property @{
                    ModulesAvailable= @(Get-Module -ListAvailable)
                    CommandsAvailable=  Get-Command -CommandType Cmdlet, Function
                    Patrols = Get-ScriptCopPatrol
                    Rules = Get-ScriptCopRule
                }             
            }
            
            Invoke-Background -Parameter @{
                GlobalLoadedModules = $globalLoadedModules
            } -ScriptBlock $sb -control $parent -On_OutputChanged {
                $lastOut = Get-PowerShellOutput -Last -OutputOnly    
                if ($lastOut.ModulesAvailable -as [Management.Automation.PSModuleInfo[]]) {
                    # It's a module, update the module tree                                       
                    foreach ($module in $lastOut.ModulesAvailable) {
                        $moduleExists = foreach ($m in $moduleTree.Items) {if ($m.Header -eq "$module") { $m }}
                        if ($moduleExists) {
                        } else {
                            $newTreeViewItem = 
                                New-TreeViewItem -Header "$module" -Tag $module -Items {
                                    foreach ($exc in $module.ExportedCommands.Values) {
                                        if (-not $exc) { continue } 
                                        New-TreeViewItem -Header "$exc" -Tag $exc 
                                    }
                                }
                            $moduleTree.Items.add($newTreeViewItem)
                            $moduleTree.UpdateLayout()
                        }
                    }
                }
                if ($lastOut.Patrols) {
                    $patrolComboBox.ItemsSource = @("") + @($lastOut.Patrols | Select-Object -ExpandProperty Name)
                }
                if ($lastOut.Rules) {
                    $ruleComboBox.ItemsSource = @("") + @($lastOut.Rules | Select-Object -ExpandProperty Name) 
                }
            } -On_ProgressChanged {
                $lastOut = Get-PowerShellOutput -Last -ProgressOnly
                if ($lastOut.RecordType -ne 'Completed') {
                    $ProgressHolder.Visibility = 'Visible'
                    $progressHolder.DataContext = $lastOut
                } else {
                    $ProgressHolder.Visibility = 'Collapsed'
                }
            } -On_ErrorChanged $ErrorUpdater 
        } -Child {
            New-Grid -MinWidth 640 -MinHeight 640 -Name ScriptCopGrid -Columns 2*, 'Auto', 10* -Rows '10*', 'Auto', '1*','Auto','Auto' -Children {

                New-TreeView -MaxWidth 640 -MaxHeight 640 -Name ModuleTree -On_SelectedItemChanged {
                    $runScriptCop.IsEnabled = $this.SelectedItem
                }                    
                
                New-GridSplitter -Column 1 -VerticalAlignment Stretch -HorizontalAlignment Center -Background Black -Width 2.5 -ShowsPreview                
                New-ListBox -On_MouseDoubleClick { 
                    if ($this.SelectedItem) {
                        $file = $this.SelectedItem.ItemWithProblem.ScriptBlock.File
                        if ($file) {
                            if ($powershell_ise) {
                                $powershell_ise.CurrentPowerShellTab.Files.Add($file)
                            } elseif ($powergui) {
								$powergui.DocumentWindows.add($file)
							}
                        }
                    }
                } -MaxWidth 640 -MaxHeight 640 -Visibility Collapsed -Column 2 -Name ScriptCopResults -ItemTemplate {
                    New-StackPanel -Orientation Horizontal -MaxWidth 640 -Children { 
                        New-TextBlock -Name "ItemWithProblem" -FontWeight DemiBold
                        New-TextBlock ":"
                        New-TextBlock -Name "Problem" -TextWrapping Wrap 
                    } | ConvertTo-DataTemplate @{
                        "ItemWithProblem.Text" = "ItemWithProblem"
                        "Problem.Text" = "Problem"
                    }
                } 
                New-GridSplitter -ColumnSpan 3 -Row 1 -VerticalAlignment Center -HorizontalAlignment Stretch -Background Black -Height 2.5 -ShowsPreview
                New-Grid -Name ToolbarGrid -Row 2 -ColumnSpan 3 -Columns 3 -Children {
                    New-Button -Name RunScriptCop -Margin 5 -Column 1 "Run ScriptCop" -On_Click {
                        $ScriptCopResults.Visibility = 'Visible'
                        $invokeBackgroundParameters = @{
                            Control = $parent
                            On_ProgressChanged =  {
                                $progress = Get-PowerShellOutput -Last -ProgressOnly
                                $statusDescription.Text = $progress.StatusDescription
                                $activityText.Text = $progress.activity
                                $progressPercent.Value = $progress.percentComplete
                                $progressHolder.UpdateLayout()
                            }
                            On_OutputChanged = {
                                $results = Get-PowerShellOutput -Last -OutputOnly
                                $progressHolder.Visibility = 'Collapsed'
                                $ScriptCopResults.ItemsSource = @($results.ScriptCopResults)
                                
                                if ($results.Module) {
                                    foreach ($it in $moduleTree.Items) {
                                        if ($it.header -eq "$($results.Module)") {
                                            $it.Items.Clear()
                                            $it.Tag = $results.Module
                                            foreach ($exc in $results.module.ExportedCommands.Values) {
                                                if (-not $exc) { continue }
                                                $tvi = New-TreeViewItem -Header "$exc" -Tag $exc 
                                                $it.Items.Add($tvi)
                                            }
                                            
                                            break
                                        }
                                    }
                                }                                                                  
                                $ScriptCopResults.UpdateLayout()                                                                                                                      
                            }
                            On_ErrorChanged = $errorUpdater                            
                        }
                        if ($moduleTree.SelectedItem.Tag -is [Management.Automation.PSModuleInfo]) {
                            $ProgressHolder.Visibility = 'Visible'
                            Invoke-Background @invokeBackgroundParameters -ScriptBlock {
                                param($moduleName, $patrol = "", $rule = "")
                                Import-Module ScriptCop
                                $results = Import-Module $moduleName -Force -PassThru | 
                                    Test-Command -Patrol $patrol -Rule $rule 
                                New-Object PSObject -Property @{
                                    ScriptCopResults = $results                                
                                    Module = Get-Module $ModuleName 
                                }
                            } -Parameter @{
                                moduleName =  $moduleTree.SelectedItem.Tag.Name 
                                rule = $ruleComboBox.Text
                                patrol = $patrolComboBox.Text
                            } 
                        }
                        
                        if ($moduleTree.SelectedItem.Tag -is [Management.Automation.CommandInfo]) {
                            $ProgressHolder.Visibility = 'Visible'
                            Invoke-Background @invokeBackgroundParameters  -ScriptBlock {
                                param($commandName, $patrol = "", $rule = "")
                                Import-Module ScriptCop
                                New-Object PSObject -Property @{
                                    ScriptCopResults=  Get-Command $commandName | 
                                        Test-Command -patrol $patrol -rule $rule                                                                   
                                }                                
                            } -Parameter @{
                                CommandName =  $moduleTree.SelectedItem.Tag.Name 
                                Patrol = $patrol.Text
                                Rule = $rule
                            } -On_ProgressChanged $ProgressUpdater -On_ErrorChanged $ErrorUpdater
                        }                                                
                    }
                    New-UniformGrid -Column 2 -Columns 2 -Rows 2 {
                        "Patrol" 
                        New-ComboBox -Name PatrolComboBox
                        "Rule" 
                        New-ComboBox -Name RuleComboBox
                    }
                }
                
                
                New-Label -Foreground Red -ColumnSpan 3 -Row 3 -Name ErrorHolder -Visibility Collapsed 
                New-Grid -ColumnSpan 3 -Row 4 -Name ProgressHolder -Visibility Collapsed -Children {
                    New-TextBlock -Margin 10 -Name ActivityText -TextWrapping Wrap -ZIndex 1 -HorizontalAlignment Left -FontWeight Bold -FontSize 12 -DataBinding @{            
                        "Text" = "Activity"            
                    }            
                    New-TextBlock -Margin 10 -ZIndex 1 -Name StatusDescription -TextWrapping Wrap -Column 1 -VerticalAlignment Bottom -HorizontalAlignment Right -FontStyle Italic -FontSize 12 -DataBinding @{            
                        "Text" = "StatusDescription"            
                    }            
                    New-ProgressBar -ColumnSpan 2 -Name ProgressPercent -DataBinding @{            
                        "Value" = "PercentComplete"            
                    }            
                }
            }
        }
    }            
}