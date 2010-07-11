#
# Copyright 2010 Jean-Marc "jihem" QUERE
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
    if dta==nil || dta=='' 
      @data=nil
    else
      if "[{".index(dta[0..0])
        @resp=dta
      else
        @resp=read_file(dta)
      end
      @pscr=0
      @psln=@resp.length
      @data=read()
      if @data==nil
        @resp=@resp[@pscr..@resp.length-1]
      else
        @resp=''
      end
    end
  end

  def read()
    dta=nil
    len=@psln
    while @pscr<len
      ccr=@resp[@pscr..@pscr]
      if ! " \t\n\r".index(ccr)
        if "tTfF".index(ccr)
          # boolean
          if @resp[@pscr..@pscr+4].downcase=="false" && (@resp[@pscr+5..@pscr+5]==nil || " \t\n\r,]}".index(@resp[@pscr+5..@pscr+5]))
            dta=false
            @pscr+=4
          else
            if @resp[@pscr..@pscr+3].downcase=="true" && (@resp[@pscr+4..@pscr+4]==nil || " \t\n\r,]}".index(@resp[@pscr+4..@pscr+4]))
              dta=true
              @pscr+=3
            end
          end
          len=0
        else
          if "0123456789".index(ccr)
            # integer
            dta=0
            while @pscr<len && "0123456789".index(@resp[@pscr..@pscr])
              dta=dta*10+@resp[@pscr]-48
              @pscr+=1
            end
            if @resp[@pscr..@pscr]==nil || " \t\n\r,]}".index(@resp[@pscr..@pscr])
              @pscr-=1
            else
              dta=nil
            end
            len=0
          else
             case ccr
               when "\""
                 # string
                 psc=@pscr+1
                 while psc<len
                   @pscr=@resp.index("\"",@pscr+1)
                   if @pscr
                     if @resp[@pscr+1..@pscr+1]==nil || @resp[@pscr+1..@pscr+1]!="\""
                       dta=@resp[psc..@pscr-1].gsub("\"\"","\"")
                       len=0
                     else
                       @pscr+=1
                     end                     
                   else
                     @pscr=psc-1
                     len=0
                   end
                 end
               when "["
                 # array
                 dta=[]
                 @pscr+=1
                 while @pscr<len
                   while @pscr<len && " \t\n\r,".index(@resp[@pscr..@pscr])
                     @pscr+=1
                   end
                   if @pscr<len
                     if @resp[@pscr..@pscr]=="]"
                       len=0
                     else
                       itm=read()
                       if itm!=nil
                         dta<<itm
                       else
                         dta=nil
                         len=0
                       end
                     end
                   else
                     dta=nil
                     len=0
                   end
                 end
               when "{"
                 # hash
                 dta={}
                 @pscr+=1
                 while @pscr<len
                   while @pscr<len && " \t\n\r,".index(@resp[@pscr..@pscr])
                     @pscr+=1
                   end
                   if @pscr<len
                     if @resp[@pscr..@pscr]=="}"
                       len=0
                     else
                       itm=read()
                       if itm!=nil && itm.class.to_s=="String"
                         while @pscr<len && " \t\n\r".index(@resp[@pscr..@pscr])
                           @pscr+=1
                         end
                         if @resp[@pscr..@pscr]==":"
                           @pscr+=1
                           val=read()
                           if val!=nil
                             dta[itm]=val
                           else
                             dta=nil
                             len=0
                           end
                         else
                           dta=nil
                           len=0
                         end
                       else
                         dta=nil
                         len=0
                       end
                     end
                   else
                     dta=nil
                     len=0
                   end
                 end
               end       
          end
        end
      end
      @pscr+=1
    end
    return dta
  end

  def read_file(nme)
    dta=""
    fle=File.new(nme,"r")
    while (lne=fle.gets)
      dta+=lne
    end
    fle.close
    return dta
  end

end

##dta=CaJson.new('caschd.conf')
#dta=CaJson.new("[ 23, true, { \"test\" \n: {\"inner\":15},\"demo\":28} ]")
#if dta.data!=nil
#  puts 'result : '+dta.data.to_s
#else
#  puts 'error near : '+dta.resp
#end
