; 
; Copyright 2010 Jean-Marc "jihem" QUERE
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

Structure dct
  dct_idx.s
  dct_val.q
  *dct_prc.dct
  *dct_svt.dct
EndStructure

Declare.q dct_new(arg_idx.s="",arg_val.q=0)
Declare dct_free(*self.dct)
Declare dct_set_(*self.dct,arg_idx.s,arg_val.q,arg_srt.b=1)
Declare dct_set(*self.dct,arg_idx.s,arg_val.q,arg_srt.b=1)
Declare.q dct_get(*self.dct,art_idx.s,arg_val.q=0)
Declare.q dct_exists(*self.dct,arg_idx.s)
Declare dct_del(*self.dct,arg_idx.s)
Declare.q dct_count(*self.dct)
Declare.q dct_at(*self.dct,arg_pos.q)
Declare dct_dump_(*self.dct)
Declare dct_dump(*self.dct)

; *smp.dct=dct_new("Key",@"Value")
; dct_dump(*smp)
; dct_free(*smp)
;
Procedure.q dct_new(arg_idx.s="",arg_val.q=0)
  *self.dct=AllocateMemory(SizeOf(dct))
  *self\dct_idx=arg_idx
  *self\dct_val=arg_val  
  ProcedureReturn *self 
EndProcedure

; see above
;
Procedure dct_free(*self.dct)
; Debug("dct_free @"+Str(*self)+" "+*self\dct_idx)
  If *self\dct_svt
    dct_free(*self\dct_svt)    
  EndIf
  FreeMemory(*self)  
EndProcedure

; private
;
Procedure dct_set_(*self.dct,arg_idx.s,arg_val.q,arg_srt.b=1)
  *din.dct
  If *self\dct_idx<arg_idx Or (*self\dct_idx>arg_idx And Not arg_srt)    
    If *self\dct_svt=0
      *self\dct_svt=dct_new(arg_idx,arg_val)
      *self\dct_svt\dct_prc=*self
;     Debug(*self\dct_idx+"<-"+Str(*self\dct_val))    
    Else
      dct_set(*self\dct_svt,arg_idx,arg_val,arg_srt)
    EndIf
  Else
    If *self\dct_idx=arg_idx
      *self\dct_val=arg_val
;     Debug(*self\dct_idx+"<="+Str(*self\dct_val))  
    Else
      *din=*self\dct_prc
      If *din
        *din\dct_svt=dct_new(arg_idx,arg_val)
        *din\dct_svt\dct_prc=*din
        *din\dct_svt\dct_svt=*self
        *self\dct_prc=*din\dct_svt
      Else
        *din=*self\dct_svt
        *self\dct_svt=dct_new(*self\dct_idx,*self\dct_val)
        *self\dct_svt\dct_prc=*self
        If *din
          *self\dct_svt\dct_svt=*din
          *din\dct_prc=*self\dct_svt
        EndIf
        *self\dct_idx=arg_idx
        *self\dct_val=arg_val
      EndIf
    EndIf
  EndIf
EndProcedure

; *smp.dct=dct_new()
; dct_set(*smp,"Key 1",@"Value 1") 
; dct_set(*smp,"Key 2",@"Value 2") 
; dct_set(*smp,"Key 1",@"Updated value") 
; dct_dump(*smp)
; dct_free(*smp)
;
Procedure dct_set(*self.dct,arg_idx.s,arg_val.q,arg_srt.b=1)
  If *self\dct_idx<>""
    dct_set_(*self.dct,arg_idx.s,arg_val.q,arg_srt.b)
  Else
    *self\dct_idx=arg_idx
    *self\dct_val=arg_val
  EndIf
EndProcedure

; *smp.dct=dct_new()
; dct_set(*smp,"Key 1",@"Value 1") 
; dct_set(*smp,"Key 2",@"Value 2") 
; adr.q=dct_get(*smp,"Key 1")
; If adr
;   Debug(PeekS(adr))
; Else
;   Debug("Not found")
; EndIf
; dct_free(*smp)
;
Procedure.q dct_get(*self.dct,arg_idx.s,arg_val.q=0)
  *itm.dct
  If arg_idx<>""
    *itm=dct_exists(*self,arg_idx)
  EndIf
; Debug(*self\dct_idx+"<?>"+arg_idx)
  If *itm
    ProcedureReturn *itm\dct_val
  Else
    ProcedureReturn arg_val
  EndIf
EndProcedure

;  *smp.dct=dct_new("Key",@"Value")
;  If dct_exists(*smp,"Key")
;    Debug("Yes")  
;  Else
;    Debug("No")
;  EndIf
;
Procedure.q dct_exists(*self.dct,arg_idx.s)
  *itm.dct  
; Debug(*self\dct_idx+"<?>"+arg_idx)
  If *self\dct_idx<>arg_idx
    If *self\dct_svt
      *itm=dct_exists(*self\dct_svt,arg_idx)
    EndIf
  Else
;   Debug(arg_idx+"="+Str(*self\dct_val))
    *itm=*self
  EndIf
  ProcedureReturn *itm.dct
EndProcedure

