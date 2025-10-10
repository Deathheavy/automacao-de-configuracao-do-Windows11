@echo off
cls
title Instalador de Apps via Winget e Otimizacoes do Windows
color 0A

echo AVISO
echo Esse script altera configuracoes do sistema, registros e servicos
echo Use com cautela e verifique o readme no Github.

echo =========================================
echo Verificando se o script esta rodando como Administrador
echo =========================================
>nul 2>&1 net session || (
    echo Este script precisa ser executado como Administrador.
    echo Tentando reiniciar com privilegios elevados...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo =========================================
echo Backup do Registro
echo =========================================
set "BACKUPDIR=%~dp0"
set "BACKUPDATE=%date:~-4%-%date:~3,2%-%date:~0,2%"  :: AAAA-MM-DD
set "HKLM_BACKUP=%BACKUPDIR%HKLM_SOFTWARE_backup_%BACKUPDATE%.reg"
set "HKCU_BACKUP=%BACKUPDIR%HKCU_SOFTWARE_backup_%BACKUPDATE%.reg"

echo Criando backup do registro em:
echo  %HKLM_BACKUP%
echo  %HKCU_BACKUP%

:: Backup HKLM\SOFTWARE
reg export HKLM\SOFTWARE "%HKLM_BACKUP%" /y >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao exportar HKLM\SOFTWARE
) else (
    echo [OK] Backup de HKLM\SOFTWARE concluido
)

:: Backup HKCU\SOFTWARE
reg export HKCU\SOFTWARE "%HKCU_BACKUP%" /y >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao exportar HKCU\SOFTWARE
) else (
    echo [OK] Backup de HKCU\SOFTWARE concluido
)

echo =========================================
echo Verificando se o Winget esta instalado
echo =========================================
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo Winget nao foi encontrado no sistema.
    echo Instale o App Installer da Microsoft Store e tente novamente.
    pause
    exit /b
)

:: Manifest
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    winget settings --enable LocalManifest >nul 2>&1
)

echo =========================================
echo Instalando aplicativos com Winget...
echo =========================================
set "apps=Valve.Steam Discord.Discord RARLab.WinRAR VideoLAN.VLC Brave.Brave qBittorrent.qBittorrent"

for %%i in (%apps%) do (
    echo Instalando %%i ...
    winget install --id=%%i -e --silent --accept-package-agreements --accept-source-agreements
    echo -----------------------------------------
)
color 0A
echo =========================================
echo Removendo aplicativos desnecessarios...
echo =========================================
set "bloat=Microsoft.BingNews Microsoft.BingWeather Microsoft.GetHelp Microsoft.MicrosoftOfficeHub Microsoft.MicrosoftSolitaireCollection Microsoft.MicrosoftStickyNotes Microsoft.People Microsoft.PowerAutomateDesktop Microsoft.SkypeApp Microsoft.Todos Microsoft.WindowsAlarms Microsoft.WindowsCamera Microsoft.windowscommunicationsapps Microsoft.WindowsFeedbackHub Microsoft.WindowsMaps Microsoft.XboxGameOverlay Microsoft.XboxGamingOverlay Microsoft.XboxSpeechToTextOverlay Microsoft.ZuneMusic Microsoft.ZuneVideo Microsoft.Clipchamp Microsoft.YourPhone Microsoft.Microsoft3DViewer Microsoft.Paint3D Microsoft.MixedReality.Portal MicrosoftTeams"

for %%b in (%bloat%) do (
    powershell -Command "Get-AppxPackage -AllUsers %%b | Remove-AppxPackage -ErrorAction SilentlyContinue"
    powershell -Command "Get-AppxProvisionedPackage -Online | Where-Object PackageName -like '*%%b*' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue"
)

echo =========================================
echo Ajustando configuracoes de privacidade...
echo =========================================

:: Desativar ID de publicidade
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0"

:: Desativar sugestões de conteúdo no menu iniciar
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0"

:: Desativar telemetria (nível mínimo permitido)
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -Value 0"
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0"

:: Desativar localização
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Value 'Deny'"
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Value 'Deny'"

:: Desativar histórico de atividades
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0"
powershell -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0"

:: Desativar sugestões na tela de bloqueio
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenEnabled' -Value 0"
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenOverlayEnabled' -Value 0"

:: Desativar sincronização com a conta Microsoft
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync' -Name 'Enabled' -Value 0"

:: Desativar tarefas agendadas de telemetria
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable
schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable

:: Desativar Windows Spotlight (tela de bloqueio)
reg add "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlight" /t REG_DWORD /d 1 /f

:: Desativar "Obtenha dicas, truques e sugestões ao usar o Windows"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f

:: Desativar anúncios no Explorador de Arquivos
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f

:: Desativar animações do Windows
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d 0 /f

:: Desativar transparência no menu iniciar e barra de tarefas
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f

:: Desativar histórico da Área de Transferência
reg add "HKCU\Software\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d 0 /f

:: Desativar notificações de sugestão do Windows
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d 0 /f

echo =========================================
echo Desativando servicos desnecessarios...
echo =========================================

:: Lista de serviços a desativar (seguro para maioria dos PCs domésticos)
set "services=DiagTrack RetailDemo DiagnosticPolicyService SysMain Fax MapsBroker WSearch WMPNetworkSvc SCardSvr PrintSpooler Spooler RemoteRegistry RemoteAccess RemoteDesktopServices SharedAccess WindowsInsiderService TabletInputService bthserv BTAGService PhoneSvc WbioSrvc BcastDVRUserService lfsvc"

for %%s in (%services%) do (
    echo Desativando o servico %%s ...
    sc stop %%s >nul 2>&1 || echo Servico %%s ja esta parado.
    sc config %%s start= disabled >nul 2>&1
    echo -----------------------------------------
)

