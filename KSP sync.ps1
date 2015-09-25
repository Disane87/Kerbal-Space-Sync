# Edit them to fit your needs #
$syncflder = "KSPSync\"
$savefldr = $syncflder+'saves\'
$modfldr = $syncflder+'mods\'
$pluginfldr = $syncflder+'plugins\'
#write-host "$p"


# DONT CHANGE BEYOND THIS LINE!! #
$DebugPreference = "Continue"
$KSPReg = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 220200\"

Write-Host "########## KERBAL SPACE PROGRAM SYNC v0.1 #########" -ForegroundColor red -BackgroundColor white
Write-Host "# Currently it's impossible to sync all KSP data  #" -ForegroundColor red -BackgroundColor white
Write-Host "#   without manual synching all mods/saves/flags  #" -ForegroundColor red -BackgroundColor white
Write-Host "###################################################" -ForegroundColor red -BackgroundColor white
Write-Host "##           (c) 2015 by Marco Franke            ##" -ForegroundColor red -BackgroundColor white
Write-Host "##                 Idea by Nagra                 ##" -ForegroundColor red -BackgroundColor white
Write-Host "##            http://bit.ly/1gTUv1T              ##" -ForegroundColor red -BackgroundColor white

Write-Host "############ KERBAL SPACE PROGRAM SYNC ############`r`n`r`n`r`n" -ForegroundColor red -BackgroundColor white


Write-Host "Searching for Kerbal Space Program Installation..."
if((test-path $KSPReg)) { 
    $KSPfolder = (get-item $KSPReg).GetValue("InstallLocation") + '\'
    $KSPplugins = $KSPfolder+'plugins\'
    $KSPmods = $KSPfolder+'GameData\'
    $KSPsaves = $KSPfolder+'saves\'
}else{
    write-host "KSP not found."
    exit
}


Function New-SymLink ($link, $target)
{
    if (test-path -pathtype container $target)
    {
        $command = "cmd /c mklink /d"
    }
    else
    {
        $command = "cmd /c mklink"
    }

    invoke-expression "$command $link $target"
}

Function Remove-SymLink ($link)
{
    if (test-path -pathtype container $link)
    {
        $command = "cmd /c rmdir"
    }
    else
    {
        $command = "cmd /c del"
    }

    invoke-expression "$command $link"
}

function Test-ReparsePoint([string]$path) {
  $file = Get-Item $path -Force -ea 0
  return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

$jspath = "$env:AppData\Dropbox\info.json"
$json = Get-Content $jspath
if(-not (test-path $jspath)){
    write-host "DropBox not installed. Please install dropbox"
    exit
}else{
    write-host "DropBox installed: $jspath"
    $parsed = $json | ConvertFrom-Json
    foreach ($line in $parsed | Get-Member) {
        $path = $parsed.$($line.Name).path
        if ($path) { 
            #[System.Windows.Forms.MessageBox]::Show($path,"Titel",0)
            write-host "Resolved dropbox folder: $path"
      
            if (-not (test-path -path $path\$syncflder)) {  New-Item -Path $path\$syncflder -ItemType directory | write-host "Make root-directories in dropbox: $path\$syncflder" } else { write-host "Folder '$path\$syncflder' exists `r`n" }
            $fldr = @{
                    DB = @{ ModFolder = "$path\$modfldr"; SaveFolder = "$path\$savefldr"; PluginFolder = "$path\$pluginfldr" }; 
                    KSP =  @{ ModFolder = $KSPmods; SaveFolder = $KSPsaves; PluginFolder = $KSPplugins } 
            }

            foreach ($folder in $fldr.DB.GetEnumerator()) {
                #Write-Host "$($folder.Name): $($folder.Value) $(test-path -path $folder.Value)" 
                $p = $fldr.KSP.$($folder.Name)

                if (-not (test-path -path $folder.Value)) { 
                    New-Item -Path $folder.Value -ItemType directory | Out-Null
                    write-host "created sub directory: $($folder.Value)"
                }
                
                if ((test-path -path $p) -AND -not (Test-ReparsePoint($p))) { 
                    Get-ChildItem -Path $p -Recurse | Move-Item -destination $($folder.Value) | Out-Null
                    Remove-Item $fldr.KSP.$($folder.Name) -Recurse                    
                }
                
                if(-not (Test-ReparsePoint($p)))
                {
                    New-SymLink  "`"$p`"" "$($folder.Value)"
                }else
                {
                    write-host "Symbolic links already generated for $p"
                }
            }
        }
    }
}