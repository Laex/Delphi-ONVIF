object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'ONVIF VMS Demo'
  ClientHeight = 789
  ClientWidth = 1044
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 1044
    Height = 789
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Probe && Device'
      DesignSize = (
        1036
        761)
      object Splitter1: TSplitter
        Left = 734
        Top = 0
        Height = 761
        Align = alRight
        ExplicitLeft = 640
      end
      object tv1: TTreeView
        Left = 0
        Top = 0
        Width = 734
        Height = 689
        Align = alClient
        Indent = 19
        TabOrder = 0
        OnDblClick = tv1DblClick
      end
      object pnlActions: TPanel
        Left = 737
        Top = 0
        Width = 299
        Height = 761
        Align = alRight
        TabOrder = 1
        object btnConnect: TButton
          Left = 8
          Top = 8
          Width = 283
          Height = 25
          Caption = 'Connect selected camera'
          TabOrder = 0
          OnClick = btnConnectClick
        end
        object btnStreamUri: TButton
          Left = 8
          Top = 39
          Width = 283
          Height = 25
          Caption = 'Get RTSP Stream URI'
          TabOrder = 1
          OnClick = btnStreamUriClick
        end
        object btnPTZLeft: TButton
          Left = 8
          Top = 78
          Width = 65
          Height = 25
          Caption = 'PTZ Left'
          TabOrder = 2
          OnClick = btnPTZLeftClick
        end
        object btnPTZRight: TButton
          Left = 79
          Top = 78
          Width = 65
          Height = 25
          Caption = 'PTZ Right'
          TabOrder = 3
          OnClick = btnPTZRightClick
        end
        object btnPTZUp: TButton
          Left = 150
          Top = 78
          Width = 65
          Height = 25
          Caption = 'PTZ Up'
          TabOrder = 4
          OnClick = btnPTZUpClick
        end
        object btnPTZDown: TButton
          Left = 221
          Top = 78
          Width = 70
          Height = 25
          Caption = 'PTZ Down'
          TabOrder = 5
          OnClick = btnPTZDownClick
        end
        object btnPTZStop: TButton
          Left = 8
          Top = 109
          Width = 283
          Height = 25
          Caption = 'PTZ Stop'
          TabOrder = 6
          OnClick = btnPTZStopClick
        end
        object btnImaging: TButton
          Left = 8
          Top = 148
          Width = 283
          Height = 25
          Caption = 'Read/Apply Imaging'
          TabOrder = 7
          OnClick = btnImagingClick
        end
        object btnEvents: TButton
          Left = 8
          Top = 179
          Width = 283
          Height = 25
          Caption = 'Events (PullPoint)'
          TabOrder = 8
          OnClick = btnEventsClick
        end
        object btnRegistry: TButton
          Left = 8
          Top = 210
          Width = 137
          Height = 25
          Caption = 'VMS Registry'
          TabOrder = 10
          OnClick = btnRegistryClick
        end
        object btnEventHub: TButton
          Left = 151
          Top = 210
          Width = 140
          Height = 25
          Caption = 'VMS EventHub'
          TabOrder = 11
          OnClick = btnEventHubClick
        end
        object btnRecording: TButton
          Left = 8
          Top = 241
          Width = 137
          Height = 25
          Caption = 'VMS Recording'
          TabOrder = 12
          OnClick = btnRecordingClick
        end
        object btnReplay: TButton
          Left = 151
          Top = 241
          Width = 140
          Height = 25
          Caption = 'Device Replay'
          TabOrder = 13
          OnClick = btnReplayClick
        end
        object mmoLog: TMemo
          Left = 1
          Top = 1
          Width = 297
          Height = 759
          Align = alClient
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 9
        end
      end
      object pnlBottom: TPanel
        Left = 0
        Top = 689
        Width = 1036
        Height = 72
        Align = alBottom
        TabOrder = 2
        object btn1: TButton
          Left = 8
          Top = 8
          Width = 90
          Height = 25
          Caption = 'Multicast Probe'
          TabOrder = 0
          OnClick = btn1Click
        end
        object edtUnicastHost: TLabeledEdit
          Left = 104
          Top = 10
          Width = 105
          Height = 21
          EditLabel.Width = 3
          EditLabel.Height = 13
          EditLabel.Caption = '  '
          LabelPosition = lpLeft
          TabOrder = 1
          Text = '192.168.1.100'
        end
        object btnUnicastProbe: TButton
          Left = 215
          Top = 8
          Width = 90
          Height = 25
          Caption = 'Unicast Probe'
          TabOrder = 2
          OnClick = btnUnicastProbeClick
        end
        object edtSubnet: TLabeledEdit
          Left = 320
          Top = 10
          Width = 120
          Height = 21
          EditLabel.Width = 40
          EditLabel.Height = 13
          EditLabel.Caption = 'Subnet:'
          LabelPosition = lpLeft
          TabOrder = 3
          Text = '192.168.1.0/24'
        end
        object btnSubnetScan: TButton
          Left = 446
          Top = 8
          Width = 90
          Height = 25
          Caption = 'Scan subnet'
          TabOrder = 4
          OnClick = btnSubnetScanClick
        end
        object edtDirectHost: TLabeledEdit
          Left = 8
          Top = 42
          Width = 145
          Height = 21
          EditLabel.Width = 55
          EditLabel.Height = 13
          EditLabel.Caption = 'Direct host:'
          LabelPosition = lpLeft
          TabOrder = 5
          Text = '192.168.1.100'
        end
        object edtDirectUser: TLabeledEdit
          Left = 215
          Top = 42
          Width = 100
          Height = 21
          EditLabel.Width = 28
          EditLabel.Height = 13
          EditLabel.Caption = 'User:'
          LabelPosition = lpLeft
          TabOrder = 6
          Text = 'onvif'
        end
        object edtDirectPass: TLabeledEdit
          Left = 360
          Top = 42
          Width = 100
          Height = 21
          EditLabel.Width = 56
          EditLabel.Height = 13
          EditLabel.Caption = 'Password:'
          LabelPosition = lpLeft
          TabOrder = 7
          Text = 'test1234'
        end
        object btnDirectConnect: TButton
          Left = 550
          Top = 39
          Width = 110
          Height = 25
          Caption = 'Connect direct'
          TabOrder = 8
          OnClick = btnDirectConnectClick
        end
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
      end
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 1036
        Height = 41
        Align = alTop
        ShowCaption = False
        TabOrder = 0
        object cmURL: TLabeledEdit
          Left = 80
          Top = 10
          Width = 145
          Height = 21
          EditLabel.Width = 69
          EditLabel.Height = 21
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
          Caption = 'Get snapshot'
          TabOrder = 1
          OnClick = Button1Click
        end
        object cmUser: TLabeledEdit
          Left = 272
          Top = 10
          Width = 121
          Height = 21
          EditLabel.Width = 32
          EditLabel.Height = 21
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
          EditLabel.Width = 56
          EditLabel.Height = 21
          EditLabel.Caption = 'Password:  '
          LabelPosition = lpLeft
          TabOrder = 3
          Text = 'test1234'
        end
      end
    end
  end
  object onvfprb1: TONVIFProbe
    OnCompleted = onvfprb1Completed
    OnProbeMatch = onvfprb1ProbeMath
    OnProbeMath = onvfprb1ProbeMath
    Left = 916
    Top = 40
  end
end
