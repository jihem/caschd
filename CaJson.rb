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
    attr_reader :resp
    
    def initialize(dta=nil)
        case dta
        when nil
            @data=nil
        when /^[\{|\[]/
            @resp,@data=read(dta)
        else
            @resp,@data=readFile(dta)
        end

    end
    
    def getBool(str)
        exp=str.lstrip
        res=exp.match(/^(true|false)/)
        if res
            exp=exp[res[0].length..exp.length-1]
            res=res[0]=="true"
        end
        return [exp,res]
    end
    
    def getInteger(str)
        exp=str.lstrip
        res=exp.match(/^[-+]?[0-9]+/)
        if res
            exp=exp[res[0].length..exp.length-1]
            res=res[0].to_i
        end
        return [exp,res]    
    end
    
    def getString(str)
        exp=str.lstrip
        res=exp.match(/^"[^"]*"/)
        if res
            exp=exp[res[0].length..exp.length-1]
            res=res[0][1..res[0].length-2]
        end
        return [exp,res]        
    end
    
    def getValue(str)
        exp,res=getBool(str)
        if res==nil
            exp,res=getInteger(str)
            if res==nil
                exp,res=getString(str)
            end
        end
        return [exp,res]
    end
    
    def getArray(str)
        exp=str.lstrip
        res=nil
        if exp.match(/^\[/)
            res=[]
            exp=exp[1..exp.length-1]
            exp.lstrip!
            itm=true
            while (itm)
                if ! exp.match(/^\]/)
                    exp,itm=getValueOrArrayOrHash(exp)
                    if itm != nil
                        res << itm
                        exp.lstrip!
                        if exp.match(/^,/)
                            exp=exp[1..exp.length-1]
                            tmp,itm=getValueOrArrayOrHash(exp) 
                            
                            if itm == nil
                                res=nil
                            end
                        else
                            if ! exp.match(/^\]/)
                                itm=nil
                                res=nil
                            end
                        end
                    else
                        res=nil
                    end
                else
                    exp=exp[1..exp.length-1]
                    itm=nil
                end
            end
        end
        return [exp,res]
    end
    
    def getPair(str)
        exp,res=getString(str)
        if res
            key=res
            exp.lstrip!
            if exp.match(/^:/)
                exp=exp[1..exp.length-1]
                exp,res=getValueOrArrayOrHash(exp)
                if res!=nil
                    res=[key,res]
                end
            else
                res=nil
            end
        end
        return [exp,res]
    end
    
    def getHash(str)
        exp=str.lstrip
        res=nil
        if exp.match(/^\{/)
            res={}
            exp=exp[1..exp.length-1]
            exp.lstrip!
            itm=true
            while (itm)
                if ! exp.match(/^\}/)
                    exp,itm=getPair(exp)
                    if itm
                        res[itm[0]]=itm[1]
                        exp.lstrip!
                        if exp.match(/^,/)
                            exp=exp[1..exp.length-1]
                            tmp,itm=getPair(exp) 
                            if ! itm
                                res=nil
                            end
                        else
                            if ! exp.match(/^\}/)
                                itm=nil
                                res=nil
                            end
                        end
                    else
                        res=nil
                    end
                else
                    exp=exp[1..exp.length-1]
                    itm=nil
                end
            end
        end
        return [exp,res]
    end
    
    def getValueOrArrayOrHash(str)
        exp,res=getValue(str)
        if res==nil
            exp,res=getArray(str)
            if res==nil
                exp,res=getHash(str)
            end
        end
        return [exp,res]
    end
    
    def read(dta)
        dta.gsub!(/(\n|\t|\r)/," ")
        dta.rstrip!
        exp,res=getValueOrArrayOrHash(dta)
        return [exp,res]
    end
    
    def readFile(nme)
        dta=""
        fle=File.new(nme,'r')
        while (lne=fle.gets)
            dta+=lne
        end
        fle.close
        return read(dta)
    end
end

##dta=CaJson.new('caschd.txt')
#dta=CaJson.new('{ "int1" : 1, "str2" : "two"}')
#if ! dta.data
#    print "Error in caschd.txt near '#{dta.resp}'\n"
#else
#    print dta.data
#end

