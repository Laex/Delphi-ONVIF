# Delphi-ONVIF

Delphi library for ONVIF IP cameras and enterprise VMS integration.

## Supported platforms

Win32, Win64, Android, Linux64 (Linux64 requires Delphi Linux SDK for linking).

## Architecture

| Module | Purpose |
|--------|---------|
| `ONVIF.Core` | SOAP transport, WS-Security digest, fault parsing |
| `ONVIF.Device` | GetCapabilities, GetServices, device management |
| `ONVIF.Media` | Media ver10: profiles, stream/snapshot URI |
| `ONVIF.Media2` | Media ver20 / Profile T |
| `ONVIF.PTZ` | Pan/tilt/zoom control |
| `ONVIF.Imaging` | Brightness, contrast, focus |
| `ONVIF.Events` | Pull-point event subscriptions |
| `ONVIF.Analytics` | Analytics modules and rules |
| `ONVIF.Recording` | Device-side recording, search, replay |
| `ONVIF.Client` | `TONVIFDevice` high-level API |
| `ONVIF.Discovery` | WS-Discovery probe |

VMS application layer (not in ONVIF package):

| Module | Purpose |
|--------|---------|
| `VMS.CameraRegistry` | Camera list, credentials, health check |
| `VMS.EventHub` | Event aggregation per camera |
| `VMS.RecordingEngine` | Server-side RTSP recording stub |
| `VMS.PlaybackService` | Local + ONVIF replay URI resolution |

## Quick start

```pascal
var
  Device: TONVIFDevice;
  Uri: TStreamUri;
begin
  Device := TONVIFDevice.Create;
  try
    if Device.Connect('http://192.168.1.100/onvif/device_service', 'admin', 'pass') then
    begin
      Uri := Device.GetStreamUri(Device.Profiles[0].token, 'RTP-Unicast', 'RTSP');
      // Use Uri.Uri with your RTSP player
    end;
  finally
    Device.Free;
  end;
end;
```

## ONVIF operations coverage

See [tests/fixtures](tests/fixtures) for sample SOAP responses used in parser tests.

| Service | Key operations |
|---------|----------------|
| Device | GetDeviceInformation, GetCapabilities, GetServices, GetSystemDateAndTime, GetUsers, GetNetworkInterfaces, SystemReboot |
| Media ver10 | GetProfiles, GetStreamUri, GetSnapshotUri, GetVideoSources, Multicast streaming |
| Media2 | GetProfiles, GetStreamUri, GetSnapshotUri |
| PTZ | ContinuousMove, Stop, GetStatus, GetPresets, GotoPreset |
| Imaging | Get/SetImagingSettings, GetOptions, Move, Stop |
| Events | CreatePullPointSubscription, PullMessages, Renew, Unsubscribe |
| Analytics | Get/Modify AnalyticsModules and Rules |
| Recording | GetRecordings, FindRecordings (+ GetRecordingSearchResults, EndSearch), GetReplayUri |

## Migration from legacy API

Replace `GetONVIFAddr(XAddr, atMedia)` with:

```pascal
Device.Connect(XAddr, User, Pass);
MediaUrl := Device.MediaEndpoint;
```

Legacy functions in unit `ONVIF` remain available for backward compatibility.
