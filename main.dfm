object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderWidth = 12
  Caption = 'Duplikachu - matthieulaurent.fr'
  ClientHeight = 591
  ClientWidth = 1006
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter: TSplitter
    Left = 465
    Top = 0
    Width = 12
    Height = 569
    ExplicitLeft = 401
  end
  object LVFile: TListView
    Left = 0
    Top = 0
    Width = 465
    Height = 569
    Align = alLeft
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Columns = <
      item
        Caption = 'Nom'
        Width = 200
      end
      item
        Alignment = taRightJustify
        Caption = 'Taille'
        Width = 90
      end
      item
        Caption = 'Type'
        Width = 80
      end
      item
        Alignment = taRightJustify
        Caption = 'Occurence'
        Width = 70
      end>
    DoubleBuffered = True
    ReadOnly = True
    RowSelect = True
    ParentDoubleBuffered = False
    SmallImages = ImageList
    SortType = stData
    TabOrder = 0
    ViewStyle = vsReport
    OnColumnClick = LVFileColumnClick
    OnCompare = LVFileCompare
    OnDblClick = LVFileDblClick
    OnSelectItem = LVFileSelectItem
  end
  object SBar: TStatusBar
    Left = 0
    Top = 569
    Width = 1006
    Height = 22
    Panels = <
      item
        Alignment = taRightJustify
        Width = 180
      end
      item
        Alignment = taRightJustify
        Width = 200
      end
      item
        Width = 500
      end>
  end
  object LVFolder: TListView
    Left = 477
    Top = 0
    Width = 529
    Height = 569
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Columns = <
      item
        AutoSize = True
        Caption = 'R'#233'plique'
      end>
    DoubleBuffered = True
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    ParentDoubleBuffered = False
    SmallImages = ImageList
    SortType = stData
    TabOrder = 2
    ViewStyle = vsReport
    OnCompare = LVFolderCompare
    OnCustomDrawItem = LVFolderCustomDrawItem
    OnDblClick = LVFolderDblClick
    OnKeyDown = LVFolderKeyDown
    OnSelectItem = LVFolderSelectItem
  end
  object MainMenu: TMainMenu
    Left = 28
    Top = 32
    object MenuFile: TMenuItem
      Caption = 'Fichier'
      object MenuSearch: TMenuItem
        Caption = 'Nouvelle recherche...'
        OnClick = MenuSearchClick
      end
      object MenuCancel: TMenuItem
        Caption = 'Arr'#234'ter la recherche'
        Enabled = False
        OnClick = MenuCancelClick
      end
      object MenuClearSearch: TMenuItem
        Caption = 'Effacer la recherche'
        Enabled = False
        OnClick = MenuClearSearchClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object MenuQuit: TMenuItem
        Caption = 'Quitter'
        OnClick = MenuQuitClick
      end
    end
    object MenuReplica: TMenuItem
      Caption = 'R'#233'plique'
      object MenuRefresh: TMenuItem
        Caption = 'Rafra'#238'chir'
        Enabled = False
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object MenuOpen: TMenuItem
        Caption = 'Ouvrir le(s) fichier(s)'
        Enabled = False
        OnClick = MenuOpenClick
      end
      object MenuOpenFolder: TMenuItem
        Caption = 'Ouvrir le(s) dossier(s) contenant le fichier'
        Enabled = False
        OnClick = MenuOpenFolderClick
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object MenuDelete: TMenuItem
        Caption = 'Supprimer le(s) fichier(s)'
        Enabled = False
        OnClick = MenuDeleteClick
      end
    end
    object MenuHelp: TMenuItem
      Caption = 'Aide'
      object MenuAbout: TMenuItem
        Caption = 'A propos...'
        OnClick = MenuAboutClick
      end
    end
  end
  object ImageList: TImageList
    ColorDepth = cd32Bit
    DrawingStyle = dsTransparent
    Left = 388
    Top = 240
  end
end
