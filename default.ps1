properties {
    $base_dir = resolve-path .
    $build_dir = "$base_dir\builds"
    $source_dir = "$base_dir\source"
    $tools_dir = "$base_dir\tools"
    $package_dir = "$base_dir\packages"
    $framework_dir =  (Get-ProgramFiles) + "\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.0"
    $config = "release"
    $preReleaseVersion = $null
}

#tasks -------------------------------------------------------------------------------------------------------------

task default -depends compile

task clean {
    "Cleaning"
    
    "   builds/local"
    Remove-Item $build_dir\local\*.nupkg
    Remove-Item $build_dir\local\*.zip
    Remove-Item $build_dir\local\*.chm
    
    "   Glimpse.Core"
    Delete-Directory "$source_dir\Glimpse.Core\bin"
    Delete-Directory "$source_dir\Glimpse.Core\obj"
    
    "   Glimpse.Core.Net35"
    Delete-Directory "$source_dir\Glimpse.Core.Net35\bin"
    Delete-Directory "$source_dir\Glimpse.Core.Net35\obj"
    
    "   Glimpse.AspNet"
    Delete-Directory "$source_dir\Glimpse.AspNet\bin"
    Delete-Directory "$source_dir\Glimpse.AspNet\obj"

    "   Glimpse.AspNet.Net35"
    Delete-Directory "$source_dir\Glimpse.AspNet.Net35\bin"
    Delete-Directory "$source_dir\Glimpse.AspNet.Net35\obj"
    
    "   Glimpse.Mvc"
    Delete-Directory "$source_dir\Glimpse.Mvc\bin"
    Delete-Directory "$source_dir\Glimpse.Mvc\obj"

    "   Glimpse.Mvc2"
    Delete-Directory "$source_dir\Glimpse.Mvc2\bin"
    Delete-Directory "$source_dir\Glimpse.Mvc2\obj"
    
    "   Glimpse.Mvc3"
    Delete-Directory "$source_dir\Glimpse.Mvc3\bin"
    Delete-Directory "$source_dir\Glimpse.Mvc3\obj"
    
    "   Glimpse.Mvc4"
    Delete-Directory "$source_dir\Glimpse.Mvc4\bin"
    Delete-Directory "$source_dir\Glimpse.Mvc4\obj"
       
    "   Glimpse.Mvc3.MusicStore.Sample"
    Delete-Directory "$source_dir\Glimpse.Mvc3.MusicStore.Sample\bin"
    Delete-Directory "$source_dir\Glimpse.Mvc3.MusicStore.Sample\obj"
        
    "   Glimpse.Test.*"
    Delete-Directory "$source_dir\Glimpse.Test.AspNet\bin"
    Delete-Directory "$source_dir\Glimpse.Test.AspNet\obj"
    
    Delete-Directory "$source_dir\Glimpse.Test.Core\bin"
    Delete-Directory "$source_dir\Glimpse.Test.Core\obj"
    
    Delete-Directory "$source_dir\Glimpse.Test.Core.Net35\bin"
    Delete-Directory "$source_dir\Glimpse.Test.Core.net35\obj"
    
    Delete-Directory "$source_dir\Glimpse.Test.Mvc\bin"
    Delete-Directory "$source_dir\Glimpse.Test.Mvc\obj"
}

task compile -depends clean {
    "Compiling"
    "   Glimpse.All.sln"
    
    exec { msbuild $base_dir\Glimpse.All.sln /p:Configuration=$config /nologo /verbosity:minimal }
}

task docs -depends compile {
    "Documenting"
    "   Glimpse.Core.Documentation.Api"
    
    exec { msbuild $source_dir\Glimpse.Core.Documentation.Api\Glimpse.Core.Documentation.Api.shfbproj /p:Configuration=$config /nologo /verbosity:minimal }
    copy $source_dir\Glimpse.Core.Documentation.Api\Help\Glimpse.Core.Documentation.chm $source_dir\Glimpse.Core\nuspec\docs\Glimpse.Core.Documentation.chm
}

