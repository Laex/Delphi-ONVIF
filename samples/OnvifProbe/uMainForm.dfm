object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'ONVIF demo'
  ClientHeight = 789
  ClientWidth = 1044
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 1044
    Height = 789
    ActivePage = TabSheet2
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Probe'
      DesignSize = (
        1036
        761)
      object tv1: TTreeView
        Left = 10
        Top = 10
        Width = 1010
        Height = 712
        Anchors = [akLeft, akTop, akRight, akBottom]
        Indent = 19
        TabOrder = 0
        OnDblClick = tv1DblClick
      end
      object btn1: TButton
        Left = 945
        Top = 728
        Width = 75
        Height = 25
        Anchors = [akRight, akBottom]
        Caption = 'Probe'
        TabOrder = 1
        OnClick = btn1Click
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Snapshot'
      ImageIndex = 1
      object Image1: TImage
        Left = 0
        Top = 41
        Width = 1036
        Height = 720
        Align = alClient
        Proportional = True
        Stretch = True
        ExplicitLeft = 336
        ExplicitTop = 344
        ExplicitWidth = 105
        ExplicitHeight = 105
      end
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 1036
        Height = 41
        Align = alTop
        Caption = 'Panel1'
        ShowCaption = False
        TabOrder = 0
        object cmURL: TLabeledEdit
          Left = 80
          Top = 10
          Width = 145
          Height = 21
          EditLabel.Width = 69
          EditLabel.Height = 13
          EditLabel.Caption = 'Camera URL:  '
          LabelPosition = lpLeft
          TabOrder = 0
          Text = 'http://192.168.3.145'
        end
        object Button1: TButton
          Left = 625
          Top = 8
          Width = 105
          Height = 25
          Caption = 'Get snakshot'
          TabOrder = 1
          OnClick = Button1Click
        end
        object cmUser: TLabeledEdit
          Left = 272
          Top = 10
          Width = 121
          Height = 21
          EditLabel.Width = 32
          EditLabel.Height = 13
          EditLabel.Caption = 'User:  '
          LabelPosition = lpLeft
          TabOrder = 2
          Text = 'onvif'
        end
        object cmPass: TLabeledEdit
          Left = 463
          Top = 10
          Width = 121
          Height = 21
          EditLabel.Width = 60
          EditLabel.Height = 13
          EditLabel.Caption = 'Passwordr:  '
          LabelPosition = lpLeft
          TabOrder = 3
          Text = 'test1234'
        end
      end
    end
  end
  object onvfprb1: TONVIFProbe
    OnCompleted = onvfprb1Completed
    OnProbeMath = onvfprb1ProbeMath
    ProbeType = [ptNetworkVideoTransmitter, ptDevice]
    Left = 916
    Top = 40
  end
end
