; Inno Setup Script for Cân Heo Application
; Chạy file này bằng Inno Setup Compiler để tạo file cài đặt

#define MyAppName "Cân Heo"
#define MyAppVersion "1.0.6"
#define MyAppPublisher "Your Company Name"
#define MyAppURL "https://yourwebsite.com"
#define MyAppExeName "can_heo.exe"
#define MyAppId "{{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"

; Đường dẫn tới thư mục Release (thay đổi nếu cần)
#define SourcePath "C:\Users\APC\source\repos\Can_Heo\can_heo\build\windows\x64\runner\Release"

[Setup]
; Thông tin ứng dụng
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; HỖ TRỢ 64-BIT - Quan trọng!
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Cài đặt thư mục
DefaultDirName={autopf}\CanHeo
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Tên file output
OutputDir=Output
OutputBaseFilename=CanHeo_Setup_{#MyAppVersion}

; Nén cao
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; Yêu cầu quyền admin để cài đặt
PrivilegesRequired=admin

; Giao diện wizard
WizardStyle=modern
WizardSizePercent=120

; Icon (tạo file icon nếu có)
; SetupIconFile=icon.ico
; UninstallDisplayIcon={app}\{#MyAppExeName}

; Thông tin bổ sung
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

; License (tạo file license.txt nếu muốn hiển thị)
; LicenseFile=license.txt

[Languages]
Name: "vietnamese"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
vietnamese.BeveledLabel=Cân Heo - Phần mềm quản lý cân heo

[Tasks]
Name: "desktopicon"; Description: "Tạo biểu tượng trên Desktop"; GroupDescription: "Biểu tượng:"
Name: "quicklaunchicon"; Description: "Tạo biểu tượng trên Quick Launch"; GroupDescription: "Biểu tượng:"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Copy toàn bộ thư mục Release (chỉ các file cần thiết)
Source: "{#SourcePath}\can_heo.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; NOTE: Không sử dụng "Flags: ignoreversion" cho file DLL hệ thống

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Gỡ cài đặt {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Chạy ứng dụng sau khi cài đặt
Filename: "{app}\{#MyAppExeName}"; Description: "Chạy {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Xóa các file được tạo ra khi chạy app
Type: filesandordirs; Name: "{localappdata}\can_heo"
Type: filesandordirs; Name: "{userappdata}\can_heo"

[Code]
// Kiểm tra Visual C++ Redistributable
function VCRedistInstalled: Boolean;
var
  Version: String;
begin
  Result := RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version);
  if not Result then
    Result := RegQueryStringValue(HKLM, 'SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version);
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  
  // Cảnh báo nếu chưa cài Visual C++ Redistributable
  if not VCRedistInstalled then
  begin
    if MsgBox('Ứng dụng yêu cầu Microsoft Visual C++ Redistributable.' + #13#10 + 
              'Bạn có muốn tiếp tục cài đặt không?' + #13#10 + #13#10 +
              '(Nếu gặp lỗi khi chạy, hãy tải và cài đặt VC++ Redistributable từ Microsoft)',
              mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Có thể thêm code xử lý sau khi cài đặt
  end;
end;
