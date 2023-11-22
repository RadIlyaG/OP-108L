
##***************************************************************************
##** OpenRL
##***************************************************************************
proc OpenRL {} {
  global gaSet glTests
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  
  RLEH::Open
  
  puts "Open PIO [MyTime]"
  set ret [OpenPio]
  set ret1 [OpenComUut]
  if {$gaSet(dut.eth)=="ETH"} {
    set openGens 1
#     foreach tst [lrange $glTests [lsearch $glTests $gaSet(startFrom)] end] {
#       if {[string match *Data* $tst] || [string match *Loop* $tst] || [string match *FaultPro* $tst]} {
#         set openGens 1
#         break
#       } 
#     }
  } else {
    set openGens 0
  }
  if {$openGens==1} {  
    Status "Open ETH GENERATOR"
    set ret2 [OpenEtxGen]
    if {$ret2!=0} {set gaSet(fail) "Cann't open COM-$gaSet(comEtx)"}
    RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus down
  } else {
    set ret2 0
  } 
  
  Status "Open E1 GENERATOR"
  set ret3 [OpenDxc4] 
   
  
  set gaSet(curTest) $curTest
  puts "[MyTime] ret:$ret ret1:$ret1 ret2:$ret2  ret3:$ret3 " ; update
  if {$ret1!=0 || $ret2!=0 || $ret3!=0} {
    return -1
  }
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  set ret [RLCom::Open $gaSet(comUut1) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open UUT1's COM $gaSet(comDut) fail"
  } else {
    set ret [RLCom::Open $gaSet(comUut2) 9600 8 NONE 1]
    if {$ret!=0} {
      set gaSet(fail) "Open  UUT2's COM $gaSet(comDut) fail"
    }
  }
  return $ret
}
proc ocu {} {OpenComUut}
proc ouc {} {OpenComUut}
proc ccu {} {CloseComUut}
proc cuc {} {CloseComUut}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  catch {RLCom::Close $gaSet(comUut1)}
  catch {RLCom::Close $gaSet(comUut2)}
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  puts "CloseRL ClosePio" ; update
  ClosePio
  CloseComUut
  catch {RLEtxGen::CloseAll}
  catch {RLDxc4::CloseAll}
  catch {RLEH::Close}
}

# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  # parray ::RLUsbPio::description *Ser*
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
#   if {[llength $boxL]!=14} {
#     set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
#     return -1
#   }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet descript
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  foreach rb {1 2} {
    set gaSet(idPwr$rb) [RLUsbPio::Open $rb RBA $channel]
  }
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet
  set ret 0
  foreach rb "1 2" {
	  catch {RLUsbPio::Close $gaSet(idPwr$rb)}
  }
  return $ret
}

# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet  
  set id [open [info host]/init$gaSet(pair).tcl w]
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(entDUT)      \"$gaSet(DutFullName)\""
    puts $id "set gaSet(DutFullName) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
    
  if {![info exists gaSet(Uut2asUut)]} {
    set gaSet(Uut2asUut) 1
  }
  puts $id "set gaSet(Uut2asUut) \"$gaSet(Uut2asUut)\""
  
  close $id   
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}

#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [Send$com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent {expected stamm} {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #puts "sent:<$sent>"
  
  ## replace a few empties by one empty
  regsub -all {[ ]+} $sent " " sent
  
  #puts "sent:<[string trimleft $sent]>"
  ##set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  if {$expected=="stamm"} {
    set cmd [list RLCom::Send $com $sent]
    ##set cmd [list RLCom::Send $com $sent]
    foreach car [split $sent ""] {
      set asc [scan $car %c]
      #puts "car:$car asc:$asc" ; update
      if {[scan $car %c]=="13"} {
        append sentNew "\\r"
      } elseif {[scan $car %c]=="10"} {
        append sentNew "\\n"
      } {
        append sentNew $car
      }
    }
    set sent $sentNew
  
    set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent"
    puts "send: ----------------------------------------\n"
    update
    return $ret
    
  }
  set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  ##set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  if {$gaSet(act)==0} {return -2}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  #puts buffer:<$buffer> ; update
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  regsub -all -- {\[74G}        $b3 " " b3
  set buffer $b3
  
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } elseif {[scan $car %c]=="10"} {
      append sentNew "\\n"
    } {
      append sentNew $car
    }
  }
  set sent $sentNew
  
  #puts "sent:<$sent>"
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=$expected, buffer=$buffer"
    puts "send: ----------------------------------------\n"
    update
  }
  
  #RLTime::Delayms 50
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  $gaSet(runTime) configure -text ""
  update
}


