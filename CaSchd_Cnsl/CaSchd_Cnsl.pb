Global IcoB.l=LoadImage(0, "CaSchd_B.ico")
Global IcoG.l=LoadImage(1, "CaSchd_G.ico")
Global IcoR.l=LoadImage(2, "CaSchd_R.ico")
Global IcoP.l=LoadImage(3, "CaSchd_P.ico")
Global OggN.l;
Global UrlA.b=0;
Global UrlC.s;
Global WinH.b=1;

OpenPreferences("CaSchd_Cnsl.ini")
PreferenceGroup("Global")
UrlC.s=ReadPreferenceString("url", "")
ClosePreferences()

Procedure.s HTTPGet(Url.s)
  Res.s=""
  If ReceiveHTTPFile(Url.s,"CaSchd_Cnsl.tmp")
    If ReadFile(0,"CaSchd_Cnsl.tmp")
      If Eof(0)=0
        Res.s=ReadString(0) 
      EndIf
      CloseFile(0)
    EndIf 
  EndIf
  ProcedureReturn Res.s
EndProcedure

Procedure AlertThread(Parameter)
  Ini.b=0
  Repeat
    Mem.s=""
    Tmp.s=HTTPGet(UrlC.s+"/?cnsl=*")
    If Len(Tmp.s)
      Mem.s=Left(Tmp.s,15)
      For Ind.l=15 To Len(Tmp.s)
        If Mid(Tmp.s,Ind.l,1)="#"
          Mem.s=Mem.s+"0"
        EndIf
      Next 
    Else
      AddSysTrayIcon(1, WindowID(0), IcoB.l)
      Ini.b=1
    EndIf
    If Not Ini.b
      Delay(3000)
      Repeat
        Err.l=0
        Wrn.l=0
        Tmp.s=HTTPGet(UrlC.s+"/?cnsl=?")
        If Left(Tmp.s,15)=Left(Mem.s,15)
          For Ind.l=16 To Len(Tmp.s)
            If Mid(Tmp.s,Ind.l,1)<>"0"
              If Mid(Tmp.s,Ind.l,1)<>"1"
                If Mid(Mem.s,Ind.l,1)<>"2"
                  Err.l=Ind.l-15
                Else
                  Wrn.l=Ind.l-15
                EndIf
              Else
                Wrn.l=Ind.l-15
              EndIf
            EndIf
          Next
          If Err.l
            AddSysTrayIcon(1, WindowID(0), IcoR.l)
            UrlA.b=1
          Else
            If Wrn.l
              If Not UrlA.b
                AddSysTrayIcon(1, WindowID(0), IcoP.l)            
              EndIf
            Else
              AddSysTrayIcon(1, WindowID(0), IcoG.l)
              UrlA.b=0  
            EndIf
          EndIf      
          Mem.s=Tmp.s           
        Else
          Ini.b=1
        EndIf
        If UrlA.b Or Ini.b
          PlaySound(OggN.l)
        EndIf
        Delay(120000)
      Until Ini.b
    EndIf
  ForEver
EndProcedure

If InitSound() And InitNetwork() And OpenWindow(0, 0, 0, 300, 30, "CaSchd.rb - Console Externe", #PB_Window_SystemMenu | #PB_Window_ScreenCentered )
  UseOGGSoundDecoder()
  OggN.l=LoadSound(#PB_Any, "CaSchd_Cnsl.ogg")
  PlaySound(OggN.l)
  
  TextGadget(0, 10, 10, 280, 20, "http://wdwave.dnsalias.com") 
  AddSysTrayIcon(1, WindowID(0), IcoB.l)
  SysTrayIconToolTip(1, "CaSchd.rb")
  HideWindow(0,1)
  CreateThread(@AlertThread(),0)
  Repeat
    Event = WaitWindowEvent()
    If Event = #PB_Event_SysTray
      If EventType() = #PB_EventType_LeftDoubleClick
        If UrlA.b 
          ChangeSysTrayIcon (EventGadget(), IcoP.l)
;          SysTrayIconToolTip(EventGadget(), "Changed !")
          UrlA.b=0;
        EndIf
        RunProgram(UrlC.s)
      EndIf
      If EventType() = #PB_EventType_RightClick
         If WinH.b
           WinH.b=0
         Else
           WinH.b=1
         EndIf
         HideWindow(0,WinH.b)
      EndIf
    EndIf
  Until Event = #PB_Event_CloseWindow 
EndIf 
; IDE Options = PureBasic 4.31 (Windows - x86)
; CursorPosition = 40
; FirstLine = 40
; Folding = -
; EnableThread
; EnableXP
; UseIcon = CaSchd_B.ico
; UseMainFile = CaSchd_Cnsl.pb
; Executable = CaSchd_Cnsl.exe
; CPU = 1
; DisableDebugger