function New-TestTeardown {
	param(
		[scriptblock]$teardownDefinition = $(throw "-teardownDefinition parameter required!")
	)
	$teardownDefinition | Add-Member -MemberType NoteProperty -Name IsPoshUnitTestTeardown -Value $true
	Write-Output $teardownDefinition
}