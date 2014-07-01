function Get-TestDetails {
	param (
		[string]$testName
	)
	$test = ($global:testResults | ?{$_.name -eq $testName})
	
	if($test -eq $null)	{
		Write-Host "No test found with name [$testName]" -ForegroundColor Red	
	}
	
	Write-Host
	
	Write-Host "TestName: " -ForegroundColor Yellow -NoNewline
	Write-Host $test.Name
	Write-Host "Result  : " -ForegroundColor Yellow -NoNewline
	if($test.Result -eq "passed"){
		Write-Host $test.Result -ForegroundColor Green
	}
	else {
		Write-Host $test.Result -ForegroundColor Red
	}
	Write-Host
	Write-Host "Output" -ForegroundColor Yellow
	Write-Host "---------------------"
	Write-Host
	Write-Host $test.Output	
	Write-Host
	Write-Host "---------------------"
	Write-Host
}