##***************************************************************************
##** Wait
##** 
##** 
##***************************************************************************
proc Wait {txt count {color white}} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	 $gaSet(runTime) configure -text $i
	 RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}


#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}


# ***************************************************************************
# PerfSet
# ***************************************************************************
proc PerfSet {state} {
  global gaSet gaGui
  set gaSet(perfSet) $state
  puts "PerfSet state:$state"
  switch -exact -- $state {
    1 {$gaGui(noSet) configure -relief raised -image [Bitmap::get images/Set] -helptext "Run with the UUTs Setup"}
    0 {$gaGui(noSet) configure -relief sunken -image [Bitmap::get images/noSet] -helptext "Run without the UUTs Setup"}
    swap {
      if {[$gaGui(noSet) cget -relief]=="raised"} {
        PerfSet 0
      } elseif {[$gaGui(noSet) cget -relief]=="sunken"} {
        PerfSet 1
      }
    }  
  }
}
# ***************************************************************************
# MyWaitFor
# ***************************************************************************
proc MyWaitFor {com expected testEach timeout} {
  global buffer gaGui gaSet
  #Status "Waiting for \"$expected\""
  if {$gaSet(act)==0} {return -2}
  puts [MyTime] ; update
  set startTime [clock seconds]
  set runTime 0
  while 1 {
    #set ret [RLCom::Waitfor $com buffer $expected $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    #set ret [Send $com \r stam $testEach]
    #set ret [RLSerial::Waitfor $com buffer stam $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    set ret [Send $com \r stam $testEach]
    foreach expd $expected {
      if [string match *$expd* $buffer] {
        set ret 0
      }
      puts "buffer:__[set buffer]__ expected:\"$expected\" expd:\"$expd\" ret:$ret runTime:$runTime" ; update
#       if {$expd=="PASSWORD"} {
#         ## in old versiond you need a few enters to get the uut respond
#         Send $com \r stam 0.25
#       }
      if [string match *$expd* $buffer] {
        break
      }
    }
    #set ret [Send $com \r $expected $testEach]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    $gaSet(runTime) configure -text $runTime
    #puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
    if {$runTime>$timeout} {break }
    if {$gaSet(act)==0} {set ret -2 ; break}
    update
  }
  puts "[MyTime] ret:$ret runTime:$runTime"
  $gaSet(runTime) configure -text ""
  Status ""
  return $ret
}   
# ***************************************************************************
# Power
# ***************************************************************************
proc Power {ps state} {
  global gaSet gaGui 
  puts "[MyTime] Power $ps $state"
  set ret 0
  switch -exact -- $ps {
    1 - Uut1  {set pioL 1}
    2 - Uut2  {set pioL 2}
    all {set pioL "1 2"}
  } 
  switch -exact -- $state {
    on  {
	    foreach pio $pioL {      
        RLUsbPio::Set $gaSet(idPwr$pio) 1
      }
    } 
	  off {
	    foreach pio $pioL {
	      RLUsbPio::Set $gaSet(idPwr$pio) 0
      }
    }
  }
  Status ""
  return $ret
}

