function New-Test {
	param(
		[scriptblock]$testDefinition = $(throw "-testDefinition parameter required!")
	)
	$testDefinition | Add-Member -MemberType NoteProperty -Name IsPoshUnitTest -Value $true
	Write-Output $testDefinition
}