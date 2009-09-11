;
; Copyright 2009 Jean-Marc "jihem" QUERE
;
; This file is part of CaSchd.
;
; CaSchd is free software: you can redistribute it And/Or modify
; it under the terms of the GNU General Public License As published by
; the Free Software Foundation, either version 3 of the License, Or
; (at your option) any later version.
;
; CaSchd is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY Or FITNESS For A PARTICULAR PURPOSE.  See the
; GNU General Public License For more details.
;
; You should have received a copy of the GNU General Public License
; along With CaSchd. If Not, see <http://www.gnu.org/licenses/>.
;

Procedure.s HTTPGet(Url.s)
  Eol.s=Chr(13)+Chr(10)
  Prt.l=Val(GetURLPart(Url.s, #PB_URL_Port))
  Res.s=""
  Tmp.s=""
  If Not Prt.l
    Prt.l=80
  EndIf
  CId.l=OpenNetworkConnection(GetURLPart(Url.s, #PB_URL_Site), Prt.l)
  If CId
    *Buf.l=AllocateMemory(1000)
    SendNetworkString(CId,"GET /"+GetURLPart(Url.s, #PB_URL_Path)+"?"+GetURLPart(Url.s, #PB_URL_Parameters)+" HTTP/1.0"+Eol.s+Eol.s)
    Cpt.l=5
    While Cpt.l And (NetworkClientEvent(CId)<>#PB_NetworkEvent_Data)
      Delay(1000)
      Cpt.l=Cpt.l-1
    Wend
    Len.l=ReceiveNetworkData(CId,*Buf.l,1000)
    While Len.l=1000
      Tmp.s=Tmp.s+PeekS(*Buf.l)
      Len.l=ReceiveNetworkData(CId,*Buf.l,1000)
    Wend
    If Len.l<>-1
      Tmp.s=Tmp.s+PeekS(*Buf.l)
      Cpt.l=FindString(Tmp.s,"200 OK"+Eol.s,1)
      If Cpt.l
        Cpt.l=FindString(UCase(Tmp.s),"CONTENT-TYPE",Cpt.l)
        If Cpt.l
          Cpt.l=FindString(Tmp.s,Eol.s+Eol.s,Cpt.l)
          If Cpt.l
            Res.s=Right(Tmp.s,Len(Tmp.s)-Cpt.l-3)
          EndIf
        EndIf
      EndIf
    EndIf    
    FreeMemory(*Buf)    
    CloseNetworkConnection(CId)
  EndIf
  ProcedureReturn Res.s
EndProcedure

If OpenConsole() And InitNetwork()
  Res.l=1
  If CountProgramParameters()=1
    Rsp.s=HTTPGet(ProgramParameter())
    If Len(Rsp.s)=8 And Right(Rsp.s,3)=":OK"
      PrintN(Rsp.s)
      Res.l=0
    EndIf
  Else
    PrintN("Usage: CaSchd_Htbt "+Chr(34)+"http://path_to_CaSchd_server_logs/?htbt=heartbeat_name&pswd=heartbeat_password"+Chr(34))
  EndIf
  End(Res.l)
EndIf


; IDE Options = PureBasic 4.31 (Windows - x86)
; ExecutableFormat = Console
; CursorPosition = 69
; FirstLine = 52
; Folding = -
; EnableXP
; Executable = CaSchd_Htbt.exe
; CommandLine = "http://wdwave.dnsalias.com/schd.js?htbt=heartbeat1&pswd=hb1"