task merge -depends test {
    "Merging"

    cd $package_dir\ilmerge.*\

    "   Glimpse.Core"
    exec { & .\ilmerge.exe /targetplatform:"v4,$framework_dir" /log /out:"$source_dir\Glimpse.Core\nuspec\lib\net40\Glimpse.Core.dll" /internalize:$base_dir\ILMergeInternalize.txt "$source_dir\Glimpse.Core\bin\Release\Glimpse.Core.dll" "$source_dir\Glimpse.Core\bin\Release\Newtonsoft.Json.dll" "$source_dir\Glimpse.Core\bin\Release\Castle.Core.dll" "$source_dir\Glimpse.Core\bin\Release\NLog.dll" "$source_dir\Glimpse.Core\bin\Release\AntiXssLibrary.dll" "$source_dir\Glimpse.Core\bin\Release\Tavis.UriTemplates.dll" }
    
    "   Glimpse.Core.Net35"
    exec { & .\ilmerge.exe /log /out:"$source_dir\Glimpse.Core\nuspec\lib\net35\Glimpse.Core.dll" /internalize:$base_dir\ILMergeInternalize.txt "$source_dir\Glimpse.Core.Net35\bin\Release\Glimpse.Core.dll" "$source_dir\Glimpse.Core.Net35\bin\Release\Newtonsoft.Json.dll" "$source_dir\Glimpse.Core.Net35\bin\Release\Castle.Core.dll" "$source_dir\Glimpse.Core.Net35\bin\Release\NLog.dll" "$source_dir\Glimpse.Core.Net35\bin\Release\AntiXssLibrary.dll"  "$source_dir\Glimpse.Core.Net35\bin\Release\Tavis.UriTemplates.dll"}
    
    "   Glimpse.AspNet"
    copy $source_dir\Glimpse.AspNet\bin\Release\Glimpse.AspNet.* $source_dir\Glimpse.AspNet\nuspec\lib\net40\
    
    "   Glimpse.AspNet.Net35"
    copy $source_dir\Glimpse.AspNet.Net35\bin\Release\Glimpse.AspNet.* $source_dir\Glimpse.AspNet\nuspec\lib\net35\

    "   Glimpse.Mvc2"
    copy $source_dir\Glimpse.Mvc2\bin\Release\Glimpse.Mvc2.* $source_dir\Glimpse.Mvc2\nuspec\lib\net35\
    
    "   Glimpse.Mvc3"
    copy $source_dir\Glimpse.Mvc3\bin\Release\Glimpse.Mvc3.* $source_dir\Glimpse.Mvc3\nuspec\lib\net40\
    
    "   Glimpse.Mvc4"
    copy $source_dir\Glimpse.Mvc4\bin\Release\Glimpse.Mvc4.* $source_dir\Glimpse.Mvc4\nuspec\lib\net40\
    
}

task pack -depends merge {
    "Packing"
    
    cd $base_dir\.NuGet
    
    "   Glimpse.nuspec"
    $version = Get-AssemblyInformationalVersion $source_dir\Glimpse.Core\Properties\AssemblyInfo.cs | Update-AssemblyInformationalVersion
    exec { & .\nuget.exe pack $source_dir\Glimpse.Core\NuSpec\Glimpse.nuspec -OutputDirectory $build_dir\local -Symbols -Version $version }
    
    "   Glimpse.AspNet.nuspec"
    $version = Get-AssemblyInformationalVersion $source_dir\Glimpse.AspNet\Properties\AssemblyInfo.cs | Update-AssemblyInformationalVersion
    exec { & .\nuget.exe pack $source_dir\Glimpse.AspNet\NuSpec\Glimpse.AspNet.nuspec -OutputDirectory $build_dir\local -Symbols -Version $version }

    "   Glimpse.Mvc2.nuspec"
    $version = Get-AssemblyInformationalVersion $source_dir\Glimpse.Mvc2\Properties\AssemblyInfo.cs | Update-AssemblyInformationalVersion
    exec { & .\nuget.exe pack $source_dir\Glimpse.Mvc2\NuSpec\Glimpse.Mvc2.nuspec -OutputDirectory $build_dir\local -Symbols -Version $version }
    
    "   Glimpse.Mvc3.nuspec"
    $version = Get-AssemblyInformationalVersion $source_dir\Glimpse.Mvc3\Properties\AssemblyInfo.cs | Update-AssemblyInformationalVersion
    exec { & .\nuget.exe pack $source_dir\Glimpse.Mvc3\NuSpec\Glimpse.Mvc3.nuspec -OutputDirectory $build_dir\local -Symbols -Version $version }
    
    "   Glimpse.Mvc4.nuspec"
    $version = Get-AssemblyInformationalVersion $source_dir\Glimpse.Mvc4\Properties\AssemblyInfo.cs | Update-AssemblyInformationalVersion
    exec { & .\nuget.exe pack $source_dir\Glimpse.Mvc4\NuSpec\Glimpse.Mvc4.nuspec -OutputDirectory $build_dir\local -Symbols -Version $version }
    
    "   Glimpse.zip"
    New-Item $build_dir\local\zip\Core\net40 -Type directory -Force > $null
    New-Item $build_dir\local\zip\Core\net35 -Type directory -Force > $null
    New-Item $build_dir\local\zip\AspNet\net40 -Type directory -Force > $null
    New-Item $build_dir\local\zip\AspNet\net35 -Type directory -Force > $null
    New-Item $build_dir\local\zip\MVC2\net35 -Type directory -Force > $null
    New-Item $build_dir\local\zip\MVC3\net40 -Type directory -Force > $null
    New-Item $build_dir\local\zip\MVC4\net40 -Type directory -Force > $null

    copy $base_dir\license.txt $build_dir\local\zip
        
    copy $source_dir\Glimpse.Core\nuspec\lib\net40\Glimpse.Core.* $build_dir\local\zip\Core\net40
    copy $source_dir\Glimpse.Core\nuspec\lib\net35\Glimpse.Core.* $build_dir\local\zip\Core\net35
    
    copy $source_dir\Glimpse.AspNet\nuspec\lib\net40\Glimpse.AspNet.* $build_dir\local\zip\AspNet\net40
    copy $source_dir\Glimpse.AspNet\nuspec\lib\net35\Glimpse.AspNet.* $build_dir\local\zip\AspNet\net35
    copy $source_dir\Glimpse.AspNet\nuspec\readme.txt $build_dir\local\zip\AspNet
    
    copy $source_dir\Glimpse.Mvc2\nuspec\lib\net35\Glimpse.Mvc2.* $build_dir\local\zip\Mvc2\net35
    copy $source_dir\Glimpse.Mvc3\nuspec\lib\net40\Glimpse.Mvc3.* $build_dir\local\zip\Mvc3\net40
    copy $source_dir\Glimpse.Mvc4\nuspec\lib\net40\Glimpse.Mvc4.* $build_dir\local\zip\Mvc4\net40
        
    #TODO: Add help .CHM file
    
    Create-Zip $build_dir\local\zip $build_dir\local\Glimpse.zip
    Delete-Directory $build_dir\local\zip
}

