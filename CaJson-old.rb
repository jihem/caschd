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
# along with CaSchd. If not, see <http://www.gnu.org/licenses/>.
#

class CaJson
    
    attr_reader :data
    attr_reader :resp
    
    def initialize(dta='')
        case dta
        when ''
            @data=nil
        when /^[\{|\[]/
            @resp,@data=read(dta)
        else
            @resp,@data=read_file(dta)
        end
    end
    
    def get_bool(str)
        exp=str.lstrip
        res=exp.match(/^(true|false)/)
        if res
            exp=exp[res[0].length..exp.length-1]
            res=res[0]=="true"
        end
        return [exp,res]
    end
    
    def get_integer(str)
        exp=str.lstrip
        res=exp.match(/^[-+]?[0-9]+/)
        if res
            exp=exp[res[0].length..exp.length-1]
            res=res[0].to_i
        end
        return [exp,res]    
    end
    
    def get_string(str)
        exp=str.lstrip
        res=exp.match(/^"([^"]||"")*"/)
        if res
            exp=exp[res[0].length..exp.length-1]
            res=res[0][1..res[0].length-2]
            res.gsub!('""','"')
        end
        return [exp,res]        
    end
    
    def get_value(str)
        exp,res=get_bool(str)
        if res==nil
            exp,res=get_integer(str)
            if res==nil
                exp,res=get_string(str)
            end
        end
        return [exp,res]
    end
    
    def get_array(str)
        exp=str.lstrip
        res=nil
        if exp.match(/^\[/)
            res=[]
            exp=exp[1..exp.length-1]
            exp.lstrip!
            itm=true
            while (itm)
                if ! exp.to_s.match(/^\]/)
                    exp,itm=get_value_or_array_or_hash(exp)
                    if itm != nil
                        res << itm
                        exp.lstrip!
                        if exp.match(/^,/)
                            exp=exp[1..exp.length-1]
                            tmp,itm=get_value_or_array_or_hash(exp)

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
                    exp=exp[1..exp.to_s.length-1]
                    itm=nil
                end
            end
        end
        return [exp,res]
    end
    
    def get_pair(str)
        exp,res=get_string(str)
        if res
            key=res
            exp.lstrip!
            if exp.match(/^:/)
                exp=exp[1..exp.length-1]
                exp,res=get_value_or_array_or_hash(exp)
                if res!=nil
                    res=[key,res]
                end
            else
                res=nil
            end
        end
        return [exp,res]
    end
    
    def get_hash(str)
        exp=str.lstrip
        res=nil
        if exp.match(/^\{/)
            res={}
            exp=exp[1..exp.length-1]
            exp.lstrip!
            itm=true
            while (itm)
                if ! exp.match(/^\}/)
                    exp,itm=get_pair(exp)
                    if itm
                        res[itm[0]]=itm[1]
                        exp.lstrip!
                        if exp.match(/^,/)
                            exp=exp[1..exp.length-1]
                            tmp,itm=get_pair(exp)
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
    
    def get_value_or_array_or_hash(str)
        exp,res=get_value(str)
        if res==nil
            exp,res=get_array(str)
            if res==nil
                exp,res=get_hash(str)
            end
        end
        return [exp,res]
    end
    
    def read(dta)
        dta.gsub!(/(\n|\t|\r)/," ")
        dta.rstrip!
        exp,res=get_value_or_array_or_hash(dta)
        return [exp,res]
    end
    
    def read_file(nme)
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