:: Desativar máquinas virtuais do Hyper V
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HvHost" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmickvpexchange" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicguestinterface" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicshutdown" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicheartbeat" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicvmsession" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicrdv" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmictimesync" /v "Start" /t REG_DWORD /d 4 /f

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicvss" /v "Start" /t REG_DWORD /d 4 /f

:: Audio VR
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\QWAVE" /v "Start" /t REG_DWORD /d 4 /f

color 0A
echo =========================================
echo Desligando aceleracao do mouse e configurando a sensibilidade do mouse...
echo =========================================
REG ADD "HKCU\Control Panel\Mouse" /v MouseSpeed /d 0 /t REG_SZ /f
REG ADD "HKCU\Control Panel\Mouse" /v MouseThreshold1 /d 0 /t REG_SZ /f
REG ADD "HKCU\Control Panel\Mouse" /v MouseThreshold2 /d 0 /t REG_SZ /f
REG ADD "HKCU\Control Panel\Mouse" /v MouseSensitivity /d 10 /t REG_SZ /f

echo =========================================
echo Desativando recursos indesejados do Brave...
echo =========================================

:: Desativar Brave Rewards
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v "BraveRewardsDisabled" /t REG_DWORD /d 1 /f

:: Desativar Brave Wallet
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v "BraveWalletDisabled" /t REG_DWORD /d 1 /f

:: Desativar Brave VPN
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v "BraveVPNDisabled" /t REG_DWORD /d 1 /f

:: Desativar Leo AI Chat
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v "BraveAIChatEnabled" /t REG_DWORD /d 0 /f

echo =========================================
echo Desativando CrossDevice Resume...
echo =========================================

:: Bloquear retomada de atividades entre dispositivos
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" /v "IsResumeAllowed" /t REG_DWORD /d 0 /f

echo =========================================
echo Remover Home e Galeria do explorer...
echo =========================================

REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f

:: Definir o comportamento do Explorador de Arquivos (Abrir no "Este Computador")
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f

echo =========================================
echo Aplicando tweak do menu de contexto do Windows 11...
echo =========================================

:: Criar chave do registro para menu de contexto clássico
powershell -Command "New-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Name 'InprocServer32' -Force -Value ''"


echo =========================================
echo Desativando sugestoes da pesquisa do Windows (Bing / online)...
echo =========================================

:: Criar chave se nao existir e desativar sugestoes da caixa de pesquisa
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f

:: Reiniciar o Explorer para aplicar a mudanca imediatamente
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

echo =========================================
echo Configurando DNS no adaptador de rede ativo...
echo =========================================

setlocal enabledelayedexpansion
set "adapter="

:: Obter o nome do adaptador ativo usando PowerShell
for /f "tokens=*" %%A in ('powershell -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.LinkSpeed -ne '0 Bps' -and $_.Name -notlike '*Loopback*' } | Select-Object -ExpandProperty Name"') do (
    set "adapter=%%A"
)

if defined adapter (
    set "adapter=!adapter!"
) else (
    echo Nenhum adaptador conectado ou ativo encontrado.
    goto :end_dns_config
)

echo Adaptador detectado: "!adapter!"

:: Configurar DNS (Cloudflare)
netsh interface ip set dns name="!adapter!" static 1.1.1.1
netsh interface ip add dns name="!adapter!" 1.0.0.1 index=2

echo DNS configurado com sucesso no adaptador "!adapter!".

:: Configurar DNS IPv6 (Cloudflare)
netsh interface ipv6 set dns name="!adapter!" static 2606:4700:4700::1111
netsh interface ipv6 add dns name="!adapter!" 2606:4700:4700::1001 index=2

echo DNS IPv6 configurado com sucesso no adaptador "!adapter!".

:: Limpar cache DNS e reiniciar o serviço DNS Client
ipconfig /flushdns >nul 2>&1
net stop Dnscache >nul 2>&1
net start Dnscache >nul 2>&1

:end_dns_config
endlocal

echo =========================================
echo Identificando a fabricante da GPU e abrindo o site dos drivers...
echo =========================================

setlocal

:: Obter a fabricante da GPU via PowerShell
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name"`) do (
    set "GPU=%%G"
    goto :FoundGPU
)

:FoundGPU
echo GPU detectada: %GPU%

echo %GPU% | findstr /I "NVIDIA" >nul
if %errorlevel%==0 (
    start https://www.nvidia.com/pt-br/drivers/
    goto :continue
)

echo %GPU% | findstr /I "AMD" >nul
if %errorlevel%==0 (
    start https://www.amd.com/pt/support/download/drivers.html
    goto :continue
)

echo %GPU% | findstr /I "Intel" >nul
if %errorlevel%==0 (
    start https://www.intel.com.br/content/www/br/pt/download-center/
    goto :continue
)

:continue
endlocal

echo =========================================
echo Abrindo a configuracao de desempenho do Windows...
echo =========================================
echo O site de drivers da sua GPU foi aberto em seu navegador e a aba de opcoes de desempenho do Windows foi iniciada
echo Faca o download do driver atualizado da sua GPU.
echo E nas Opcoes de Desempenho marque a opcao Customizado e depois marque
echo .
echo .
echo Mostrar miniaturas em vez de icones
echo Mostrar retangulo de selecao translucido
echo Bordas suaves das fontes da tela
echo Use sombras projetadas para rotulos de icones na area de trabalho
echo .
echo .
echo Apos configurar e aplicar as configuracoes na aba de desempenho
echo clique em ok nas opcoes de desempenho para fechar a janela

SystemPropertiesPerformance.exe

echo =========================================
echo Todas as operacoes foram concluidas.
echo Reinicie o computador para aplicar todas as configuracoes.
echo =========================================
pause