; *smp.dct=dct_new()
; dct_set(*smp,"Key 1",@"Value 1") 
; dct_set(*smp,"Key 2",@"Value 2") 
; dct_set(*smp,"Key 3",@"Value 3") 
; dct_dump(*smp)
; dct_del(*smp,"Key 2")
; dct_dump(*smp)
; dct_free(*smp)
;
Procedure dct_del(*self.dct,arg_idx.s)
  *itm.dct=dct_exists(*self,arg_idx) 
  If *itm
    If *itm=*self
      If *self\dct_svt
        *dsv.dct=*self\dct_svt
        *self\dct_idx=*dsv\dct_idx
        *self\dct_val=*dsv\dct_val
        *self\dct_svt=*dsv\dct_svt
        If *self\dct_svt
          *self\dct_svt\dct_prc=*self
        EndIf
        *dsv\dct_svt=0
        dct_free(*dsv)
      Else
        *self\dct_idx=""
      EndIf
    Else
      *itm\dct_prc\dct_svt=*itm\dct_svt
      If *itm\dct_svt
        *itm\dct_svt\dct_prc=*itm\dct_prc
      EndIf
      *itm\dct_svt=0
      dct_free(*itm)
    EndIf
  EndIf
EndProcedure

; *smp.dct=dct_new()
; dct_set(*smp,"Key 1",@"Value 1") 
; Debug(dct_count(*smp))
; dct_set(*smp,"Key 2",@"Value 2") 
; Debug(dct_count(*smp))
; dct_set(*smp,"Key 3",@"Value 3") 
; Debug(dct_count(*smp))
; dct_free(*smp)
;
Procedure.q dct_count(*self.dct)
  *itm.dct=*self
  cnt.q
  If *self\dct_idx<>""
    While *itm
      cnt=cnt+1
      *itm=*itm\dct_svt
    Wend
  EndIf
  ProcedureReturn cnt
EndProcedure

; *smp.dct=dct_new()
; dct_set(*smp,"Key 1",@"Value 1") 
; dct_set(*smp,"Key 2",@"Value 2") 
; dct_set(*smp,"Key 3",@"Value 3") 
; *itm.dct=dct_at(*smp,3)
; If *itm
;   Debug(PeekS(*itm\dct_val))
; EndIf
; dct_free(*smp)
;
Procedure.q dct_at(*self.dct,arg_pos.q)
  *itm.dct
  If arg_pos.q>0
    If *self\dct_idx<>""
      arg_pos=arg_pos-1
      *itm=*self
      While *itm And arg_pos
        arg_pos=arg_pos-1
        *itm=*itm\dct_svt
      Wend
    EndIf
  EndIf
  If pos
    ProcedureReturn 0
  Else
    ProcedureReturn *itm
  EndIf
EndProcedure

; private
;
Procedure dct_dump_(*self.dct)
  txt.s="@"+Str(*self)+"(P="+Str(*self\dct_prc)+",S="+Str(*self\dct_svt)+") ['"+*self\dct_idx+"']="
  If *self\dct_val
    txt.s=txt.s+"'"+PeekS(*self\dct_val)+"'"
  Else
    txt.s=txt.s+"''"
  EndIf
  Debug(txt)
  If *self\dct_svt
    dct_dump_(*self\dct_svt)  
  EndIf
EndProcedure

; see above
;
Procedure dct_dump(*self.dct)
  dct_dump_(*self)
  Debug("-/-")
EndProcedure

; Advanced sample : structure as value

; Structure book
;   Title.s
;   Price.f
; EndStructure
; 
; bk1.book
; bk1\Title="DMZ2"
; bk1\Price=13.90
; bk2.book
; bk2\Title="DMZ3"
; bk2\Price=15.00
; 
; *smp.dct=dct_new()
; dct_set(*smp,"9782809401790",@bk1)
; dct_set(*smp,"9782809403466",@bk2)
; *res.book=dct_get(*smp,"9782809401790")
; If *res
;   Debug(*res\Title+" ("+StrF(*res\Price,2)+")")
; EndIf
; dct_free(*smp)

; *smp.dct=dct_new()
; dct_set(*smp,"Key 1",@"Value 1") 
; dct_set(*smp,"Key 2",@"Value 2") 
; dct_set(*smp,"Key 1",@"Updated value") 
; dct_dump(*smp)
; dct_free(*smp)
;

; Advanced sample : sorted / ordored

; *smp.dct=dct_new()
; dct_set(*smp,"Third",@"Value 3") 
; dct_set(*smp,"First",@"Value 1") 
; dct_set(*smp,"Second",@"Value 2")
; *each.dct=*smp
; While *each
;   Debug("sorted (asc) :"+*each\dct_idx) 
;   *each=*each\dct_svt
; Wend
; *each.dct=dct_at(*smp,dct_count(*smp))
; While *each
;   Debug("sorted (desc) :"+*each\dct_idx) 
;   *each=*each\dct_prc
; Wend
; dct_free(*smp)
; *smp.dct=dct_new()
; dct_set(*smp,"Third",@"Value 3",0) 
; dct_set(*smp,"First",@"Value 1",0) 
; dct_set(*smp,"Second",@"Value 2",0)
; *each.dct=*smp
; While *each
;   Debug("ordored :"+*each\dct_idx) 
;   *each=*each\dct_svt
; Wend
; dct_free(*smp)
; IDE Options = PureBasic 4.50 (MacOS X - x86)
; CursorPosition = 33
; FirstLine = 3
; Folding = --
; EnableXP