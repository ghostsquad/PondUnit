function Invoke-PoshUnit {
	param (
		[Parameter(Position=0,Mandatory=$false)]
        [Alias('relative_path')]
        [string]$Path = "."
	)
	
	$ErrorActionPreference = "Stop"
	$here = Split-Path -Parent $MyInvocation.PSCommandPath
	
	$testPath = Resolve-Path $Path
	
	$testFiles = Get-ChildItem $testPath -Filter "*.tests.ps1" -Recurse `
		| ForEach-Object { $_.PSPath }
	
	$modulePath = Join-Path $here "PoshUnit.psm1"
	$global:testResults = @()
	
	foreach($testFile in $testFiles) {
		$testFileContents = Get-Content $testFile.Fullname
		$testFileContentsAsScriptBlock = [scriptblock]::Create($testFileContents)
		
		$testFixtureRetrievalScriptBlockString = $testFixtures[0].Value.ToString() `
			+ '; gci variable:\ | ?{$_.Value.IsPoshUnitTestFixture} "'
			+ '| %{New-Object -TypeName PSObject -Property @{Name = $_.Name; ScriptBlock = $_.Value}}'
		
		$testFixtures = @([scriptblock]::Create($testFixtureRetrievalScriptBlockString).Invoke())
		
		foreach($testFixture in $testFixtures) {
		
			$testSetupRetrievalScriptBlockString = $testFixture.ScriptBlock.ToString() `
				+ '; gci variable:\ | ?{$_.Value.IsPoshUnitTestSetup} | %{$_.Value}'
		
			$testSetup = [scriptblock]::Create($testSetupRetrievalScriptBlockString).Invoke()
			
			$testTeardownRetrievalScriptBlockString = $testFixture.ScriptBlock.ToString() `
				+ '; gci variable:\ | ?{$_.Value.IsPoshUnitTestTeardown} | %{$_.Value}'
		
			$testTeardown = [scriptblock]::Create($testTeardownRetrievalScriptBlockString).Invoke()
			
			$unitTestsRetrievalScriptBlockString = $testFixture.ScriptBlock.ToString() `
				+ '; gci variable:\ | ?{$_.Value.IsPoshUnitTest}' `
				+ ' | %{New-Object -TypeName PSObject -Property @{Name = $_.Name; ScriptBlock = $_.Value}}'
			
			$tests = @([scriptblock]::Create($unitTestsRetrievalScriptBlockString).Invoke())
			
			$privateVariablesRetrievalScriptBlockString = $testFixture.ScriptBlock.ToString() `
				+ '; gci variable:\ | ?{-not $_.Value.IsPoshUnitTest -and -not ' `
				+ '$_.Value.IsPoshUnitTestTeardown -and -not $_.Value.IsPoshUnitTestSetup}'
			
			$privateVariables = @([scriptblock]::Create($privateVariablesRetrievalScriptBlockString).Invoke())
			
			$privateMethodsDictionary = GetPrivateMethodsDictionary
		}		
	}
		
	function NewTestData {
		param(
			$testName
		)		
		New-Object -TypeName PSObject -Property @{
			Name = $testName
			Result = "NotRun"
			Output = [string]::Empty
		}
	}

	foreach($test in $tests) {
		$testData = NewTestData $test.Name		
		$testScriptBlockString = "Import-Module '$modulePath'"
		$testScriptBlockString += $testFixtures[0].Value.ToString()
		$testScriptBlockString += $test.ScriptBlock.ToString()
		$testScriptBlock = [scriptblock]::Create($testScriptBlockString)
		Try {
			$testData.Output = Invoke-Command -ScriptBlock $testScriptBlock
			$testData.Result = "Passed"
		}
		Catch [Exception] {
			$testData.Result = "Failed"
		}
		
		$global:testResults += $testData
	}

	$passedTestCases = @()
	$failedTestCases = @()	

	foreach($testCase in $global:testResults) {
		if($testCase.Result -eq "passed") {
			$passedTestCases += $testCase
		}
		else {
			$failedTestCases += $testCase		
		}
	}
	
	WriteTestResults $passedTestCases $failedTestCases
}

function WriteTestResults {
	param(
		[Object[]]$passedTestCases,
		[Object[]]$failedTestCases
	)
	$testCaseCategoryDivider = "---------------------"

	Write-Host

	Write-Host "Passed" -ForegroundColor Green -NoNewline
	Write-Host (" ({0})" -f $passedTestCases.Count) -ForegroundColor White
	Write-Host $testCaseCategoryDivider
	$passedTestCases | %{ 
		Write-Host " + " -ForegroundColor Black -BackgroundColor Green -NoNewline
		Write-Host $(" " + $_.Name)
	}

	Write-Host

	Write-Host "Failed" -ForegroundColor Red -NoNewline
	Write-Host (" ({0})" -f $failedTestCases.Count) -ForegroundColor White
	Write-Host $testCaseCategoryDivider
	$failedTestCases | %{ 
		Write-Host " + " -ForegroundColor Black -BackgroundColor Red -NoNewline
		Write-Host $(" " + $_.Name)
	}

	Write-Host
	Write-Host 'run Get-TestDetails for individual test details'
}

function GetTestFiles {

}