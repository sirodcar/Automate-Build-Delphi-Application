object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Delphi GitHub Builder'
  ClientHeight = 700
  ClientWidth = 920
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object lblGitUrl: TLabel
    Left = 16
    Top = 20
    Width = 59
    Height = 15
    Caption = 'GitHub URL'
  end
  object lblBaseFolder: TLabel
    Left = 16
    Top = 52
    Width = 61
    Height = 15
    Caption = 'Base Folder'
  end
  object lblRepoFolder: TLabel
    Left = 16
    Top = 84
    Width = 57
    Height = 15
    Caption = 'Repo Folder'
  end
  object lblDelphi: TLabel
    Left = 16
    Top = 116
    Width = 82
    Height = 15
    Caption = 'Installed Delphi'
  end
  object lblProjects: TLabel
    Left = 16
    Top = 148
    Width = 39
    Height = 15
    Caption = 'Project'
  end
  object lblConfig: TLabel
    Left = 16
    Top = 180
    Width = 35
    Height = 15
    Caption = 'Config'
  end
  object lblPlatform: TLabel
    Left = 220
    Top = 180
    Width = 48
    Height = 15
    Caption = 'Platform'
  end
  object lblDcuOutput: TLabel
    Left = 16
    Top = 212
    Width = 61
    Height = 15
    Caption = 'DCU Output'
  end
  object lblExeOutput: TLabel
    Left = 16
    Top = 244
    Width = 58
    Height = 15
    Caption = 'EXE Output'
  end
  object lblCurrentVersion: TLabel
    Left = 16
    Top = 276
    Width = 87
    Height = 15
    Caption = 'Current Version'
  end
  object lblNewVersion: TLabel
    Left = 16
    Top = 308
    Width = 69
    Height = 15
    Caption = 'New Version'
  end
  object lblMajor: TLabel
    Left = 120
    Top = 308
    Width = 31
    Height = 15
    Caption = 'Major'
  end
  object lblMinor: TLabel
    Left = 220
    Top = 308
    Width = 31
    Height = 15
    Caption = 'Minor'
  end
  object lblRelease: TLabel
    Left = 320
    Top = 308
    Width = 42
    Height = 15
    Caption = 'Release'
  end
  object lblBuild: TLabel
    Left = 420
    Top = 308
    Width = 29
    Height = 15
    Caption = 'Build'
  end
  object edtGitUrl: TEdit
    Left = 120
    Top = 16
    Width = 680
    Height = 23
    TabOrder = 0
  end
  object edtBaseFolder: TEdit
    Left = 120
    Top = 48
    Width = 600
    Height = 23
    TabOrder = 1
  end
  object btnBrowseBaseFolder: TButton
    Left = 730
    Top = 47
    Width = 70
    Height = 25
    Caption = 'Browse'
    TabOrder = 2
    OnClick = btnBrowseBaseFolderClick
  end
  object edtRepoFolder: TEdit
    Left = 120
    Top = 80
    Width = 600
    Height = 23
    TabOrder = 3
  end
  object btnBrowseRepoFolder: TButton
    Left = 730
    Top = 79
    Width = 70
    Height = 25
    Caption = 'Browse'
    TabOrder = 4
    OnClick = btnBrowseRepoFolderClick
  end
  object cmbDelphi: TComboBox
    Left = 120
    Top = 112
    Width = 680
    Height = 23
    Style = csDropDownList
    TabOrder = 5
  end
  object btnReloadDelphi: TButton
    Left = 810
    Top = 111
    Width = 90
    Height = 25
    Caption = 'Reload'
    TabOrder = 6
    OnClick = btnReloadDelphiClick
  end
  object cmbProjects: TComboBox
    Left = 120
    Top = 144
    Width = 680
    Height = 23
    Style = csDropDownList
    TabOrder = 7
    OnChange = cmbProjectsChange
  end
  object cmbConfig: TComboBox
    Left = 120
    Top = 176
    Width = 80
    Height = 23
    Style = csDropDownList
    TabOrder = 8
  end
  object cmbPlatform: TComboBox
    Left = 280
    Top = 176
    Width = 80
    Height = 23
    Style = csDropDownList
    TabOrder = 9
  end
  object edtDcuOutput: TEdit
    Left = 120
    Top = 208
    Width = 600
    Height = 23
    TabOrder = 10
  end
  object btnBrowseDcuOutput: TButton
    Left = 730
    Top = 207
    Width = 70
    Height = 25
    Caption = 'Browse'
    TabOrder = 11
    OnClick = btnBrowseDcuOutputClick
  end
  object edtExeOutput: TEdit
    Left = 120
    Top = 240
    Width = 600
    Height = 23
    TabOrder = 12
  end
  object btnBrowseExeOutput: TButton
    Left = 730
    Top = 239
    Width = 70
    Height = 25
    Caption = 'Browse'
    TabOrder = 13
    OnClick = btnBrowseExeOutputClick
  end
  object edtCurrentVersion: TEdit
    Left = 120
    Top = 272
    Width = 200
    Height = 23
    ReadOnly = True
    TabOrder = 14
  end
  object spnMajor: TSpinEdit
    Left = 120
    Top = 328
    Width = 80
    Height = 24
    MaxValue = 65535
    MinValue = 0
    TabOrder = 15
    Value = 1
  end
  object spnMinor: TSpinEdit
    Left = 220
    Top = 328
    Width = 80
    Height = 24
    MaxValue = 65535
    MinValue = 0
    TabOrder = 16
    Value = 0
  end
  object spnRelease: TSpinEdit
    Left = 320
    Top = 328
    Width = 80
    Height = 24
    MaxValue = 65535
    MinValue = 0
    TabOrder = 17
    Value = 0
  end
  object spnBuild: TSpinEdit
    Left = 420
    Top = 328
    Width = 80
    Height = 24
    MaxValue = 65535
    MinValue = 0
    TabOrder = 18
    Value = 0
  end
  object btnClone: TButton
    Left = 120
    Top = 372
    Width = 90
    Height = 28
    Caption = 'Clone'
    TabOrder = 19
    OnClick = btnCloneClick
  end
  object btnPull: TButton
    Left = 220
    Top = 372
    Width = 90
    Height = 28
    Caption = 'Pull'
    TabOrder = 20
    OnClick = btnPullClick
  end
  object btnScanProjects: TButton
    Left = 320
    Top = 372
    Width = 110
    Height = 28
    Caption = 'Scan Projects'
    TabOrder = 21
    OnClick = btnScanProjectsClick
  end
  object btnBuild: TButton
    Left = 440
    Top = 372
    Width = 90
    Height = 28
    Caption = 'Build'
    TabOrder = 22
    OnClick = btnBuildClick
  end
  object memLog: TMemo
    Left = 16
    Top = 420
    Width = 884
    Height = 260
    ScrollBars = ssVertical
    TabOrder = 23
  end
end