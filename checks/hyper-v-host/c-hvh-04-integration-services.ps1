<#
    DESCRIPTION: 
        Check the version of the Integration Services installed on all VMs

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:    
            All VMs are up to date
        WARNING:
        FAIL:
            One or more VMs are not up to date, or do not have the integration services installed
        MANUAL:
        NA:
            No VMs are located on this host
            Not a Hyper-V server

    APPLIES:
        Hyper-V Host Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function c-hvh-04-integration-services
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = $script:lang['Name']
    $result.check  = 'c-hvh-04-integration-services'
 
    #... CHECK STARTS HERE ...#

    If ((Check-NameSpace -ServerName $serverName -NameSpace 'ROOT\Virtualization') -eq $true)
    {
        Try
        {
            [string]$query = 'SELECT * FROM Msvm_ComputerSystem WHERE Caption="Virtual Machine"'
            [object]$check = Get-WmiObject -ComputerName $serverName -Query $query -Namespace ROOT\Virtualization\v2
        }
        Catch
        {
            $result.result  = $script:lang['Error']
            $result.message = $script:lang['Script-Error']
            $result.data    = $_.Exception.Message
            Return $result
        }

        If ($check.Count -ne 0)
        {
            [string]$result.data = ''
            ForEach ($vm In $check)
            {
                $VSMS = Get-WmiObject -Class 'Msvm_VirtualSystemManagementService' -Namespace ROOT\Virtualization\v2
                $Info = $VSMS.GetSummaryInformation($vm.__PATH, 123)

                Switch ($Info.SummaryInformation[0].IntegrationServicesVersionState)
                {
                    '0' { $result.data += "$($vm.ElementName): Unknown,#"     }    # Unknown
                    '1' { $result.data += ''                                  }    # Up To Date
                    '2' { $result.data += "$($vm.ElementName): Out of date,#" }    # Out Of Date
                }
            }

            If ($result.data -ne '')
            {
                $result.result  = $script:lang['Fail']
                $result.message = 'One or more VMs are not up to date, or do not have the integration services installed'
            }
            ELse
            {
                $result.result  = $script:lang['Pass']
                $result.message = 'All VMs are up to date'
            }
        }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = 'No VMs are located on this host'
        }
    }
    Else
    {
        $result.result  = $script:lang['Not-Applicable']
        $result.message = 'Not a Hyper-V host server'
    }

    Return $result
}