# ***************************************************************************
# GuiPower
# ***************************************************************************
proc GuiPower {n state} { 
  global gaSet descript
  puts "\nGuiPower $n $state"
  RLEH::Open
  RLUsbPio::GetUsbChannels descript
  switch -exact -- $n {
    1 - Uut1 {set portL [list 1]}
    2 - Uut2 {set portL [list 2]}      
    all {set portL [list 1 2]}  
  }        
  set channel [RetriveUsbChannel]
  if {$channel!="-1"} {
    foreach rb $portL {
      set id [RLUsbPio::Open $rb RBA $channel]
      puts "rb:<$rb> id:<$id>"
      RLUsbPio::Set $id $state
      RLUsbPio::Close $id
    }   
  }
  RLEH::Close
} 

#***************************************************************************
#** Wait
#***************************************************************************
proc _Wait {ip_time ip_msg {ip_cmd ""}} {
  global gaSet 
  Status $ip_msg 

  for {set i $ip_time} {$i >= 0} {incr i -1} {       	 
	 if {$ip_cmd!=""} {
      set ret [eval $ip_cmd]
		if {$ret==0} {
		  set ret $i
		  break
		}
	 } elseif {$ip_cmd==""} {	   
	   set ret 0
	 }

	 #user's stop case
	 if {$gaSet(act)==0} {		 
      return -2
	 }
	 
	 RLTime::Delay 1	 
    $gaSet(runTime) configure -text " $i "
	 update	 
  }
  $gaSet(runTime) configure -text ""
  update   
  return $ret  
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
  #set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
  set logFileID [open $gaSet(logFile.$gaSet(pair)) a+] 
    puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# AddToPairLog
# ***************************************************************************
proc AddToPairLog {pair line}  {
  global gaSet
  set logFileID [open $gaSet(log.$pair) a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}
# ***************************************************************************
# ShowLog 
# ***************************************************************************
proc ShowLog {} {
	global gaSet
	#exec notepad tmpFiles/logFile-$gaSet(pair).txt &
#   if {[info exists gaSet(logFile.$gaSet(pair))] && [file exists $gaSet(logFile.$gaSet(pair))]} {
#     exec notepad $gaSet(logFile.$gaSet(pair)) &
#   }
  if {[info exists gaSet(log.$gaSet(pair))] && [file exists $gaSet(log.$gaSet(pair))]} {
    exec notepad $gaSet(log.$gaSet(pair)) &
  }
}

# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}
# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {mode} {
  global gaSet gaGui
  set barcode [set gaSet(entDUT) [string toupper $gaSet(entDUT)]] ; update
  Status "Please wait for retriving DBR's parameters"
  puts "\r[MyTime] GetDbrName $mode $barcode "; update
  
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  wm title . "$gaSet(pair) : "
  after 500
  
  if {![file exist $gaSet(javaLocation)]} {
    set gaSet(fail) "Java application is missing"
    return -1
  }
  catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b
  set fileName MarkNam_$barcode.txt
  after 1000
  if ![file exists MarkNam_$barcode.txt] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  
  #set txt "$barcode $res"
  set txt "[string trim $res]"
  #set gaSet(entDUT) $txt
  set gaSet(entDUT) ""
  puts "GetDbrName <$txt>"
  
  set initName [regsub -all / $res .]
  puts "GetDbrName res:<$res>"
  puts "GetDbrName initName:<$initName>"
  set gaSet(DutFullName) $res
  set gaSet(DutInitName) $initName.tcl
  
  file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  
  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  pack forget $gaGui(frFailStatus)
  #Status ""
  update
  
  focus -force $gaGui(curTest)
  Status "Ready"
  return 0
}

# ***************************************************************************
# DelMarkNam
# ***************************************************************************
proc DelMarkNam {} {
  if {[catch {glob MarkNam*} MNlist]==0} {
    foreach f $MNlist {
      file delete -force $f
    }  
  }
}

# ***************************************************************************
# GetInitFile
# ***************************************************************************
proc GetInitFile {} {
  global gaSet gaGui
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl]
  if {$fil!=""} {
    source $fil
    set gaSet(entDUT) "" ; #$gaSet(DutFullName)
    wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    #UpdateAppsHelpText
    pack forget $gaGui(frFailStatus)
    Status ""
    BuildTests
  }
}
# ***************************************************************************
# UpdateAppsHelpText
# ***************************************************************************
proc UpdateAppsHelpText {} {
  global gaSet gaGui
  #$gaGui(labPlEnPerf) configure -helptext $gaSet(pl)
  #$gaGui(labUafEn) configure -helptext $gaSet(uaf)
  #$gaGui(labUdfEn) configure -helptext $gaSet(udf)
}