task test -depends compile {
    "Testing"
    
    New-Item $build_dir\local\artifacts -Type directory -Force > $null
    
    cd $package_dir\xunit.runners*\tools\
    
    exec { & .\xunit.console.clr4 $base_dir\tests.xunit }
}

task push {
    "Pushing"
    "`nPush the following packages:"
    
    cd $build_dir\local
    
    $packages = Get-ChildItem * -Include *.nupkg -Exclude *.symbols.nupkg
    
    foreach($package in $packages){ 
        Write-Host "`t$package" 
    } 
     
    #Get-ChildItem -Path .\builds\local -Filter *.nupkg | FT Name
    
    $input = Read-Host "to (N)uget, (M)yget, (B)oth or (Q)uit?"

    switch ($input) 
        { 
            N {
               "Pushing to NuGet...";
               Push-Packages https://nuget.org/api/v2/
               break;
               } 
            M {
               "Pushing to MyGet...";
               Push-Packages http://www.myget.org/F/glimpsemilestone/
               break;
              } 
            B {
               "Pushing to MyGet...";
               Push-Packages http://www.myget.org/F/glimpsemilestone/
               "Pushing to NuGet...";
               Push-Packages https://nuget.org/api/v2/
               break;
              } 
            default {
              "Push aborted";
              break;
              }
        }
}

task buildjs {
}

