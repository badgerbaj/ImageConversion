# Created: 2/15/2017
# Original Python Author: Dr. John Nicholson
# Last Updated: 2/15/2017
# Converted to PowerShell By: Brad Jordan

<#
    This script will look in $imageSource for $fileExtSource and convert image files
    found there using Inkscape (dependency).  Everything operates from the context of where the 
	script was executed, so place any SVG files in a child folder called $imageSource.

	Usage: 
	
	From an elevated command prompt:
	
		Default Values:
		powershell.exe -File ImageConversion.ps1

		With User Supplied Values:
		powershell.exe -File ImageConversion.ps1 -imageSource "pictures" -resultDir "draw" -inkscape "path\to\inkscape" -width 300

		With Some User Supplied, Some Default Values:
		powershell.exe -File ImageConversion.ps1 -imageSource "pictures" -width 300

	From an elevated powershell_ise.exe:
		File -> Open -> Locate ImageConversion.ps1

		Modify items in param as needed
		Click the Green arrow or Press F5

  Warning: Converting large sets of images is very CPU intensive.  I put in a decent
    amount of effort in to the way that Inkscape is executed to prevent it from massively
    slowing down the system.  I've noticed that remnants of Inkscape can still be present
    after the script finishes executing, so I recommend ending any Inkscape.exe instances 
    you find in task manager.

    For example, out of 80 image conversions, three instances of Inkscape remained on
    my last conversion.

	Second Warning: If any file path being worked with has a space in it, it could break
	  this script.  
#>

param (
	# SVG File Path
	[string]$imageSource = "images",
	
	# Where to place images
	[string]$resultDir = "results",
	
	# Path to Inkscape
	[string]$inkscape = "$($env:ProgramFiles)\INKSCAPE\inkscape.exe",
	
	# SVG width on mdpi
	[int]$width = 175
)

#--------------------------------------------------------------------------
# Initialization script (Load modules and check requirements)
$oInvocation = (Get-Variable MyInvocation).Value
$thisPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath((Split-Path $oInvocation.MyCommand.Path))
Set-Location $thisPath
#--------------------------------------------------------------------------

#region Declare Variables

# Declare file extensions
$fileExtSource = ".svg"
$fileExtDestination = ".png"

# DPI for screens and names
[hashtable]$sizes = @{
'ldpi' = 120
'mdpi' = 160
'hdpi' = 240
'xhdpi' = 320
'xxhdpi' = 480
}

#endregion Declare Variables

#region Main
# SVG files to process
if(Test-Path $inkscape)
{
    if(Test-Path $imageSource)
    { [object]$images = gci $imageSource | Where-Object { $_.Name -match ".*($($fileExtSource))" } }
    else
    { Write-Error "Image Source Path Not Found." }

    if($images)
    {
        foreach($size in $sizes.GetEnumerator())
        {
            foreach($image in $images.Name)
            {
                $outputWidth = ($size.Value / 160) * $width

                # Ensure base result path exists
                if((Test-Path $resultDir) -eq $false)
                { New-Item -Name $resultDir -ItemType Directory }

                # Ensure drawable path exists
                [string]$outputDir = "$($thisPath)\$($resultDir)\drawable-$($size.Name)"
                if((Test-Path $outputDir) -eq $false)
                { New-Item -Path $outputDir -ItemType Directory }

                # Build fully qualified path for Inkscape
                [string]$outputFile = "$($outputDir)\$($image.trim($($fileExtSource)))$($fileExtDestination)"
                [string]$inputFile = "$($thisPath)\$($imageSource)\$($image)"            

                # Build Arguments
                [hashtable]$arguments = @{
                    "ToPNG" = "--export-png=$($outputFile)"
                    "ToWidth" = "--export-width=$($outputWidth)"
                    "NoGUI" = "--without-gui"
                    "InputFile" = "$($inputFile)"
                }          

                # Convert Image
                & $inkscape $arguments.ToPNG $arguments.ToWidth $arguments.NoGUI $arguments.InputFile            
            }
        }
    }
    else
    { Write-Error "No Image Files Found With $($fileExtSource) to Convert." }
}
else
{ Write-Error "Inkscape Not Found At: $($inkscape)" }
#endregion Main
