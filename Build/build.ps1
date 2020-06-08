if (!$solutionName)
    { exit -1; }

if (!$rootDir)
    { exit -1; }
    
# -----------------------------------------------------------------------------
# set some variables needed later
# -----------------------------------------------------------------------------
$outputDir = Join-Path $rootDir "Output\"
$outputDir = Resolve-Path($outputDir);
$logdir = Join-Path $outputDir "logs";
$buildDir = Join-Path $outputDir "build";
$libDir = Join-Path $buildDir "lib";
$nugetDir = Join-Path $outputDir "nuget";


$targets = Join-Path $PSScriptRoot "targets.txt";
$nuspec = [io.path]::combine($rootdir, "build", ($solutionName + ".nuspec"));
$readme = Join-Path $buildDir "readme.txt";
$nupkg = Join-Path $nugetDir ($solutionName + ".nupkg")

Write-Host "outputDir" $outputDir 
Write-Host "logdir   " $logdir
Write-Host "buildDir " $buildDir 
Write-Host "libDir   " $libDir
Write-Host "nugetDir " $nugetDir
Write-Host "readme   " $readme
Write-Host "targets  " $targets
Write-Host "nuspec   " $nuspec
Write-Host "nupkg    " $nupkg

# -----------------------------------------------------------------------------
# create the log directory or make it empty if it already exists
# -----------------------------------------------------------------------------

if(!(Test-Path -Path $logDir ))
{
    Write-Host "Creating" $logDir;
    New-Item -ItemType directory -Path $logDir | Out-Null;
}
else
{
    Write-Host "Clearing" $logDir;
    Get-ChildItem -Path $logDir -Include * | remove-Item -recurse | Out-Null
}

if(!(Test-Path -Path $buildDir ))
{
    Write-Host "Creating" $buildDir;
    New-Item -ItemType directory -Path $buildDir | Out-Null;
}

if(!(Test-Path -Path $libDir ))
{
    Write-Host "Creating" $libDir;
    New-Item -ItemType directory -Path $libDir | Out-Null;
}
else
{
    Write-Host "Clearing" $libDir;
    Get-ChildItem -Path $libDir -Include * | remove-Item -recurse | Out-Null
}

if(!(Test-Path -Path $nugetDir ))
{
    Write-Host "Creating" $nugetDir;
    New-Item -ItemType directory -Path $nugetDir | Out-Null;
}

if (!(Test-Path -Path $readme))
{
    Write-Host "Creating" $readme;
    New-Item -ItemType file -Path $readme | Out-Null;
}

foreach($line in [System.IO.File]::ReadLines($targets))
{
    if (![string]::IsNullOrWhitespace($line) -and !$line.StartsWith("#"))
    {
       $targetFramework = $line.Trim();
       
       & (join-path $PSScriptRoot buildtarget.ps1)
       if ($lastExitCode -ne 0) { exit $lastExitCode; }
       
       # TODO call tests if available
    }
}

& nuget pack $nuspec -OutputDirectory $nugetDir
if ($lastExitCode -ne 0) { exit $lastExitCode; }

# TODO put the version number in the package name
# & nuget push $nupkg xxx -src http://xxx.com/nuget/nuget
