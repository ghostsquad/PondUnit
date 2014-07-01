function New-TestFixture {
	param(
		[scriptblock]$fixtureDefinition = $(throw "-fixtureDefinition parameter required!")
	)
	$fixtureDefinition | Add-Member -MemberType NoteProperty -Name IsPoshUnitTestFixture -Value $true
	Write-Output $fixtureDefinition
}