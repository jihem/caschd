require 'net/http'
require 'net/smtp'
require 'net/pop'
require 'uri'

class CaTest
    
    def info(prm)
        res=prm['name']+' '
        case prm['name']
        when 'smtp'
            res+=prm['args'][0..2].join(', ')
        when 'sppp'
            res+=prm['args'][0..2].join(', ')+', '+prm['args'][6]
        when 'htbt','pop3'
            res+=prm['args'][0..1].join(', ')
        else # ping http 
            res+=prm['args'].join(', ')
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
end