# ***************************************************************************
# RetriveDutFam
# RetriveDutFam [regsub -all / ETX-DNFV-M/I7/128S/8R .].tcl
# ***************************************************************************
proc RetriveDutFam {{dutInitName ""}} {
  global gaSet 
  array unset gaSet dut.*
  if {$dutInitName==""} {
    set dutInitName $gaSet(DutInitName)
  }
  puts "RetriveDutFam $dutInitName"
  if {[string match *.B.* $dutInitName]==1} {
    set e1 Bal
  }  elseif {[string match *.U.* $dutInitName]==1} {
    set e1 Unbal
  }
  if {[string match *.ETH.* $dutInitName]==1} {
    set eth ETH
  } else {
    set eth 0
  }
  if {[string match *.SC.* $dutInitName]==1} {
    set optConn SC
  } elseif {[string match *.FC.* $dutInitName]==1} {
    set optConn FC
  } elseif {[string match *.ST.* $dutInitName]==1} {
    set optConn ST
  }
  if {[string match *.13* $dutInitName]==1 || [string match *.13L* $dutInitName]==1 || \
      [string match *.SF1.* $dutInitName]==1 || \
      [string match *.SF4.* $dutInitName]==1} {
    set waveLen  1310nm
  } elseif {[string match *.15* $dutInitName]==1 || [string match *.15L* $dutInitName]==1 || \
      [string match *.SF2.* $dutInitName]==1 || \
      [string match *.SF5.* $dutInitName]==1} {
    set waveLen  1550nm
  }
  if {[string match *.13.* $dutInitName]==1 || [string match *.15.* $dutInitName]==1} {
    set singleMultiMode "Multi mode"
  } else {
    set singleMultiMode "Single mode"
  }
  if {[string match *.13.* $dutInitName]==1 || [string match *.15.* $dutInitName]==1 ||\
      [string match *.13L.* $dutInitName]==1 || [string match *.15L.* $dutInitName]==1 ||\
      [string match *.SF1.* $dutInitName]==1 || [string match *.SF2.* $dutInitName]==1} {
    set haul SH
  } else {
    set haul LH
  }
  
  set gaSet(dut.e1) $e1
  set gaSet(dut.eth) $eth
  set gaSet(dut.optConn) $optConn
  set gaSet(dut.waveLen) $waveLen
  set gaSet(dut.singleMultiMode) $singleMultiMode
  set gaSet(dut.haul) $haul
  
  puts "dutInitName:$dutInitName [parray gaSet dut.*]" ; update
}                               
# ***************************************************************************
# DownloadConfFile
# ***************************************************************************
proc DownloadConfFile {cf cfTxt save com} {
  global gaSet  buffer
  puts "[MyTime] DownloadConfFile $cf \"$cfTxt\" $save $com"
  #set com $gaSet(comDut)
  if ![file exists $cf] {
    set gaSet(fail) "The $cfTxt configuration file ($cf) doesn't exist"
    return -1
  }
  Status "Download Configuration File $cf" ; update
  set s1 [clock seconds]
  set id [open $cf r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {close $id ; return -2}
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      puts "line:<$line>"
      if {[string match {*address*} $line] && [llength $line]==2} {
        if {[string match *DefaultConf* $cfTxt] || [string match *RTR* $cfTxt]} {
          ## don't change address in DefaultConf
        } else {
          ##  address 10.10.10.12/24
          if {$gaSet(pair)==5} {
            set dutIp 10.10.10.1[set ::pair]
          } else {
            if {$gaSet(pair)=="SE"} {
              set dutIp 10.10.10.111
            } else {
              set dutIp 10.10.10.1[set gaSet(pair)]
            }  
          }
          #set dutIp 10.10.10.1[set gaSet(pair)]
          set address [set dutIp]/[lindex [split [lindex $line 1] /] 1]
          set line "address $address"
        }
      }
      if {[string match *EccXT* $cfTxt] || [string match *vvDefaultConf* $cfTxt] || [string match *aAux* $cfTxt]} {
        ## perform the configuration fast (without expected)
        set ret 0
        set buffer bbb
        RLSerial::Send $com "$line\r" 
        ##RLCom::Send $com "$line\r" 
      } else {
        if {[string match *Aux* $cfTxt]} {
          set gaSet(prompt) 205A
        } else {
          set waitFor 2I
        }
        if {[string match {*conf system name*} $line]} {
          set gaSet(prompt) [lindex $line end]
        }
        if {[string match *CUST-LAB-ETX203PLA-1* $line]} {
          set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
        }
        if {[string match *WallGarden_TYPE-5* $line]} {
          set gaSet(prompt) "WallGarden_TYPE-5"          
        }
        if {[string match *BOOTSTRAP-2I10G* $line]} {
          set gaSet(prompt) "BOOTSTRAP-2I10G"          
        }
        set ret [Send $com $line\r $gaSet(prompt) 60]
#         Send $com "$line\r"
#         set ret [MyWaitFor $com {205A 2I ztp} 0.25 60]
      }  
      if {$ret!=0} {
        set gaSet(fail) "Config of DUT failed"
        break
      }
      if {[string match {*cli error*} [string tolower $buffer]]==1} {
        if {[string match {*range overlaps with previous defined*} [string tolower $buffer]]==1} {
          ## skip the error
        } else {
          set gaSet(fail) "CLI Error"
          set ret -1
          break
        }
      }            
    }
  }
  close $id  
  if {$ret==0} {
    if {$com==$gaSet(comAux1) || $com==$gaSet(comAux2)} {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
    } else {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
#       Send $com "exit all\r" 
#       set ret [MyWaitFor $com {205A 2I ztp} 0.25 8]
    }
    if {$save==1} {
      set ret [Send $com "admin save\r" "successfull" 80]
      if {$ret=="-1"} {
        set ret [Send $com "admin save\r" "successfull" 80]
      }
    }
     
    set s2 [clock seconds]
    puts "[expr {$s2-$s1}] sec c:$c" ; update
  }
  Status ""
  puts "[MyTime] Finish DownloadConfFile" ; update
  return $ret 
}
# ***************************************************************************
# Ping
# ***************************************************************************
proc Ping {dutIp} {
  global gaSet
  puts "[MyTime] Pings to $dutIp" ; update
  set i 0
  while {$i<=4} {
    if {$gaSet(act)==0} {return -2}
    incr i
    #------
    catch {exec arp.exe -d}  ;#clear pc arp table
    catch {exec ping.exe $dutIp -n 2} buffer
    if {[info exist buffer]!=1} {
	    set buffer "?"  
    }  
    set ret [regexp {Packets: Sent = 2, Received = 2, Lost = 0 \(0% loss\)} $buffer var]
    puts "ping i:$i ret:$ret buffer:<$buffer>"  ; update
    if {$ret==1} {break}    
    #------
    after 500
  }
  
  if {$ret!=1} {
    puts $buffer ; update
	  set gaSet(fail) "Ping fail"
 	  return -1  
  }
  return 0
}
# ***************************************************************************
# GetMac
# ***************************************************************************
proc GetMac {fi} {
  puts "[MyTime] GetMac $fi" ; update
  set macFile c:/tmp/mac[set fi].txt
  exec $::RadAppsPath/MACServer.exe 0 1 $macFile 1
  set ret [catch {open $macFile r} id]
  if {$ret!=0} {
    set gaSet(fail) "Open Mac File fail"
    return -1
  }
  set buffer [read $id]
  close $id
  file delete $macFile)
  set ret [regexp -all {ERROR} $buffer]
  if {$ret!=0} {
    set gaSet(fail) "MACServer ERROR"
    exec beep.exe
    return -1
  }
  return [lindex $buffer 0]
}
# ***************************************************************************
# SplitString2Paires
# ***************************************************************************
proc SplitString2Paires {str} {
  foreach {f s} [split $str ""] {
    lappend l [set f][set s]
  }
  return $l
}

