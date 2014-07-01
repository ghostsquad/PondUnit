$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Add-Type -AssemblyName 'System.IO.Compression.Filesystem'
Add-Type -Path (Join-Path $here "xunit.dll")

. $here\Invoke-PoshUnit.ps1
. $here\New-TestFixture.ps1
. $here\New-TestSetup.ps1
. $here\New-TestTeardown.ps1
. $here\New-Test.ps1
. $here\Get-TestDetails.ps1

Export-ModuleMember -Function *-*