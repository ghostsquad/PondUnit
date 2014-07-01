$myTestFixture = New-TestFixture {
	
	$foo = "hello world"

	$setup = New-TestSetup {		
		Write-Output "Setup"
	}
	
	$teardown = New-TestTeardown {
		Write-Output "Teardown"
	}
	
	$testFail = New-Test {
		throw "omg! wtf happened?"
	}
	
	$test1 = New-Test {
		Write-Output "Test1!"
	}
	
	$testFoo = New-Test {
		Write-Output "value of foo: $foo"
	}
}

function GetPrivateMethodsDictionary {
	$privateMethodsDictionary = New-Object 'system.collections.generic.dictionary[[string],[ScriptBlock]]'
	$privateMethods = @([scriptblock]::Create($testFixtures[0].Value.ToString() + '; gci function:\').Invoke())
	$privateMethods | %{
		$privateMethodsDictionary.Add($_.Name, $_.ScriptBlock)
	}
	
	return $privateMethodsDictionary
}

$testFixtures = gci variable:\ | ?{$_.Value.IsPoshUnitTestFixture} 
$setup = [scriptblock]::Create($testFixtures[0].Value.ToString() + '; gci variable:\ | ?{$_.Value.IsPoshUnitTestSetup} | %{$_.Value.Invoke()}')
$teardown = [scriptblock]::Create($testFixtures[0].Value.ToString() + '; gci variable:\ | ?{$_.Value.IsPoshUnitTestTeardown} | %{$_.Value.Invoke()}')
$tests = @([scriptblock]::Create($testFixtures[0].Value.ToString() + '; gci variable:\ | ?{$_.Value.IsPoshUnitTest} | %{New-Object -TypeName PSObject -Property @{Name = $_.Name; ScriptBlock = $_.Value}}').Invoke())

$privateVariables = @([scriptblock]::Create($testFixtures[0].Value.ToString() + '; gci variable:\ | ?{-not $_.Value.IsPoshUnitTest -and -not $_.Value.IsPoshUnitTestTeardown -and -not $_.Value.IsPoshUnitTestSetup}').Invoke())
$privateMethodsDictionary = GetPrivateMethodsDictionary

function runTests {
	$testResults = @()
	
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
		
		$testResults += $testData
	}
	
	Write-Output $testResults
}

$global:testResults = @(runTests)
$passedTestCases = @()
$failedTestCases = @()
$testCaseDivider = "---------------------"

foreach($testCase in $global:testResults) {
	if($testCase.Result -eq "passed") {
		$passedTestCases += $testCase
	}
	else {
		$failedTestCases += $testCase		
	}
}

Write-Host

Write-Host "Passed" -ForegroundColor Green -NoNewline
Write-Host (" ({0})" -f $passedTestCases.Count) -ForegroundColor White
Write-Host $testCaseDivider
$passedTestCases | %{ 
	Write-Host " + " -ForegroundColor Black -BackgroundColor Green -NoNewline
	Write-Host $(" " + $_.Name)
}

Write-Host

Write-Host "Failed" -ForegroundColor Red -NoNewline
Write-Host (" ({0})" -f $failedTestCases.Count) -ForegroundColor White
Write-Host $testCaseDivider
$failedTestCases | %{ 
	Write-Host " + " -ForegroundColor Black -BackgroundColor Red -NoNewline
	Write-Host $(" " + $_.Name)
}

Write-Host
Write-Host 'run Get-TestDetails for individual test details'