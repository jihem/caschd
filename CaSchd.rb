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

require 'webrick'
require 'webrick/https'
require 'yaml'
require 'CaJson'
require 'CaTest'
require 'drb'

sch=nil
web=nil
dta=nil
$err=nil
tst=['*','%']

$port=2000
$drby=false
$dres=[ false ]*40

class CaRdby
  def set(mid,res)
    $dres[mid]=res
  end
  def self.update(mid,res)
    DRb.start_service()
    cpt=4
    while(cpt>0)
        begin
            obj=DRbObject.new(nil, 'druby://localhost:'+$drby.to_s)
            obj.set(mid,res)
            cpt=0
        rescue
            sleep(0.25)
            cpt-=1
        end
    end
    DRb.stop_service()
  end
end

class CaEvent  
    attr_accessor :evnt
    attr_accessor :evok
    attr_reader   :time
    attr_reader   :test
    
    def initialize(evt,tme,tst)
        @evnt=evt
        @evok=evt
        @time=tme
        @test=tst
    end
end

class CaSchd
    attr_reader :list
    attr_reader :json
    attr_reader :page
    attr_reader :logh
    attr_reader :htbt

    def initialize(dta)
        @wrkr=[ false ]*40
        @json=dta 
        @test=CaTest.new
        @list=Array.new
        @pool={}
        @mutex=Mutex.new
        @hdte=get_date()
        @page={}
        @page['*']='*'
        @page['%']='_'+' _'*39
        @page['#*']=''
        @page['#?']=''
        @logh=ini_logh()
        @htbt={}
        hnow=get_now()
        @wday=hnow[0..0]
        @json.data['test'].each do | ts |
            ts['file']='htdocs/'+ts['name'].gsub(/\W/,'_')+'_'+@hdte+".csv"
            ts['exec'].each do | ex |
                ex['cdwn']=ex['redo']
                ex['ccrt']=0
                ex['cmax']=0
                if ex['name']=='htbt'
                    @htbt[ex['args'][1]]=[ex['args'][2], false]
                end
            end
            ts['time'].each do | tm |
                if ! @page.keys.include?(ts['name'])
                    @page[ts['name']]=ts['name'] 
                end
                if ts['doit'] 
                    if tm['days'].include?(hnow[0..0]) && (hnow[1..4] <= tm['to'])
                        list << CaEvent.new('0'+tm['from'],tm,ts)
                    else
                        list << CaEvent.new('1'+tm['from'],tm,ts)
                    end
                end
            end
        end
    end
    
    def synchronize
        @mutex.synchronize { yield self }
    end
      
    def get_page(nme)
        dta=''
        synchronize { |sch| dta=sch.page[nme] }
        return dta
    end
    
    def set_page(nme,dta)
        synchronize { |sch| sch.page[nme]=dta }
    end
    
    def get_htbt(nme)
        dta=''
        synchronize do |sch|
            dta=sch.htbt[nme][1]
            sch.htbt[nme][1]=false
        end
        return dta
    end
    
    def set_htbt(nme,pss)
        res=false
        synchronize do |sch|
            if sch.htbt.has_key?(nme) && sch.htbt[nme][0]==pss
                sch.htbt[nme][1]=true
                res=true
            end
        end
        return res
    end
    
    def set_page_chr(nme,pos,chr)
        synchronize { |sch| sch.page[nme][pos]=chr }
    end
  
    def ini_logh
        res=[]
        if File.file?('caschd.log')
            buf=''
            pos=[]
            fle=File.new('caschd.log','r')
            sze=File.size('caschd.log')
            while (sze>0) && (pos.length<100) 
                dlt=8192
                if sze<8192
                    dlt=sze
                end
                pos.each_index { | ix | pos[ix]+=dlt }
                sze-=dlt
                fle.seek(sze)
                blk=fle.read(dlt)
                buf=blk+buf
                idx=blk.index("\n")
                tps=[]
                while (idx)
                    tps << idx
                    idx+=1
                    idx=blk.index("\012",idx)        
                end
                tps.reverse!
                tps.each { | ix | pos.unshift(ix) }
            end
            pos << (buf.length-1)
            pos.each_index do | ix |
                if (ix<(pos.length-2))
                    res << buf[pos[ix]+1..pos[ix+1]-1]
                end
            end
        end
        res.reverse!
        return res
    end
    
    def get_logh()
        dta=''
        synchronize { |sch| dta=sch.logh.join("<br/>\n") }
    end
    
    def add_logh(dta)
        synchronize do |sch|
            now=get_date()
            msg=now[0..3]+'/'+now[4..5]+'/'+now[6..7]+' '+now[8..9]+':'+now[10..11]+':'+now[12..13]+' : '+dta
            sch.logh.unshift(msg)
            File.open('caschd.log','a') { |fle| fle.write(msg+"\n") } 
            if sch.logh.length>100
                sch.logh.pop
            end
        end
    end
    
    def exec(prm)
        wid=-1
        while (wid==-1) 
            @wrkr.each_index do | id |
                if (wid<0) && !@wrkr[id]
                    @wrkr[id]=true
                    wid=id
                end
            end
            if (wid==-1)
                sleep(5)
            end
        end
        thr=Thread.new(wid)  do |mid|
            res=false
            begin
                set_page_chr('%',mid*2,'*')
                cnt=2          
                while (cnt>0)
                    deb=Time.new                
                    dly=prm['args'].length>0 ? prm['args'][0] : 10
                    pid=nil
                    begin
                        timeout(dly) do
                            if @test.respond_to?(prm['name'])
                                if $drby
                                    $dres[mid]=false
                                    pid=fork { CaRdby.update(mid,@test.send(prm['name'],prm['args'])) }
                                    Process.wait(pid)
                                    res=$dres[mid]
                                else
                                    res=@test.send(prm['name'],prm['args'])
                                end
                            else
                                res=prm['name']=='htbt'? get_htbt(prm['args'][1]) : false
                            end
                        end
                    rescue
                        res=false
                    ensure
                        if $drby
                            begin
                                Process.kill("HUP",pid)
                                Process.wait(pid)
                            rescue
                                #
                            end
                        end
                        prm['ccrt']=Time.new-deb
                        if prm['ccrt']>prm['cmax']
                            prm['cmax']=prm['ccrt']
                        end               
                        if (res || (prm['cdwn']==-1))
                            cnt=0
                        else
                            sleep(5)
                            cnt-=1
                        end
                    end
                end
            ensure
                if res
                    if prm['cdwn']!=prm['redo']
                        add_logh('OK : '+@test.info(prm))
                        prm['cdwn']=prm['redo'] 
                    end
                else
                    if prm['cdwn']==0
                        add_logh('KO : '+@test.info(prm))
                    end
                    if prm['cdwn']>-1
                        prm['cdwn']-=1
                    end
                end
                set_page_chr('%',mid*2,'_')
                @wrkr[mid]=false
            end
        end
    end 
    
    def get_now
        now=Time.new
        sprintf("%1d%2.2d%2.2d",now.wday,now.hour,now.min)
    end
    
    def get_date
        now=Time.new
        sprintf("%4.4d%2.2d%2.2d%2.2d%2.2d%2.2d",now.year,now.month,now.day,now.hour,now.min,now.sec)
    end

    def get_next(tme)
        now=Time.new
        day=now.wday
        now+=tme['wait']*60
        evt=sprintf("%2.2d%2.2d",now.hour,now.min)
        if (evt<=tme['to']) 
            if now.wday==day
                if (evt>=tme['from'])
                    sprintf("0%s",evt)
                else
                    sprintf("0%s",tme['from'])
                end
            else
                sprintf("1%s",evt)
            end
        else
            sprintf("1%s",tme['from'])
        end
    end   
    
    def schd_start        
        acv={}     
        fle='caschd.flg'
        open(fle,"w") do | fl |
            fl.puts get_now()
            fl.close
        end
        while File.file?(fle)
            now=get_now()
            nme={}
            @list.sort_by { | ev | ev.evnt }   
            @list.each do | ev |
                flg=(ev.evnt[0..0]=='0') && (now[1..4]>=ev.evnt[1..4])
                fok=(ev.evok[0..0]=='0') && (now[1..4]>=ev.evok[1..4])
                res=true
                if flg || (nme[ev.test['name']]==nil)
                    if flg
                        begin
                            if File.file?(ev.test['file'])
                                fcv=open(ev.test['file'],'a')
                            else
                                fcv=open(ev.test['file'],'w')
                                fbf='"date";"time"'
                                ev.test['exec'].each { | ex | fbf+=';"'+ex['name']+'_'+ex['args'][1].to_s.gsub(/\W/,'_')+'"' }
                                fcv.write(fbf+"\n")
                                fcv.close
                                fcv=open(ev.test['file'],'a')
                            end
                        rescue
                            #
                        end
                        fbf=get_date()
                        fbf='"'+fbf[0..3]+'/'+fbf[4..5]+'/'+fbf[6..7]+'";"'+fbf[8..9]+':'+fbf[10..11]+'"'
                        ev.test['exec'].each do | ex |
                            fbf+=';'+ (ex['cdwn']!=-1 ? ("%01.1f" %ex['ccrt']) : '-1')
                            if flg && ( (ex['cdwn']==-1) || (! ex['atom']) || (ex['atom'] && fok) )
                                exec(ex)
                            end
                            res=res && (ex['cdwn']!=-1)
                        end
                        begin
                            if (acv[ev.test['name']])
                                fcv.write(fbf+"\n")
                            else
                                acv[ev.test['name']]=true
                            end
                            fcv.close
                        rescue
                            #
                        end
                    else
                        ev.test['exec'].each { | ex | res=res && (ex['cdwn']!=-1) }
                    end
                    nme[ev.test['name']]=res
                else
                    res=nme[ev.test['name']]
                end
                if (fok)
                    ev.evok=get_next(ev.time)
                end
                if res
                    if flg
                        ev.evnt=ev.evok
                    end
                else
                    if flg || (ev.evnt==ev.evok)
                        tme=ev.time.clone
                        if tme['days'].include?(now[0..0])
                            tme['wait']=1 # redo delay
                            ev.evnt=get_next(tme)
                        else
                            ev.evnt='1'+tme['from']
                        end
                    end
                end
            end
            if @wday!=now[0..0]
                @wday=now[0..0]
                @list.each do | ev |
                    if ev.time['days'].include?(@wday) && (now[1..4] <= ev.time['to'])
                        ev.evnt='0'+ev.evnt[1..4]
                        ev.evok='0'+ev.evok[1..4]
                    else
                        ev.evnt='1'+ev.time['from']
                        ev.evok='1'+ev.time['from']
                    end
                end
            end
            sleep 20
        end
    end
    
    def start
        thr=Thread.new { schd_start }
        lst={}
        @list.each { | ev | lst[ev.test['name']]=[false, -2, -2] }
        idx=lst.keys.sort
        pgc=@hdte
        idx.each { | nm | pgc+='#'+nm }
        set_page('#*',pgc)
        set_page('#?',@hdte+'#'+('0'*idx.length))
        while thr.status
            now=get_now()
            pge={}
            pgi={}
            pgo={}
            
            lst.each do | nm,vl |
                lst[nm]=[vl[0],-2, -2]
                pge[nm]='<table>'
            end
            @list.each do | ev |
                srv=ev.time['days'].include?(now[0..0]) && (ev.time['from'] <=now[1..4]) && (now[1..4] <= ev.time['to'])
                clr=srv ? 'yellow' : 'black'
                pge[ev.test['name']]+='<tr><td bgcolor="'+clr+'" width="20"></td><td>'+ev.evnt[1..2]+':'+ev.evnt[3..4]+' ('+ev.evok[1..2]+':'+ev.evok[3..4]+') '+ev.time['days']+' ('+ev.time['from'][0..1]+':'+ev.time['from'][2..3]+'-'+ev.time['to'][0..1]+':'+ev.time['to'][2..3]+")</td></tr>\n"
                pgx=''
                ev.test['exec'].each do | ex |
                    clr='blueviolet'
                    if ex['cdwn']!=ex['redo']
                        if srv
                            if lst[ev.test['name']][1]!=-1
                                lst[ev.test['name']][1]=ex['cdwn']
                            end
                            if ex['cdwn']==-1
                                clr='red'
                            else
                                clr='yellow'
                            end                       
                        else
                            if lst[ev.test['name']][2]!=-1
                                lst[ev.test['name']][2]=ex['cdwn']
                            end    
                        end
                    else
                        clr='green'
                    end
                    if (srv && ! pgi[ev.test['name']]) || (! srv && ! pgo[ev.test['name']])
                        pgx+='<tr><td bgcolor="'+clr+'" width="20"></td><td>'+@test.info(ex)+' ('+("%01.1f" %ex['ccrt'])+'<'+("%01.1f" %ex['cmax'])+")</td></tr>\n"
                    end
                end
                if srv
                    if (! pgi[ev.test['name']])
                        pgi[ev.test['name']]=pgx                       
                    end
                else
                    if (! pgo[ev.test['name']])
                        pgo[ev.test['name']]=pgx  
                    end
                end
            end
            lst.each do | nm,vl |
                pge[nm]+="<tr><td><br/></td><td><hr noshade width=\"460\" size=\"3\" align=\"left\"></td></tr>\n"
                if pgi[nm]
                    pge[nm]+=pgi[nm]
                else
                    pge[nm]+=pgo[nm]
                end
                pge[nm]+='</table>'
                set_page(nm,pge[nm])
            end
            pgc=@hdte+'#'
            pge='<table>'          
            slp=20
            idx.each do | nm |
                vl=lst[nm]
                sbj=nm
                if (vl[1]==-1)
                    sbj+=" KO!"
                    pgc+='2'
                elsif (vl[2]==-1)
                    sbj+=" OK?"
                    pgc+='1'
                else
                    sbj+=" OK!"
                    pgc+='0'
                end                
                if vl[0]!=(vl[1]==-1)
                    if @pool.keys.include?(nm) && (nm[0..0]!='!')  
                        @pool.delete(nm)
                    else
                        if nm[0..0]!='!' 
                            @pool[nm]={ 'wait'=>7, 'list'=>[] }
                        else 
                            @pool[nm]={ 'wait'=>1, 'list'=>[] }
                        end   
                        @json.data['user'].each do | us |
                            if (us['doit']) && (us['test'].include?(nm))
                                res=false
                                if sbj=~ /OK.$/
                                    us['tmok'].each do | tm |
                                        if tm['days'].include?(now[0..0]) && (tm['from'] <= now[1..4]) && (now[1..4] <= tm['to'])
                                            res=true
                                        end
                                    end
                                else
                                    us['tmhs'].each do | tm |
                                        if tm['days'].include?(now[0..0]) && (tm['from'] <= now[1..4]) && (now[1..4] <= tm['to'])
                                            res=true
                                        end
                                    end
                                end
                                if res
                                    prm=us['exec']['args'].clone
                                    if us['exec']['name']=='smtp'
                                        msg="#{sbj}\t"
                                        if sbj=~ /OK.$/
                                            prm[3].split(//).each do |cr|
                                                case cr
                                                when "p"
                                                    msg+=get_page(nm)+"<br/>\n"
                                                when "l"
                                                    msg+=get_logh()+"<br/>\n"
                                                when "f"
                                                    fln='_'+nm.to_s.gsub(/\W/,'_')
                                                    fln=File.file?(fln+'.OK') ? fln+'.OK' : fln
                                                    if File.file?(fln)
                                                        fle=File.new(fln)
                                                        msg+=fle.read(File.size(fln))+"<br/>\n"
                                                    end
                                                end                            
                                            end
                                        else
                                            prm[3].split(//).each do |cr|
                                                case cr
                                                when "P"
                                                    msg+=get_page(nm)+"<br/>\n"
                                                when "L"
                                                    msg+=get_logh()+"<br/>\n"
                                                when "F"
                                                    fln='_'+nm.to_s.gsub(/\W/,'_')
                                                    fln=File.file?(fln+'.KO') ? fln+'.KO' : fln
                                                    if File.file?(fln)
                                                        fle=File.new(fln)
                                                        msg+="<br/>\n"+fle.read(File.size(fln))+"\n"
                                                    end
                                                end
                                            end
                                        end
                                        prm[3]=msg
                                    end  
                                    @pool[nm]['list']<< { 'user'=>us['name'],'name'=>us['exec']['name'],'subj'=>sbj,'args'=>prm }                        
                                end
                            end
                        end
                    end
                    lst[nm][0]=(lst[nm][1]==-1)
                end         
                clr='blueviolet'
                if (vl[1]==-2) && (vl[2]==-2)
                    clr='green'
                else
                    if (vl[1]==-1)
                        clr='red'
                    else
                        if (vl[1]!=-2)
                            clr='yellow'
                        end
                    end
                end
                pge+="<tr><td bgcolor=\"#{clr}\" width=\"20\"></td><td><a href=\"?page=#{nm}\">#{nm}</a></td></tr>\n" 
                #
                if @pool.keys.include?(nm)
                    @pool[nm]['wait']-=1
                    if @pool[nm]['wait']<=0
                        @pool[nm]['list'].each do | itm |
                            tst=CaTest.new
                            sbj=itm['subj']
                            prm=itm['args']
                            dly=prm.length>0 ? prm[0] : 10
                            mly=dly                         
                            res=false
                            snd=Thread.new do
                                begin
                                    case itm['name']
                                    when 'ping'
                                        res=tst.ping(prm)
                                    when 'http'
                                        res=tst.http(prm)
                                    when 'smtp'
                                        res=tst.smtp(prm)
                                    when 'puts'
                                        res=true
                                    end
                                rescue
                                    #
                                end
                            end
                            while ((dly>0) && !res)
                                if snd && snd.alive?
                                    sleep(1)
                                    dly-=1
                                    slp-=1 if slp>1
                                else
                                    dly=0    
                                end
                            end
                            snd.kill if snd && snd.alive?
                            if res
                                add_logh("** : #{sbj} (#{itm['user']} OK #{dly}/#{mly})")
                            else
                                add_logh("** : #{sbj} (#{itm['user']} KO)")
                            end
                        end
                        @pool.delete(nm)
                    end
                end
                #
            end
            pge+='<tr><td></td><td><a href="?page">*</a></td></tr></table>'
            set_page('#?',pgc)
            set_page('*',pge)
            sleep slp
        end            
    end
end

begin
    $err="Error: can\'t create directory \'htdocs\'\n"
    FileUtils.mkdir('htdocs') unless File.directory?('htdocs')
    if File.directory?('htdocs')
        $err="Error: caschd.conf not found\n"
        dta=CaJson.new('caschd.conf')
        $err=nil
    end
rescue
    #
end

if (! $err)
    if dta.data
        # conf
        if dta.data['conf']
            if dta.data['conf']['port']
                if dta.data['conf']['port'].class.to_s=='Fixnum'
                    if dta.data['conf']['port']<0 || dta.data['conf']['port']>65535
                        $err="'test' section, wrong port value"
                    end
                else
                    $err="'conf' section, port isn't a Fixnum"
                end
            end        
            if dta.data['conf']['drby']
                if dta.data['conf']['drby'].class.to_s=='Fixnum'
                    if dta.data['conf']['drby']==dta.data['conf']['port'] || dta.data['conf']['drby']<0 || dta.data['conf']['drby']>65535
                        $err="'conf' section, wrong drby value"
                    end
                else
                    $err="'conf' section, drby isn't a Fixnum"
                end            
            end
        end
        
        # test
        if dta.data['test']
            dta.data['test'].each do | te |
                if (! $err)
                    if te['name']
                        if tst.index(te['name'])==nil
                            tst<<te['name']
                        else
                            $err="'test' section '#{te['name']}' duplicate or reserved"
                        end
                    else
                        $err="'test' section without name"
                    end
                end
                if (! $err) && (te['doit']==nil)
                    $err="'test' section '#{te['name']}, property 'doit' not defined"
                end
                if (! $err)
                    if te['time']
                        te['time'].each do | tm |
                            if (! $err)
                                if tm['days']
                                    if (! $err) && (! tm['days'].match(/^(-|[0-6])+$/))
                                        $err="'test' section '#{te['name']}, in 'time' property, wrong 'days'"
                                    end
                                else
                                    $err="'test' section '#{te['name']}, in 'time' property, 'days' not defined"
                                end
                            end
                            if (! $err)
                                if tm['from']
                                    if (tm['from'].length!=4) || ((tm['from']!='2400') && ((tm['from'][0..1]<'00') || (tm['from'][0..1]>'23') || (tm['from'][2..3]<'00') || (tm['from'][2..3]>'59')))
                                        $err="'test' section '#{te['name']}, in 'time' property, wrong 'from'"
                                    end
                                else
                                    $err="'test' section '#{te['name']}, in 'time' property, 'from' not defined"
                                end
                            end
                            if (! $err)
                                if tm['to']
                                    if (tm['to'].length!=4) || ((tm['to']!='2400') && ((tm['to'][0..1]<'00') || (tm['to'][0..1]>'23') || (tm['to'][2..3]<'00') || (tm['to'][2..3]>'59')))
                                        $err="'test' section '#{te['name']}, in 'time' property, wrong 'to'"
                                    end                        
                                else
                                    $err="'test' section '#{te['name']}, in 'time' property, 'to' not defined"
                                end
                            end
                            if (! $err)
                                if tm['wait']
                                    if (tm['wait']<-1) || (tm['wait']>=1440)
                                        $err="'test' section '#{te['name']}, in 'time' property, wrong 'wait'"
                                    end
                                else
                                    $err="'test' section '#{te['name']}, in 'time' property, 'wait' not defined"
                                end
                            end
                        end
                    else
                        $err="'test' section '#{te['name']}, property 'time' not defined"
                    end
                end
                if (! $err)
                    if te['exec']
                        te['exec'].each do | ex |
                            if (! $err) && (! ex['name'])
                                $err="'test' section '#{te['name']}, property 'exec', 'name' not defined"
                            end
                            if (! $err) && (! ex['args'])
                                $err="'test' section '#{te['name']}, property 'exec', 'args' not defined"
                            end
                            if (! $err)
                                if ex['redo']
                                    if (ex['redo']<0) || (ex['redo']>99)
                                        $err="'test' section '#{te['name']}, property 'exec', wrong 'redo'"
                                    end   
                                else
                                    ex['redo']=0
                                end
                            end
                            if (! $err) && (ex['atom']==nil)
                                ex['atom']=true
                            end
                        end
                    else
                        $err="'test' section '#{te['name']}, property 'exec' not defined"
                    end
                end
            end
        else
            $err="'test' section not defined"
        end
    
        # user
        if (! $err)
            if dta.data['user']
                dta.data['user'].each do | us |
                    if (! $err) && (! us['name'])
                        $err="'user' section without name"
                    end
                    if (! $err) && (us['doit']==nil)
                        $err="'user' section '#{us['name']}, property 'doit' not defined"
                    end
                    if (! $err)
                        if us['tmok']
                            us['tmok'].each do | tm |
                                if (! $err)
                                    if tm['days']
                                        if (! $err) && (! tm['days'].match(/^(-|[0-6])+$/))
                                            $err="'user' section '#{us['name']}, in 'tmok' property, wrong 'days'"
                                        end
                                    else
                                        $err="'user' section '#{us['name']}, in 'tmok' property, 'days' not defined"
                                    end
                                end
                                if (! $err)
                                    if tm['from']
                                        if (tm['from'].length!=4) || ((tm['from']!='2400') && ((tm['from'][0..1]<'00') || (tm['from'][0..1]>'23') || (tm['from'][2..3]<'00') || (tm['from'][2..3]>'59')))
                                            $err="'user' section '#{us['name']}, in 'tmok' property, wrong 'from'"
                                        end
                                    else
                                        $err="'user' section '#{us['name']}, in 'tmok' property, 'from' not defined"
                                    end
                                end
                                if (! $err)
                                    if tm['to']
                                        if (tm['to'].length!=4) || ((tm['to']!='2400') && ((tm['to'][0..1]<'00') || (tm['to'][0..1]>'23') || (tm['to'][2..3]<'00') || (tm['to'][2..3]>'59')))
                                            $err="'user' section '#{us['name']}, in 'tmok' property, wrong 'to'"
                                        end                        
                                    else
                                        $err="'user' section '#{us['name']}, in 'tmok' property, 'to' not defined"
                                    end
                                end
                            end
                        else
                            $err="'user' section '#{us['name']}, property 'tmok' not defined"
                        end
                        if us['tmhs']
                            us['tmhs'].each do | tm |
                                if (! $err)
                                    if tm['days']
                                        if (! $err) && (! tm['days'].match(/^(-|[0-6])+$/))
                                            $err="'user' section '#{us['name']}, in 'tmhs' property, wrong 'days'"
                                        end
                                    else
                                        $err="'user' section '#{us['name']}, in 'tmhs' property, 'days' not defined"
                                    end
                                end
                                if (! $err)
                                    if tm['from']
                                        if (tm['from'].length!=4) || ((tm['from']!='2400') && ((tm['from'][0..1]<'00') || (tm['from'][0..1]>'23') || (tm['from'][2..3]<'00') || (tm['from'][2..3]>'59')))
                                            $err="'user' section '#{us['name']}, in 'tmhs' property, wrong 'from'"
                                        end
                                    else
                                        $err="'user' section '#{us['name']}, in 'tmhs' property, 'from' not defined"
                                    end
                                end
                                if (! $err)
                                    if tm['to']
                                        if (tm['to'].length!=4) || ((tm['to']!='2400') && ((tm['to'][0..1]<'00') || (tm['to'][0..1]>'23') || (tm['to'][2..3]<'00') || (tm['to'][2..3]>'59')))
                                            $err="'user' section '#{us['name']}, in 'tmhs' property, wrong 'to'"
                                        end                        
                                    else
                                        $err="'user' section '#{us['name']}, in 'tmhs' property, 'to' not defined"
                                    end
                                end
                            end
                        else
                            $err="'user' section '#{us['name']}, property 'tmhs' not defined"
                        end                    
                    end
                    if (! $err)
                        if us['test']
                            us['test'].each do | te |
                                if (! $err) && (tst.index(te)==nil)
                                    $err="'user' section '#{us['name']}, property 'test', test '#{te}' unkown"
                                end
                            end
                        else
                            $err="'user' section '#{us['name']}, property 'test' not defined"
                        end
                    end
                    if (! $err)
                        if us['exec']    
                            if (! $err) && (! us['exec']['name'])
                                $err="'user' section '#{us['name']}, property 'exec', 'name' not defined"
                            end
                            if (! $err) && (! us['exec']['args'])
                                $err="'user' section '#{us['name']}, property 'exec', 'args' not defined"
                            end         
                        else
                            $err="'user' section '#{us['name']}, property 'exec' not defined"
                        end
                    end    
                end
            else
                $err="'user' section not defined"
            end
        end
    else
        $err="near '#{dta.resp}'\n"
    end
    $err="Error: in caschd.conf #{$err}\n" if $err
end

if $err
    print $err
else
    if dta.data['conf']
        $port=dta.data['conf']['port'] ? dta.data['conf']['port'] : $port
        $drby=dta.data['conf']['drby'] ? dta.data['conf']['drby'] : $drby
    end
    
    if $drby
        #aServerObject = TestServer.new
        DRb.start_service('druby://localhost:'+$drby.to_s, CaRdby.new)
    end
    
    Socket.do_not_reverse_lookup = true
    sch=CaSchd.new(dta)
    Thread.new do
        sch.start
        web.shutdown
        if ($drby)
            DRb.stop_service()
        end
    end
    
    web=WEBrick::HTTPServer.new(
      :Port            => $port,
      :DocumentRoot    => Dir::pwd + "/htdocs" #,
     # :SSLEnable       => true,
     # :SSLVerifyClient => ::OpenSSL::SSL::VERIFY_NONE,
     # :SSLCertName => [ ["C","FR"], ["O","dnsalias.com"], ["CN", "WDWave"] ]
    )
    
    web.mount_proc("/") do |req, res|
        now=sch.get_now()
        prm={}
        if (req.query_string)
            req.query_string.split('&').each do | ex |
                vlr=ex.split('=')
                prm[vlr[0]]=vlr[1]
            end
        end
        
        if prm['cnsl']
            if prm['cnsl']=='*'
                res.body=sch.get_page('#*')
                res['Content-Type'] = "text/plain"
            else
                res.body=sch.get_page('#?')
                res['Content-Type'] = "text/plain"
            end
        elsif prm['htbt']
            if sch.set_htbt(prm['htbt'],prm['pswd'])
                res.body="#{now}:OK"
            else
                res.body="#{now}:KO"
            end
            res['Content-Type'] = "text/plain"
        else
            if ! sch.get_page(prm['page'])
                prm['page']='*'
            end
            day='1234560'
            day[now[0..0]]='['+now[0..0]+']'
            res.body = "<html><body><table border=\"1\" width=\"640\"><tr><td width=\"140\"><a href=\"http://wdwave.dnsalias.com\">CaSchd.rb</a> ["+($drby ? "Red T." : "Green T.")+"]<br/>20091211</td><td>#{now[1..2]}:#{now[3..4]} #{day} - #{prm['page']}</br>"+sch.get_page('%')+"</td></tr></table>"
            res.body+="<table border=\"0\" width=\"640\"><tr><td valign=\"top\" width=\"140\">"
            res.body+=sch.get_page('*')+"</td><td  valign=\"top\">"
            if prm['page']=='*'
                res.body+='<table><tr><td><font face="Courier New"><span style="font-size:11px">'+sch.get_logh()+'</span></font></td></tr></table>'
            else
                res.body+=sch.get_page(prm['page'])
            end 
            res.body+="</td></tr></table>"
            res.body+="</body></html>" 
            res['Content-Type'] = "text/html"
        end    
    end
    
    trap("INT") do
        web.shutdown
        if ($drby)
            DRb.stop_service()
        end
    end
    web.start
end
