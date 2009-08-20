#
# Copyright 2009 Jean-Marc "jihem" QUERE
#
# This file is part of CaSchd.
#
# CaSchd is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CaSchd is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
#

class CaJson
    
    attr_reader :data
    
    def initialize(dta=nil)
        case dta
        when nil
            @data=nil
        when /^[\{|\[]/
            @data=read(dta)
        else
            @data=readFile(dta)
        end

    end
    
    def _read(dta)
        res=nil
        exp=nil
        hsh=nil
        
        if ! "\"{[".index(dta[0..0]) then
            if dta=='true' then
                res=true
            elsif dta=='false' then
                res=false
            else
                res=dta.to_i
            end
        elsif dta[0..0] == '"' 
            res=dta[1..dta.length-2]
        else
            
            if dta[0..0] == '{' then
                res={}
                hsh=true
                exp=dta[1..dta.rindex('}')-1].strip
            else
                res=[]
                hsh=false
                exp=dta[1..dta.rindex(']')-1].strip
            end
            
            qte=false   # "..."
            deb=0       # begin position
            pos=0       # current position
            sep=0       # separator position 
            lvl=0       # level 
            exp.each_byte { |car|       
                if qte
                   qte=(car!=34) 
                else    
                    case car
                    when 34 # "
                        qte=true
                    when 44 # ,
                        if lvl==0 then
                            if hsh then
                                sbk=exp[deb..sep-1].strip
                                sbv=exp[sep+1..pos-1].strip
                                res[sbk[1..sbk.length-2]]=_read(sbv)
                            else
                                sbv=exp[deb..pos-1].strip
                                res << _read(sbv)
                            end
                            deb=pos+1
                        end
                    when 58 # :
                        if lvl==0
                            sep=pos
                        end
                    when 123,91 # { [
                        lvl+=1
                    when 93,125 # ] }
                        lvl-=1
                    end
                end
                
                pos+=1
            }
            if hsh then
                sbk=exp[deb..sep-1].strip
                sbv=exp[sep+1..exp.length-1].strip            
                res[sbk[1..sbk.length-2]]=_read(sbv)
            else
                sbv=exp[deb..exp.length-1].strip            
                res << _read(sbv)
            end
        end
        return res
    end
    
    def read(dta)
        @data=_read(dta)
    end
    
    def readFile(nme)
        dta=""
        fle=File.new(nme,'r')
        while (lne=fle.gets)
            dta+=lne
        end
        fle.close
        read(dta)
    end
    
end

#dta=CaJson.new
#dta.read('{ "name1": "val,{ue1", "name2" : "value2", "name3" : [1, 2, "value", { "n3.3.1" : "331", "n3.3.2": true  }Ê] }')
#print dta.data

#dta=CaJson.new('{ "name1" : "value1" }');
#print dta.data

#dta=CaJson.new('dwdata.txt');
#print dta.data