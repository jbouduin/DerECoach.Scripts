# -----------------------------------------------------------------------------
# function CreateDir 
# -----------------------------------------------------------------------------
function CreateDir
{
    Param ([string] $newDir, [string] $inDir)
    
    if ($inDir -eq "") { $inDir = $fullProjectDirectory }
    
    $toCreate = join-path $inDir $newDir;
    
    write-host "Creating" $toCreate;
    New-Item $toCreate -itemtype directory
        
}

# -----------------------------------------------------------------------------
# set some variables needed later
# -----------------------------------------------------------------------------
$namespaceRoot = "DerECoach";
$rootDir = join-path $PSScriptRoot "..\";
$rootDir = Resolve-Path($rootDir);
$confirmCreation = "N";

# -----------------------------------------------------------------------------
# ask user for input
# -----------------------------------------------------------------------------
while ($confirmCreation.ToLower() -ne "j")
{
    $input = Read-Host -Prompt "Enter the namespace root. Enter an empty string for 'DerECoach'"
    if ($input.Trim().Trim(".") -ne "") { $namespaceRoot = $input.Trim().Trim(".") }

    $namespaceTail = "";
    while ($namespaceTail -eq "")
    {
        $input = Read-Host -Prompt "Enter the rest of the namespace"
        if ($input.Trim().Trim(".") -ne "") { $namespaceTail = $input.Trim().Trim(".") }
    }

    $projectDirectory = $namespaceRoot + "." + $namespaceTail;
    $fullProjectDirectory = join-path $rootDir $projectDirectory;
    $confirmMessage = "Create project in '" + $fullProjectDirectory + "' [J/N]"
    $confirmCreation = "a";
    while ($confirmCreation.ToLower() -ne "j" -and $confirmCreation.ToLower() -ne "n")
    { $confirmCreation = Read-Host -Prompt $confirmMessage; }
    
}

# -----------------------------------------------------------------------------
# create the directories
# -----------------------------------------------------------------------------
CreateDir $projectDirectory $rootDir
CreateDir "build";
CreateDir "output";
CreateDir "output\build";
CreateDir "output\build\lib";
CreateDir "output\logs";
CreateDir "output\nuget";
CreateDir "src";
CreateDir "src\net";
CreateDir (join-path "src\net" $projectDirectory);
CreateDir "src\netcoreapp";
CreateDir (join-path "src\netcoreapp" $projectDirectory);
CreateDir "src\netstandard";
CreateDir (join-path "src\netstandard" $projectDirectory);
CreateDir "src\shared";
CreateDir (join-path "src\shared" $projectDirectory);

# -----------------------------------------------------------------------------
# create some files
# -----------------------------------------------------------------------------
# create a nuget.spec
$buildDir = "build";
cd (join-path $rootDir $projectDirectory);
cd build
nuget spec $projectDirectory

# create the buildscript
$text = "`$solutionName = `"$projectDirectory`";";
$text | Set-Content "build.ps1"
$text = "`$rootdir = Join-Path `$PSScriptRoot "".."";";
$text | Add-Content "build.ps1"
$text = "`$rootdir = Resolve-Path `$rootdir;"
$text | Add-Content "build.ps1"
$text = "..\..\DerECoach.Scripts\build\build.ps1"
$text | Add-Content "build.ps1"

# create a git repository
cd (join-path $rootDir $projectDirectory);
git init
cd $PSScriptRoot

