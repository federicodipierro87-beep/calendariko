# Script per creare un pacchetto MSI di Calendariko
# Richiede WiX Toolset v3.11+ installato

param(
    [string]$Version = "1.0.0",
    [string]$OutputPath = ".\dist"
)

$ErrorActionPreference = "Stop"

Write-Host "Creazione pacchetto MSI Calendariko v$Version..." -ForegroundColor Cyan

# Verifica WiX Toolset
try {
    $wixPath = Get-Command "candle.exe" -ErrorAction Stop
    Write-Host "✓ WiX Toolset trovato: $($wixPath.Source)" -ForegroundColor Green
} catch {
    Write-Host "✗ WiX Toolset non trovato!" -ForegroundColor Red
    Write-Host "Installare WiX Toolset da: https://wixtoolset.org/releases/" -ForegroundColor Yellow
    exit 1
}

# Crea directory output
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force
}

# Genera file WiX
$wixContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
    <Product Id="*" 
             Name="Calendariko" 
             Language="1040" 
             Version="$Version" 
             Manufacturer="Calendariko Team" 
             UpgradeCode="12345678-1234-1234-1234-123456789012">
        
        <Package InstallerVersion="200" 
                 Compressed="yes" 
                 InstallScope="perMachine" 
                 Description="Sistema di gestione calendario per band e agenzie" />

        <MajorUpgrade DowngradeErrorMessage="Una versione più recente di Calendariko è già installata." />
        
        <MediaTemplate EmbedCab="yes" />

        <!-- Icona dell'installer -->
        <Icon Id="CalendarikoIcon" SourceFile="assets\icon.ico" />
        <Property Id="ARPPRODUCTICON" Value="CalendarikoIcon" />

        <!-- Cartella di installazione -->
        <Directory Id="TARGETDIR" Name="SourceDir">
            <Directory Id="ProgramFilesFolder">
                <Directory Id="INSTALLFOLDER" Name="Calendariko" />
            </Directory>
            <Directory Id="ProgramMenuFolder">
                <Directory Id="ApplicationProgramsFolder" Name="Calendariko" />
            </Directory>
            <Directory Id="DesktopFolder" Name="Desktop" />
        </Directory>

        <!-- Componenti dell'applicazione -->
        <ComponentGroup Id="CalendarikoComponents" Directory="INSTALLFOLDER">
            
            <!-- Script di installazione -->
            <Component Id="InstallerScript" Guid="*">
                <File Id="InstallScript" 
                      Source="Install-Calendariko.bat" 
                      KeyPath="yes" />
            </Component>

            <!-- Script PowerShell -->
            <Component Id="PowerShellScript" Guid="*">
                <File Id="InstallPS1" 
                      Source="scripts\install.ps1" 
                      KeyPath="yes" />
            </Component>

            <!-- File dell'applicazione -->
            <Component Id="AppFiles" Guid="*">
                <File Id="PackageJson" 
                      Source="..\package.json" 
                      KeyPath="yes" />
                <File Id="NextConfig" 
                      Source="..\next.config.mjs" />
                <File Id="TailwindConfig" 
                      Source="..\tailwind.config.ts" />
                <File Id="TSConfig" 
                      Source="..\tsconfig.json" />
                <File Id="PostCSSConfig" 
                      Source="..\postcss.config.mjs" />
                <File Id="ESLintConfig" 
                      Source="..\.eslintrc.json" />
                <File Id="GitIgnore" 
                      Source="..\.gitignore" />
                <File Id="ReadMe" 
                      Source="..\README.md" />
            </Component>

            <!-- Directory src -->
            <Component Id="SrcFiles" Guid="*">
                <File Id="SrcDummy" 
                      Source="..\src\app\page.tsx" 
                      KeyPath="yes" />
            </Component>

        </ComponentGroup>

        <!-- Collegamento menu Start -->
        <Component Id="StartMenuShortcut" 
                   Directory="ApplicationProgramsFolder" 
                   Guid="*">
            <Shortcut Id="ApplicationStartMenuShortcut"
                      Name="Calendariko"
                      Description="Sistema di gestione calendario per band"
                      Target="[INSTALLFOLDER]Install-Calendariko.bat"
                      WorkingDirectory="INSTALLFOLDER"
                      Icon="CalendarikoIcon" />
            <RemoveFolder Id="ApplicationProgramsFolder" On="uninstall" />
            <RegistryValue Root="HKCU" 
                           Key="Software\Calendariko\Installed" 
                           Name="StartMenu" 
                           Type="integer" 
                           Value="1" 
                           KeyPath="yes" />
        </Component>

        <!-- Collegamento Desktop -->
        <Component Id="DesktopShortcut" 
                   Directory="DesktopFolder" 
                   Guid="*">
            <Shortcut Id="ApplicationDesktopShortcut"
                      Name="Installa Calendariko"
                      Description="Sistema di gestione calendario per band"
                      Target="[INSTALLFOLDER]Install-Calendariko.bat"
                      WorkingDirectory="INSTALLFOLDER"
                      Icon="CalendarikoIcon" />
            <RegistryValue Root="HKCU" 
                           Key="Software\Calendariko\Installed" 
                           Name="Desktop" 
                           Type="integer" 
                           Value="1" 
                           KeyPath="yes" />
        </Component>

        <!-- Azione personalizzata per eseguire l'installer -->
        <CustomAction Id="RunInstaller" 
                      Directory="INSTALLFOLDER" 
                      ExeCommand="Install-Calendariko.bat"
                      Execute="deferred"
                      Impersonate="no"
                      Return="ignore" />

        <!-- Sequenza di installazione -->
        <InstallExecuteSequence>
            <Custom Action="RunInstaller" After="InstallFiles">
                <![CDATA[NOT Installed]]>
            </Custom>
        </InstallExecuteSequence>

        <!-- Feature principale -->
        <Feature Id="MainFeature" Title="Calendariko" Level="1">
            <ComponentGroupRef Id="CalendarikoComponents" />
            <ComponentRef Id="StartMenuShortcut" />
            <ComponentRef Id="DesktopShortcut" />
        </Feature>

        <!-- UI semplificata -->
        <UI>
            <UIRef Id="WixUI_Minimal" />
            <Publish Dialog="ExitDialog"
                     Control="Finish" 
                     Event="DoAction" 
                     Value="LaunchApplication">WIXUI_EXITDIALOGOPTIONALCHECKBOX = 1 and NOT Installed</Publish>
        </UI>

        <!-- Proprietà UI -->
        <Property Id="WIXUI_EXITDIALOGOPTIONALCHECKBOXTEXT" 
                  Value="Esegui l'installazione di Calendariko ora" />

        <!-- Azione per lanciare l'applicazione dopo l'installazione -->
        <Property Id="WixShellExecTarget" Value="[INSTALLFOLDER]Install-Calendariko.bat" />
        <CustomAction Id="LaunchApplication"
                      BinaryKey="WixCA"
                      DllEntry="WixShellExec"
                      Impersonate="yes" />

    </Product>