task integrate {
    "Integration Testing"
    
    "   Clean Glimpse.Test.Integration"
    Delete-Directory "$source_dir\Glimpse.Test.Integration\bin"
    Delete-Directory "$source_dir\Glimpse.Test.Integration\obj"
    
    "   Clean Glimpse.Test.Integration.Site"
    Delete-Directory "$source_dir\Glimpse.Test.Integration.Site\bin"
    Delete-Directory "$source_dir\Glimpse.Test.Integration.Site\obj"

    "`nBuild Integration Sln"
    exec { msbuild $base_dir\Glimpse.Integration.sln /p:Configuration=$config /nologo /verbosity:minimal }
    
    "`nGlimpse must be manually installed while waiting for http://nuget.codeplex.com/workitem/2730"
    #cd $base_dir\.NuGet
    
    #nuget update -source "c:\glimpse\builds\local" -Id Glimpse.MVC;Glimpse.AspNet;Glimpse -Verbose "c:\glimpse\source\Glimpse.Test.Integration.Site\packages.config"
    #exec { & .\nuget.exe update -source $build_dir\local -id "Glimpse.MVC;Glimpse.AspNet;Glimpse" -Verbose "$source_dir\Glimpse.Test.Integration.Site\packages.config" }
    
    "`nIIS must be set up with Administrative privledges. Run: "
    "C:\Windows\System32\inetsrv\appcmd.exe add site /name:""Glimpse Integration Test Site"" /bindings:""http/*:1155:"" /physicalPath:""C:\Glimpse\source\Glimpse.Test.Integration.Site"
    "to support IIS testing"

    
    "`nEnding Cassini"
    kill -name WebDev.WebServer*

    "`nEnding IIS Express"
    kill -name iisexpress*
    
    $cassiniPath = "C:\Program Files (x86)\Common Files\microsoft shared\DevServer\11.0\WebDev.WebServer40.EXE"
    $exists = Test-Path($cassiniPath)
    if ($exists -eq $false)
    {
        $cassiniPath = "C:\Program Files\Common Files\microsoft shared\DevServer\11.0\WebDev.WebServer40.EXE"
        $exists = Test-Path($cassiniPath)
        if ($exists -eq $false)
        {
            "Using WebDev.WebServer40.EXE from PATH. Add directory containing 'WebDev.WebServer40.EXE' to PATH environment variable."
            $cassiniPath = "WebDev.WebServer40.EXE"
        }
    }
    
    $iisExpressPath = "C:\Program Files (x86)\IIS Express\iisexpress.exe"
    $exists = Test-Path($iisExpressPath)
    if ($exists -eq $false)
    {
        $iisExpressPath = "C:\Program Files\IIS Express\iisexpress.exe"
        $exists = Test-Path($iisExpressPath)
        if ($exists -eq $false)
        {
            "Using iisexpress.exe from PATH. Add directory containing 'iisexpress.exe' to PATH environment variable."
            $iisExpressPath = "iisexpress.exe"
        }
    }

    "`nStarting Cassini"
    &$cassiniPath /port:234 /path:"$source_dir\Glimpse.Test.Integration.Site"
    
    "`nStarting IIS Express"
    $iisExpressArgs = "/port:1153 /path:$source_dir\Glimpse.Test.Integration.Site /systray:true"
    start-process $iisExpressPath $iisExpressArgs 
    
    "`nRunning Tests"
    New-Item $build_dir\local\artifacts -Type directory -Force > $null
    cd $package_dir\xunit.runners*\tools\
    exec { & .\xunit.console.clr4.x86 $base_dir\integration.xunit }
    
    "`nEnding Cassini"
    kill -name WebDev.WebServer*

    "`nEnding IIS Express"
    kill -name iisexpress*
}

#functions ---------------------------------------------------------------------------------------------------------

function Push-Packages($uri)
{
  cd $build_dir\local
  $packages = Get-ChildItem * -Include *.nupkg -Exclude *.symbols.nupkg
  
  cd $base_dir\.NuGet
  
  foreach($package in $packages){
    exec { & .\nuget.exe push $package -src $uri}
  }
    
}

function Delete-Directory($path)
{
  rd $path -recurse -force -ErrorAction SilentlyContinue | out-null
}

function Get-AssemblyInformationalVersion($path)
{
    $line = Get-Content $path | where {$_.Contains("AssemblyInformationalVersion")}
    $line.Split('"')[1]
}

function Update-AssemblyInformationalVersion
{
    if ($preReleaseVersion -ne $null)
    {
        $version = ([string]$input).Split('-')[0]
        $date = Get-Date
        $parsed = $preReleaseVersion.Replace("{date}", $date.ToString("yyMMdd"))
        return "$version-$parsed"
    }
    else
    {
        return $input
    }
}

function Create-Zip($sourcePath, $destinationFile)
{
    cd $package_dir\SharpZipLib.*\lib\20\
    
    Add-Type -Path ICSharpCode.SharpZipLib.dll

    $zip = New-Object ICSharpCode.SharpZipLib.Zip.FastZip
    $zip.CreateZip("$destinationFile", "$sourcePath", $true, $null)
}

function Get-ProgramFiles
{
    #TODO: Someone please come up with a better way of detecting this - Tried http://msmvps.com/blogs/richardsiddaway/archive/2010/02/26/powershell-pack-mount-specialfolder.aspx and some enums missing
    #      This is needed because of this http://www.mattwrock.com/post/2012/02/29/What-you-should-know-about-running-ILMerge-on-Net-45-Beta-assemblies-targeting-Net-40.aspx (for machines that dont have .net 4.5 and only have 4.0)
    if (Test-Path "C:\Program Files (x86)") {
        return "C:\Program Files (x86)"
    }
    return "C:\Program Files"
}