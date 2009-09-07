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

require 'net/http'
require 'net/smtp'
require 'net/pop'
require 'net/ftp'
require 'resolv'
require 'uri'
require 'tempfile'
require 'ftools'

class CaTest
    
    def info(prm)
        res=nil
        if prm['info']
            res=prm['info']    
        else
            res=prm['name']+' '
            case prm['name']
            when 'smtp'
                res+=prm['args'][0..2].join(', ')
            when 'fpfp'
                res+=prm['args'][0..1].join(', ')+', '+prm['args'][4]+', '+prm['args'][6]+', '+prm['args'][9]
            when 'sppp'
                res+=prm['args'][0..2].join(', ')+', '+prm['args'][6]
            when 'htbt','pop3'
                res+=prm['args'][0..1].join(', ')
            else # ping http 
                res+=prm['args'].join(', ')
            end
        end
        return res
    end
    
    def http(prm)
        dly,url=prm
        res=true
        rep= Net::HTTP.get_response(URI.parse("http://#{url}"))
        case rep
            when Net::HTTPSuccess
                # OK
            else
                res=false
        end
        return res
    end
    
    def ping(prm)
        dly,url,prt=prm
        sck=TCPSocket.new(url, prt)
        sck.close
        return true
    end
    
    def smtp(prm)
        dly,srv,prt,msg,frm,dst=prm
        sbj=''
        idx=msg.index("\t")
        if idx
            sbj=msg[0..idx-1]
            msg=msg[idx+1..msg.length-1]
        else
            sbj=msg
            msg=''
        end
        
        dta = "From: #{frm} <#{frm}>\n"
        dta+= "To: #{dst} <#{dst}>\n"
        dta+= "Content-Type: text/html\n"
        dta+= "Subject: #{sbj}\n\n"
        dta+= "#{msg}\n"    
        Net::SMTP.start(srv,prt) do | net |
            net.send_message(dta,frm,dst)
        end
        return true
    end
    
    def pop3(prm)
        dly,sr2,lgn,pss=prm
        cnx=Net::POP3.new(sr2)
        cnx.start(lgn,pss)       
        cnx.finish
        return true
    end
     
    def sppp(prm)
        dly,sr1,prt,msg,frm,dst,sr2,lgn,pss=prm
        res=false
        
        cnx=Net::POP3.new(sr2)
        cnx.start(lgn,pss)       
        cnx.mails.each { |dta|
            blk=dta.pop
            idx=blk.index("\n")
            while (idx)
                lne=blk[0..idx-1]
                if (lne.length>8)
                    if (lne[0..7].upcase=='SUBJECT:')
                        res=(lne[8..lne.length]=~/#{msg}/)!=nil
                        if res                         
                            dta.delete
                        end
                    end
                end
                blk=blk[idx+1..blk.length-1]
                idx=blk.index("\012")        
            end        
        }
        cnx.finish
        res=smtp(prm) && res
        return res
    end
    
    def rdns(prm)
        dly,srv,uri,ipl=prm
        rsl=Resolv::DNS.new({:nameserver=>[srv],})
        return (' '+ipl+' ').include?(rsl.getaddress(uri).to_s)
    end
    
    def fpfp(prm)
        dly,sr1,lg1,ps1,fr1,fl1,sr2,lg2,ps2,fr2,fl2=prm
        fl1="caschd.flg" if fl1==""
        fl2="caschd.flg" if fl2==""
        res=false

        tmp=Tempfile.new('caschd','.')
        tmp.close
        begin       
            cnx=Net::FTP.new(sr2,lg2,ps2)
            cnx.passive=true
            cnx.getbinaryfile(fr2, tmp.path, 1024)
            cnx.delete(fr2)
            cnx.close
            res=File.compare(tmp.path,fl2)
        rescue
            #
        end
        tmp.unlink       
        
        cnx=Net::FTP.new(sr1,lg1,ps1)
        cnx.passive=true
        cnx.putbinaryfile(fl1,fr1, 1024)
        cnx.close
        
        return res
    end
    
    def cnsl(prm)
        dly,url,tst,lvl=prm
        tst='#'+tst+'#'
        wrk=true
        pos=0
        mem=nil
        res=true
        
        while (wrk)            
            rep= Net::HTTP.get_response(URI.parse("http://#{url}/?cnsl=*"))
            case rep
                when Net::HTTPSuccess
                    # OK
                    mem=rep.body[0..14]
                    ind=14
                    while (ind<rep.body.length)
                        if (rep.body[ind..ind]=='#')
                            pos=rep.body.index('#',ind+1).to_i-1
                            if (pos==-1)
                                pos=rep.body.length-1
                            end
                            if tst.length>0
                                if tst.index('#'+rep.body[ind+1,pos-ind]+'#')
                                    mem+='0'
                                else
                                    mem+='-'
                                end
                            else
                                mem+='0'
                            end
                        end
                        ind=pos+1
                    end
                else
                    res=false
            end
            
            if (mem)
                rep= Net::HTTP.get_response(URI.parse("http://#{url}/?cnsl=?"))
                case rep
                    when Net::HTTPSuccess
                        # OK
                        if mem[0..14]==rep.body[0..14]
                            wrk=false
                            for ind in (15..rep.body.length)
                                if mem[ind..ind]!='-'
                                    if (rep.body[ind..ind].to_i>=lvl)
                                        res=false
                                    end
                                end
                            end
                        end
                    else
                        res=false
                end
            end
        end
        return res        
    end
end