# ***************************************************************************
# wsplit
# ***************************************************************************
proc wsplit {str sep} {
  split [string map [list $sep \0] $str] \0
}

# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  puts "OpenTeraTerm $comName"
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  if [file exist $path1] {
    set path $path1
  } elseif [file exist $path2] {
    set path $path2  
  } else {
    puts "no teraterm installed"
    return {}
  }
  if {[string match *Uut* $comName]} {
    set baud 9600
  } else {
    set baud 115200
  }
  if {[string match *com* $comName]} {
    exec $path /c=[set $comName] /baud=$baud &
  } else {
    exec $path telnet://10.10.10.${gaSet(pair)}$comName /T=1 &
  }
  return {}
}  

# ***************************************************************************
# TelnetOpen
# ***************************************************************************
proc TelnetOpen {unit} {
  global gaSet
  set ret 0
  if {$unit=="Uut1"} {
    set ip 10.10.10.${gaSet(pair)}1 ;  # 11  or 21
  } elseif {$unit=="Uut2"} {
    set ip 10.10.10.${gaSet(pair)}2 ;  # 12 or 22
  } 
  
  set id [RLPlink::Open $ip -protocol telnet -port 23]
  puts "TelnetOpen $unit $ip $id"
  
  if {[regexp {file\w+} $id]} {
    set gaSet(idTelnet$unit) $id
    return 0
  } else {
    set gaSet(fail) "Open Telnet to $unit fail"
    return -1
  }   
}
# ***************************************************************************
# TelnetClose
# ***************************************************************************
proc TelnetClose {unit} {
  global gaSet
  set cmd {catch {RLPlink::Close $gaSet(idTelnet$unit)}}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  puts "TelnetClose $unit $tt $ret"  
  return 0
}

