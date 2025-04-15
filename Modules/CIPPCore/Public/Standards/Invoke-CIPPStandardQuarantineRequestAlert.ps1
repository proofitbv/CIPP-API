function Invoke-CIPPStandardQuarantineRequestAlert {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) QuarantineRequestAlert
    .SYNOPSIS
        (Label) Quarantine Release Request Alert
    .DESCRIPTION
        (Helptext) Sets a e-mail address to alert when a User requests to release a quarantined message.
        (DocsDescription) Sets a e-mail address to alert when a User requests to release a quarantined message. This is useful for monitoring and ensuring that the correct messages are released.
    .NOTES
        CAT
            Defender Standards
        TAG
        ADDEDCOMPONENT
            {"type":"textField","name":"standards.QuarantineRequestAlert.NotifyUser","label":"E-mail to receive the alert"}
        IMPACT
            Low Impact
        ADDEDDATE
            2024-07-15
        POWERSHELLEQUIVALENT
            New-ProtectionAlert and Set-ProtectionAlert
        RECOMMENDEDBY
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards/defender-standards#low-impact
    #>

    param ($Tenant, $Settings)

    $PolicyName = 'CIPP User requested to release a quarantined message'

    $CurrentState = New-ExoRequest -TenantId $Tenant -cmdlet 'Get-ProtectionAlert' -Compliance |
    Where-Object { $_.Name -eq $PolicyName } |
    Select-Object -Property *

    $StateIsCorrect = ($CurrentState.NotifyUser -contains $Settings.NotifyUser)

    if ($Settings.remediate -eq $true) {
        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -Tenant $Tenant -Message 'Quarantine Request Alert is configured correctly' -sev Info
        } else {
            $cmdParams = @{
                'NotifyUser'      = $Settings.NotifyUser
                'Category'        = 'ThreatManagement'
                'Operation'       = 'QuarantineRequestReleaseMessage'
                'Severity'        = 'Informational'
                'AggregationType' = 'None'
            }

            if ($CurrentState.Name -eq $PolicyName) {
                try {
                    $cmdParams['Identity'] = $PolicyName
                    New-ExoRequest -TenantId $Tenant -cmdlet 'Set-ProtectionAlert' -Compliance -cmdParams $cmdParams -UseSystemMailbox $true
                    Write-LogMessage -API 'Standards' -Tenant $Tenant -Message 'Successfully configured Quarantine Request Alert' -sev Info
                } catch {
                    $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                    Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Failed to configure Quarantine Request Alert. Error: $ErrorMessage" -sev Error
                }
            } else {
                try {
                    $cmdParams['name'] = $PolicyName
                    $cmdParams['ThreatType'] = 'Activity'

                    New-ExoRequest -TenantId $Tenant -cmdlet 'New-ProtectionAlert' -Compliance -cmdParams $cmdParams -UseSystemMailbox $true
                    Write-LogMessage -API 'Standards' -Tenant $Tenant -Message 'Successfully created Quarantine Request Alert' -sev Info
                } catch {
                    $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                    Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Failed to create Quarantine Request Alert. Error: $ErrorMessage" -sev Error
                }
            }
        }
    }

    if ($Settings.alert -eq $true) {
        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -Tenant $Tenant -Message 'Quarantine Request Alert is enabled' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -Tenant $Tenant -Message 'Quarantine Request Alert is disabled' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        Add-CIPPBPAField -FieldName 'QuarantineRequestAlert' -FieldValue $StateIsCorrect -StoreAs bool -Tenant $Tenant

        if ($StateIsCorrect) {
            $FieldValue = $true
        } else {
            $FieldValue = @{NotifyUser = $CurrentState.notifyUser }
        }
        Set-CIPPStandardsCompareField -FieldName 'standards.QuarantineRequestAlert' -FieldValue $FieldValue -Tenant $Tenant
    }
}
