# =============================================================================
# function targetFramework2Version: converts the target framework to the 
#          the target framework version as to be set in the project file
# Param string $framework: the Framework
# =============================================================================
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

# =============================================================================
# function getMSBuildCompilerConstants: returns the compile constants
# Param string $framework: the target Framework
# =============================================================================
function getMSBuildCompilerConstants
{
    Param ([string] $framework)
    
    switch ($framework)
    {
        #--------------------------------------------------------
        # .NET Framework
        #--------------------------------------------------------
        "net11" { $result = "NET1_1" }
        "net20" { $result = "NET2_0" } 
        "net35" { $result = "NET3_5" } 
        "net40" { $result = "NET4_0" }
        "net403" { $result = "NET4_0_3" }
        "net45" { $result = "NET4_5" }
        "net451" { $result = "NET4_5_1" }
        "net452" { $result = "NET4_5_2" }
        "net46" { $result = "NET4_6" }
        "net461" { $result = "NET4_6_1" }
        "net462" { $result = "NET4_6_2" }
 
        #--------------------------------------------------------
        # .NET-Standard
        #--------------------------------------------------------
        "netstandard1.0" { $result = "NETSTANDARD1_0" }
        "netstandard1.1" { $result = "NETSTANDARD1_1" }        
        "netstandard2.0" { $result = "NETSTANDARD2_0" }
        
        #--------------------------------------------------------
        # .NET Core-App
        #--------------------------------------------------------
        "netcoreapp1.0" { $result = "NETCOREAPP1_0" }
        "netcoreapp1.1" { $result = "NETCOREAPP1_1" }
        "netcoreapp2.0" { $result = "NETCOREAPP2_0" }
        
        default { $result = "" }
    }
    
    if ($result -eq "")
    {
       return "RELEASE" ;
    }
    
    return "RELEASE;" + $result;
}

# =============================================================================
# function writeRspFile: create the .rsp file
# param string $fileName: the full path to the .rsp file
#       string $constants: the compile constants
# =============================================================================
function writeRspFile
{
    Param ([string] $fileName, [string] $constants)
    
    try
    {
        $stream = [System.IO.StreamWriter]::new( $fileName )
        $stream.WriteLine("/m");
        $stream.WriteLine("/nologo");
        $stream.WriteLine("/p:DebugSymbols=false");
        $stream.WriteLine("/p:DebugType=none");
        $stream.WriteLine("/p:DefineDebug=false");
        $stream.WriteLine("/p:DefineTrace=false");
        $stream.WriteLine("/p:DefineConstants=""" + $constants + """");
        $stream.WriteLine("/p:configuration=""Release"""); 
        $stream.WriteLine("/p:platform=""Any CPU"""); 
        $stream.WriteLine("/p:outdir=""$targetDir""") 
        $stream.WriteLine("/t:Rebuild"); 
        $stream.WriteLine("/verbosity:quiet"); 
        $stream.WriteLine("/clp:ErrorsOnly"); 
        $stream.WriteLine("/flp:LogFile=""$buildLog""");
        
    }
    finally
    {
        $stream.close()
    }
}

# =============================================================================
# function solution2SolutionFile: converts the solution to the 
#          full path of the solutionfile
# Param string $framework: the Framework
# =============================================================================
function solution2SolutionFile
{
    Param ([string] $framework, [string] $solution)
    
    if ($framework.StartsWith("netcoreapp"))  { $result = [io.path]::combine($rootDir, "src\netcoreapp", $solution + ".sln") }
    elseif ($framework.StartsWith("netstandard"))  { $result = [io.path]::combine($rootDir, "src\netstandard", $solution + ".sln")}
    else { $result = [io.path]::combine($rootDir, "src\net", $solution + ".sln")}
    
    return $result;
}

# =============================================================================
# function setTargetFrameworkForProjects
# param string $solution
#       string $framework
# =============================================================================
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

# =============================================================================
# function setTargetFrameworkForNetProject
# =============================================================================
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

# =============================================================================
# function setTargetFrameworkForNetProject
# =============================================================================
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

# =============================================================================
# MAIN BLOCK
# =============================================================================

# -----------------------------------------------------------------------------
# set some variables needed later
# -----------------------------------------------------------------------------
$targetDir = Join-Path $libDir $targetFramework;
$targetFrameworkVersion = targetFramework2Version $targetFramework;
$solutionFileName = solution2SolutionFile $targetFramework $solutionName;
$buildLog = $trg = [io.path]::combine($logDir, "build." + $targetFramework + ".log");
$rspFileName = [io.path]::combine( $rootDir, "src", "Directory.Build.rsp");

Write-Host "Building" $solutionFileName 
Write-Host "for Target" $targetFramework "- FrameworkVersion" $targetFrameworkVersion

# -----------------------------------------------------------------------------
# create the lib directory or make it empty if it already exists
# -----------------------------------------------------------------------------
if(!(Test-Path -Path $targetDir ))
{
    Write-Host "Creating" $targetDir;
    New-Item -ItemType directory -Path $targetDir | Out-Null;
}
else
{
    Write-Host "Clearing" $targetDir;
    Get-ChildItem -Path $targetDir -Include * | remove-Item -recurse | Out-Null
}

# -----------------------------------------------------------------------------
# build for the target framework
# -----------------------------------------------------------------------------
setTargetFrameworkForProjects $solutionFileName $targetFrameworkVersion
$compileConstants = getMSBuildCompilerConstants $targetFramework
writeRspFile $rspFileName $compileConstants

& nuget restore $solutionFileName 
& dotnet msbuild $solutionFileName 

if ($lastExitCode -ne 0)
{
    Write-Host "Build failed for" $solutionFileName $targetFrameworkVersion ", opening build log file";
    Invoke-Item $buildLog;    
    exit $lastExitCode;
}  
 
Write-Host "===============================================================================";
Write-Host 
exit 0;