# ***************************************************************************
# TelnetSend
# ***************************************************************************
proc TelnetSend {unit sent {expected stamm} {timeOut 8}} {
  global gaSet buffer
   if {$gaSet(act)==0} {return -2}
  #puts "TelnetSend $unit $sent $expected $timeOut"
  
  set cmd [list RLPlink::Send $gaSet(idTelnet$unit) $sent buffer $expected $timeOut]
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  regsub -all -- {\[74G}        $b3 " " b3
  set buffer $b3
 
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } elseif {[scan $car %c]=="10"} {
      append sentNew "\\n"
    } elseif {[scan $car %c]=="27"} {
      append sentNew "ESC"
    } else {
      append sentNew $car
    }
  }
  set sent $sentNew
  
  puts "\n[MyTime] TelnetSend: unit:$unit, sent:<$sent>, ret:$ret tt:$tt, expected:<$expected>, buffer:<$buffer>"
  puts "send: ----------------------------------------\n"
  update
  return $ret
}

# ***************************************************************************
# TelnetOSC
# ***************************************************************************
proc TelnetOSC {unit sent {expected stamm} {timeOut 8}} {
  set ret [TelnetOpen $unit]
  if {$ret==0} {
    set ret [TelnetSend $unit $sent $expected $timeOut]
  }
  set retC [TelnetClose $unit]
#   if {$ret==0 && retC==0} {
#     return 0
#   }
  return [expr {$ret + $retC}]
}

# ***************************************************************************
# DxcInLoop
# ***************************************************************************
proc DxcInLoop {loc rem loop} {
  set ret [DxcInLoopRun $loc $rem $loop]
  if {$ret!=0} {return $ret}
  set ret [DxcInLoopInj $loc $rem $loop]
  if {$ret!=0} {
    set ret [DxcInLoopInj $loc $rem $loop]
    if {$ret!=0} {return $ret}
  }
  return $ret
}

