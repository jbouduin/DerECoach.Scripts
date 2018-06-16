# -----------------------------------------------------------------------------
# function targetFramework2Version: converts the target framework to the 
#          the target framework version as to be set in the project file
# Param string $framework: the Framework
# -----------------------------------------------------------------------------
function targetFramework2Version
{
    Param ([string] $framework)
    switch ($framework)
    {
        #########################################################
        # .NET Framework
        #########################################################
        "net11" { $result = "v1.1" }
        "net20" { $result = "v2.0" } 
        "net35" { $result = "v3.5" } 
        "net40" { $result = "v4.0" }
        "net403" { $result = "v4.0.3" }
        "net45" { $result = "v4.5" }
        "net451" { $result = "v4.5.1" }
        "net452" { $result = "v4.5.2" }
        "net46" { $result = "v4.6.0" }
        "net461" { $result = "v4.6.1" }
        "net462" { $result = "v4.6.2" }
 
        #########################################################
        # .NET-Standard & .NET Core-App
        #########################################################
        default { $result = $framework }
    }
    
    return $result;
}

# -----------------------------------------------------------------------------
# function solution2SolutionFile: converts the solution to the 
#          full path of the solutionfile
# Param string $framework: the Framework
# -----------------------------------------------------------------------------
function solution2SolutionFile
{
    Param ([string] $framework, [string] $solution)
    if ($framework.StartsWith("netcoreapp"))  { $result = [io.path]::combine($rootDir, "src\netcoreapp", $solution + ".sln") }
    elseif ($framework.StartsWith("netstandard"))  { $result = [io.path]::combine($rootDir, "src\netstandard", $solution + ".sln")}
    else { $result = [io.path]::combine($rootDir, "src\net", $solution + ".sln")}
    
    return $result;
}

# -----------------------------------------------------------------------------
# function setTargetFrameworkForProjects
# -----------------------------------------------------------------------------
function setTargetFrameworkForProjects
{
    Param ([string] $solution, [string] $framework)
    foreach($line in [System.IO.File]::ReadLines($solution))
    {
        if (![string]::IsNullOrWhitespace($line) -and $line.StartsWith("Project("))
        {
            $projectFileName = $line.Split(",")[1].Trim().Replace("""","");
            if ($framework.StartsWith("netcoreapp"))  
            { 
                $fullProjectFileName = [io.path]::combine($rootDir, "src\netcoreapp", $projectFileName); 
                setTargetFrameworkForOtherProject $fullProjectFileName $framework;
            }
            elseif ($framework.StartsWith("netstandard"))
            { 
                $fullProjectFileName = [io.path]::combine($rootDir, "src\netstandard", $projectFileName)
                setTargetFrameworkForOtherProject $fullProjectFileName $framework;
            }
            else 
            { 
                $fullProjectFileName = [io.path]::combine($rootDir, "src\net", $projectFileName);
                setTargetFrameworkForNetProject $fullProjectFileName $framework;
            }
        }
    }
}

# -----------------------------------------------------------------------------
# function setTargetFrameworkForNetProject
# -----------------------------------------------------------------------------
function setTargetFrameworkForNetProject
{
    Param ([string] $fullProjectFileName, [string] $framework)
        
    Write-Host "setting" $framework "in" $fullProjectFileName;
    $results = 0
    $ns = @{msb = 'http://schemas.microsoft.com/developer/msbuild/2003'}
    $xml = [xml](Get-Content $fullProjectFileName)
    $xml | 
       Select-Xml "//msb:TargetFrameworkVersion" -Namespace $ns | 
       Foreach { 
            $_.Node.set_InnerText($framework)
            $results = 1
       };
    
    if($results -eq 1)
    {
        $xml.Save($fullProjectFileName)
    }   
    
}

# -----------------------------------------------------------------------------
# function setTargetFrameworkForNetProject
# -----------------------------------------------------------------------------
function setTargetFrameworkForOtherProject
{
    Param ([string] $fullProjectFileName, [string] $framework)
    Write-Host "setting" $framework "in" $fullProjectFileName;
    $results = 0
    $ns = @{msb = ''}
    $xml = [xml](Get-Content $fullProjectFileName)
    $xml | 
       Select-Xml "//msb:TargetFramework" -Namespace $ns | 
       Foreach { 
            $_.Node.set_InnerText($framework)
            $results = 1
       };
    
    if($results -eq 1)
    {
        $xml.Save($fullProjectFileName)
    }
}

# -----------------------------------------------------------------------------
# set some variables needed later
# -----------------------------------------------------------------------------
$targetDir = Join-Path $libDir $targetFramework;
$targetFrameworkVersion = targetFramework2Version $targetFramework;
$solutionFileName = solution2SolutionFile $targetFramework $solutionName;
$buildLog = $trg = [io.path]::combine($logDir, "build." + $targetFramework + ".log");

Write-Host "Building" $solutionFileName 
Write-Host "for Target" $targetFramework "- FrameworkVersion" $targetFrameworkVersion
Write-Host $buildLog;


# -----------------------------------------------------------------------------
# create the lib directory or make it empty if it already exists
# -----------------------------------------------------------------------------
if(!(Test-Path -Path $targetDir ))
{
    Write-Host "Creating" $targetDir;
    New-Item -ItemType directory -Path $targetDir;
}
else
{
    Write-Host "Clearing" $targetDir;
    Get-ChildItem -Path $targetDir -Include * | remove-Item -recurse 
}

# -----------------------------------------------------------------------------
# build for the target framework
# -----------------------------------------------------------------------------
setTargetFrameworkForProjects $solutionFileName $targetFrameworkVersion

& nuget restore $solutionFileName 
# & dotnet msbuild $solutionFileName /m /p:configuration="Release" /p:outdir="$targetDir" /p:platform="Any CPU" /toolsversion:4.0 /t:Rebuild /verbosity:quiet  /clp:ErrorsOnly /flp:LogFile="$buildLog"
& dotnet msbuild $solutionFileName /m /p:configuration="Release" /p:outdir="$targetDir" /p:platform="Any CPU" /t:Rebuild /verbosity:quiet  /clp:ErrorsOnly /flp:LogFile="$buildLog"

if ($lastExitCode -ne 0)
{
    Write-Host "Build failed for" $solutionFileName $targetFrameworkVersion ", opening build log file";
    Invoke-Item $buildLog;    
    exit $lastExitCode;
}  
 
Write-Host "===============================================================================";
Write-Host 
exit 0;


