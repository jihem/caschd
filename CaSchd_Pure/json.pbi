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

XIncludeFile "dict.pbi"

;
; /!\ WORK IN PROGRESS /!\
;

Enumeration
  #JSN_STR=1
  #JSN_PTR
  #JSN_LST
  #JSN_MAP
EndEnumeration

Structure jsn
  jsn_typ.b
  *jsn_dct.dct
EndStructure

Declare.q jsn_new(jsn_typ.b,arg_idx.q=$7FFFFFFFFFFFFFFF)
Declare jsn_free(*self.jsn)
Declare jsn_set(*self.jsn,arg_idx.q=0,arg_val.q=0)
Declare.q jsn_get(*self.jsn)
Declare jsn_at(*self.jsn,arg_pos.q)

Procedure.q jsn_new(arg_typ.b,arg_idx.q=$7FFFFFFFFFFFFFFF)
  *self.jsn=AllocateMemory(SizeOf(jsn))
  *self\jsn_typ=arg_typ
  *self\jsn_dct=dct_new()
  If arg_idx.q<>$7FFFFFFFFFFFFFFF
    jsn_set(*self,arg_idx)
  EndIf
  ProcedureReturn *self
EndProcedure

Procedure jsn_free(*self.jsn)
  Select *self\jsn_typ
    Case #JSN_STR, #JSN_PTR
      dct_free(*self\jsn_dct)
    Case #JSN_LST, #JSN_MAP
      *each.dct=*self\jsn_dct
      While *each
        jsn_free(*self\jsn_dct\dct_val)
        *each=*each\dct_svt
      Wend
  EndSelect
  FreeMemory(*self)
EndProcedure

Procedure jsn_set(*self.jsn,arg_idx.q=0,arg_val.q=0)
  Select *self\jsn_typ
    Case #JSN_STR
      *self\jsn_dct\dct_idx=PeekS(arg_idx)
    Case #JSN_PTR
      *self\jsn_dct\dct_val=arg_idx
    Case #JSN_LST
      dct_set(*self\jsn_dct,Str(dct_count(*self\jsn_dct)),arg_idx,0)
    Case #JSN_MAP
      dct_set(*self\jsn_dct,PeekS(arg_idx),arg_val) ; <=> ... ,1)
  EndSelect
EndProcedure

Procedure.q jsn_get(*self.jsn)
  res.q
  Select *self\jsn_typ
    Case #JSN_STR
      res=@*self\jsn_dct\dct_idx
    Case #JSN_PTR
      res=*self\jsn_dct\dct_val
    Case #JSN_LST,#JSN_MAP
      res=*self\jsn_dct
  EndSelect
  ProcedureReturn res
EndProcedure

Procedure.s jsn_key(*self.jsn)
  res.s
  Select *self\jsn_typ
    Case #JSN_STR
      res=*self\jsn_dct\dct_idx
    Case #JSN_PTR
      res=Str(*self\jsn_dct\dct_val)
    Case #JSN_LST,#JSN_MAP
      res=*self\jsn_dct\dct_idx
  EndSelect
  ProcedureReturn res
EndProcedure

Procedure jsn_at(*self.jsn,arg_pos.q)
  val.q
  Select *self\jsn_typ
    Case #JSN_LST
      *itm.dct=dct_at(jsn_get(*self),arg_pos)
      If *itm
        val=*itm\dct_val
      EndIf
    Case #JSN_MAP
      val=dct_get(jsn_get(*self),PeekS(arg_pos))
  EndSelect
  ProcedureReturn val
EndProcedure

Procedure jsn_count(*self.jsn)
  cnt.q
  Select *self\jsn_typ
    Case #JSN_STR,#JSN_PTR
      cnt=1
    Case #JSN_LST,#JSN_MAP
      cnt=dct_count(*self)
  EndSelect
  ProcedureReturn cnt
EndProcedure

; *smp.jsn=jsn_new(#JSN_STR)
; jsn_set(*smp,@"Test")
; Debug(PeekS(jsn_get(*smp)))
; jsn_free(*smp)
;
; *smp.jsn=jsn_new(#JSN_PTR)
; jsn_set(*smp,25)
; Debug(jsn_get(*smp))
; jsn_free(*smp)
;
; *smp.jsn=jsn_new(#JSN_STR,@"Test")
; Debug(PeekS(jsn_get(*smp)))
; jsn_free(*smp)
;
; *smp.jsn=jsn_new(#JSN_PTR,25)
; Debug(jsn_get(*smp))
; jsn_free(*smp)
;
; *smp.jsn=jsn_new(#JSN_LST)
; jsn_set(*smp,jsn_new(#JSN_STR,@"Value 1"))
; jsn_set(*smp,jsn_new(#JSN_STR,@"Value 2"))
; jsn_set(*smp,jsn_new(#JSN_STR,@"Value 3"))
; crt.q=1
; *itm.dct=dct_at(jsn_get(*smp),crt)
; While *itm
;   Debug(Str(crt)+" - "+PeekS(jsn_get(*itm\dct_val)))
;   crt=crt+1
;   *itm.dct=dct_at(jsn_get(*smp),crt)
; Wend
; jsn_free(*smp)

*smp.jsn=jsn_new(#JSN_LST)
jsn_set(*smp,jsn_new(#JSN_STR,@"Value 1"))
jsn_set(*smp,jsn_new(#JSN_STR,@"Value 2"))
jsn_set(*smp,jsn_new(#JSN_STR,@"Value 3"))
crt.q=1
*itm.jsn=jsn_at(*smp,crt)
While *itm
  Debug(Str(crt)+" - "+PeekS(jsn_get(*itm)))
  crt=crt+1
  *itm=jsn_at(*smp,crt)
Wend
jsn_free(*smp)

*smp.jsn=jsn_new(#JSN_MAP)
jsn_set(*smp,@"Key 1",jsn_new(#JSN_STR,@"Value 1"))
jsn_set(*smp,@"Key 2",jsn_new(#JSN_STR,@"Value 2"))
jsn_set(*smp,@"Key 3",jsn_new(#JSN_STR,@"Value 3"))
*itm.jsn=jsn_at(*smp,@"Key 1")
If *itm
  Debug(PeekS(jsn_get(*itm)))
EndIf
jsn_free(*smp)