</Wix>
"@

$wixFile = "Calendariko.wxs"
$wixContent | Out-File -FilePath $wixFile -Encoding UTF8

Write-Host "✓ File WiX generato: $wixFile" -ForegroundColor Green

# Compila con Candle
Write-Host "Compilazione con candle.exe..." -ForegroundColor Yellow
try {
    & candle.exe $wixFile -out "$OutputPath\Calendariko.wixobj"
    Write-Host "✓ Compilazione candle completata" -ForegroundColor Green
} catch {
    Write-Host "✗ Errore durante candle: $_" -ForegroundColor Red
    exit 1
}

# Linka con Light
Write-Host "Linking con light.exe..." -ForegroundColor Yellow
try {
    & light.exe "$OutputPath\Calendariko.wixobj" -out "$OutputPath\Calendariko-v$Version.msi" -ext WixUIExtension
    Write-Host "✓ Linking completato" -ForegroundColor Green
} catch {
    Write-Host "✗ Errore durante light: $_" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item $wixFile -ErrorAction SilentlyContinue
Remove-Item "$OutputPath\Calendariko.wixobj" -ErrorAction SilentlyContinue

$msiPath = Resolve-Path "$OutputPath\Calendariko-v$Version.msi"

Write-Host "" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host "    PACCHETTO MSI CREATO CON SUCCESSO!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host "File: $msiPath" -ForegroundColor White
Write-Host "Dimensione: $([math]::Round((Get-Item $msiPath).Length / 1MB, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "Per installare:" -ForegroundColor Yellow
Write-Host "  1. Fare doppio clic sul file .msi" -ForegroundColor White
Write-Host "  2. Seguire la procedura guidata" -ForegroundColor White
Write-Host "  3. Selezionare 'Esegui installazione' al termine" -ForegroundColor White
Write-Host ""
Write-Host "Il pacchetto MSI installerà i file e poi eseguirà" -ForegroundColor Cyan
Write-Host "automaticamente l'installazione completa di Calendariko." -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Green