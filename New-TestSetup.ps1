function New-TestSetup {
	param(
		[scriptblock]$setupDefinition = $(throw "-setupDefinition parameter required!")
	)
	$setupDefinition | Add-Member -MemberType NoteProperty -Name IsPoshUnitTestSetup -Value $true
	Write-Output $setupDefinition
}