# ***************************************************************************
# DxcInLoopRun
# ***************************************************************************
proc DxcInLoopRun {loc rem loop} {
  global gaSet buffer gRes
  puts "[MyTime] DxcInLoopRun $loc $rem $loop"
  
  if {$loc=="Uut1" && $rem=="Uut2"} {
    set dxcGoodPorts {Port1 Port2 Port3 Port4}
    set dxcBadPorts  {Port5 Port6 Port7 Port8}
  } elseif {$loc=="Uut2" && $rem=="Uut1"} {
    set dxcGoodPorts {Port5 Port6 Port7 Port8}
    set dxcBadPorts  {Port1 Port2 Port3 Port4}
  } 
  set uutPorts {Port1 Port2 Port3 Port4}
  
  Dxc4Start
  set ret [Wait "Data is running" 10 white]
  if {$ret!=0} {return $ret}
  #Dxc4Stop
  RLDxc4::GetStatistics $gaSet(idDxc4)  gRes  -statistic bertStatis -port all
  parray gRes  
  foreach dxcPort $dxcGoodPorts uutPort $uutPorts {
    if {$gRes(id$gaSet(idDxc4),syncLoss,$dxcPort)!=0} {
      set gaSet(fail) "$loop of $loc. SyncLoss of DXC-$dxcPort ($loc-$uutPort) is not 0"
      return -1
    }    
  }
  foreach dxcPort $dxcBadPorts uutPort $uutPorts {
    if {$gRes(id$gaSet(idDxc4),syncLoss,$dxcPort)==0} {
      set gaSet(fail) "$loop of $loc. SyncLoss of DXC-$dxcPort ($rem-$uutPort) is 0. Should be more"
      return -1
    }    
  }
  return 0
}  
# ***************************************************************************
# DxcInLoopInj
# ***************************************************************************
proc DxcInLoopInj {loc rem loop} {
  global gaSet buffer gRes
  puts "[MyTime] DxcInLoopIng $loc $rem $loop"
  
  if {$loc=="Uut1" && $rem=="Uut2"} {
    set dxcGoodPorts {Port1 Port2 Port3 Port4}
    set dxcBadPorts  {Port5 Port6 Port7 Port8}
  } elseif {$loc=="Uut2" && $rem=="Uut1"} {
    set dxcGoodPorts {Port5 Port6 Port7 Port8}
    set dxcBadPorts  {Port1 Port2 Port3 Port4}
  } 
  set uutPorts {Port1 Port2 Port3 Port4}  
  Dxc4Start
  RLDxc4::BertInject $gaSet(idDxc4)
  RLTime::Delay 2
  #Dxc4Stop
  RLDxc4::GetStatistics $gaSet(idDxc4)  gRes  -statistic bertStatis -port all
  parray gRes  
  foreach dxcPort $dxcGoodPorts uutPort $uutPorts {
    if {$gRes(id$gaSet(idDxc4),errorBits,$dxcPort)!=1} {
      set gaSet(fail) "$loop of $loc. ErrorBits of DXC-$dxcPort ($loc-$uutPort) is not 1"
      return -1
    }    
  }
  foreach dxcPort $dxcBadPorts uutPort $uutPorts {
    if {$gRes(id$gaSet(idDxc4),errorBits,$dxcPort)!=0} {
      set gaSet(fail) "$loop of $loc. ErrorBits of DXC-$dxcPort ($rem-$uutPort) is not 0"
      return -1
    }    
  }
  return 0
}
# ***************************************************************************
# LoopsOffAll
# ***************************************************************************
proc LoopsOffAll {wai} {
  puts "[MyTime] LoopsOffAll $wai"
  set ret [LoopsOff Uut1]
  if {$ret!=0} {return $ret}
  set ret [LoopsOff Uut2]
  if {$ret!=0} {return $ret}
  set ret [Wait "Waiting for loops off" $wai white]
  if {$ret!=0} {return $ret}
  return $ret
}