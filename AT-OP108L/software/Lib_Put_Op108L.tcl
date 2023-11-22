# ***************************************************************************
# EntryBootMenu
# ***************************************************************************
proc EntryBootMenu {unit} {
  global gaSet buffer
  puts "[MyTime] EntryBootMenu $unit"; update
  set com $gaSet(com$unit)
  set gaSet(fail) "Entry to Boot Menu of $unit fail"
  set ret [Send $com \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  set ret [Send $com \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}

  Power $unit off
  RLTime::Delay 2
  Power $unit on
  RLTime::Delay 2
  Status "Entry to Boot Menu of $unit"
  set ret [Send $com \r "stop auto-boot.." 20]
  if {$ret!=0} {return $ret}
  set ret [Send $com \r\r "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  return 0
}

# ***************************************************************************
# PS_IDTest
# ***************************************************************************
proc IDTest {unit} {
  global gaSet buffer
  Status "ID Test $unit"
  Power all on
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Entry to Inventory of $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret!=0} {return $ret}   
  TelnetSend $unit "\33" "stam" 1
  if {[string match *PASSWORD* $buffer]} {
    set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
  } elseif {[string match *main* $buffer]} {
    set ret [TelnetSend $unit "!" "Utilities"]
  }
  if {$ret!=0} {return $ret}  
  set ret [TelnetSend $unit "1\r" "PS type"]      
  TelnetClose $unit   
  if {$ret!=0} {return $ret} 
  
  set res [regexp {SW version[\s\.]+\(([\d\.]+)\)\s} $buffer ma val ]
  if {$res==0} {
    set gaSet(fail) "Read SW version of $unit fail"
    return -1
  }
  set val [string trim $val]
  puts "SW:<$val>"
  set sw 1.25
  AddToPairLog $gaSet(pair) "SW version: $val"
  if {$val!=$sw} {
    set gaSet(fail) "SW version of $unit is $val. Should be $sw"
    return -1
  }
  
  set res [regexp {HW version[\s\.]+\(([0-9A-Z\.\/]+)\s+Firmware Ver:\s+([\d\.]+)\)\s} $buffer ma val1 val2 ]
  if {$res==0} {
    set gaSet(fail) "Read HW and FW version of $unit fail"
    return -1
  }
  set val1 [string trim $val1]
  set val2 [string trim $val2]
  puts "HW:<$val1> FW:<$val2>"
  AddToPairLog $gaSet(pair) "HW version: $val1"
  AddToPairLog $gaSet(pair) "FW version: $val2"
  set hw "0.1/A"
  if {$val1!=$hw} {
    set gaSet(fail) "HW version of $unit is $val1. Should be $hw"
    return -1
  }
  if {$gaSet(dut.eth)==0} {
    set fw 0.2
  } elseif {$gaSet(dut.eth)=="ETH"} {
    set fw 0.3
  }
  if {$val2!=$fw} {
    set gaSet(fail) "FW version of $unit is $val2. Should be $fw"
    return -1
  }
  
  set res [regexp {Fiber Optic\s+(\w+ mode)\s+([\w\-\/]+)\s+([\d\w]+)\)\s} $buffer ma val1 val2 val3]
  if {$res==0} {
    set gaSet(fail) "Read Fiber Optic details of $unit fail"
    return -1
  }
  set val1 [string trim $val1]
  set val2 [string trim $val2]
  set val3 [string trim $val3]
  puts "SM:<$val1> opt:<$val2> wl:<$val3>"
  AddToPairLog $gaSet(pair) "Fiber Optic: $val1 $val2 $val3"
  if {$val1!=$gaSet(dut.singleMultiMode)} {
    set gaSet(fail) "Fiber Optic of $unit is \'$val1\'. Should be \'$gaSet(dut.singleMultiMode)\'"
    return -1
  }
  
  set optConnHaul "${gaSet(dut.optConn)}-${gaSet(dut.haul)}" 
  puts "optConnHaul:<$optConnHaul>"
  if {$val2!=$optConnHaul} {
    set gaSet(fail) "Fiber Optic of $unit is \'$val2\'. Should be \'$optConnHaul\'"
    return -1
  }
  
  if {$val3!=$gaSet(dut.waveLen) } {
    set gaSet(fail) "Fiber Optic of $unit is \'$val3\'. Should be \'$gaSet(dut.waveLen)\'"
    return -1
  }
  
  
  if {$gaSet(dut.eth)==0} {
    if {[string match {*USER-ETH*} $buffer]} {
      set gaSet(fail) "USER-ETH port exists in $unit"
      return -1
    } else {
      AddToPairLog $gaSet(pair) "No USER-ETH"
    }
  }    
  if {$gaSet(dut.eth)=="ETH"} {
    if {![string match {*USER-ETH*} $buffer]} {
      set gaSet(fail) "USER-ETH port does not exist in $unit"
      return -1
    } else {
      AddToPairLog $gaSet(pair) "USER-ETH exists"
    }  
  }
  
  if {$gaSet(dut.e1)=="Bal"} {
    if {![string match {*Balance(120ohm)*} $buffer]} {
      set gaSet(fail) "E1 in $unit is not Balance(120ohm)"
      return -1
    } else {
      AddToPairLog $gaSet(pair) "E1: Balance(120ohm)"
    }  
  }
  if {$gaSet(dut.e1)=="Unbal"} {
    if {![string match {*Unbalance(75ohm)*} $buffer]} {
      set gaSet(fail) "E1 $unit is not Unbalance(75ohm)"
      return -1
    } else {
      AddToPairLog $gaSet(pair) "Unalance(75ohm)"
    }  
  }
  
  return $ret  
}


# ***************************************************************************
# ReadMac
# ***************************************************************************
proc ReadMac {unit} {
  global gaSet buffer
  Status "Read Mac on $unit"
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  Status "Read Mac on $unit"
  set gaSet(fail) "Read Mac of $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret==0} {   
    TelnetSend $unit "\33" "stam" 1
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
    } elseif {[string match *main* $buffer]} {
      set ret [TelnetSend $unit "!" "Utilities"]
    }
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "3\r" "Layer"]
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "1\r" "Alarms"]
  }
  TelnetClose $unit
  
  set mac1 00-00-00-00-00-00
  set res [regexp {MAC\s+Address\s+\(([\w\-]+)\)} $buffer - mac]
  if {$res==0} {
    set ret -1
    set gaSet(fail) "Read Mac of $unit fail"
    
  }
  if {$ret==0} { 
    set mac1 [join [split $mac -] ""]
    set mac2 0x$mac1
    puts "mac1:$mac1" ; update
    if {($mac2<0x0020D2500000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF )} {
      set gaSet(fail) "The MAC of $unit is $mac"
      set ret -1
    }
    if {$ret==0} { 
      set gaSet($gaSet(pair).mac[string index $unit end]) $mac1
    }
  }
  
  return $ret
}
#***************************************************************************
#**  Login
#***************************************************************************
proc Login {unit} {
  global gaSet buffer gaLocal
  set ret 0
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into $unit"
  
  set com $gaSet(com$unit)
  Send $com \r stam 0.5
  if {[string match *boot* $buffer]} {
    Send $com "@\r" stam 1
  }
  
  set ret [TelnetOpen $unit]
  if {$ret!=0} {return $ret}
  foreach sent {\33 \r \r} {
    TelnetSend $unit $sent stam 0.25
    if {[string match {*main menu*} $buffer]==0} {
      set ret -1  
    } else {
      TelnetClose $unit
      return 0
    }
    if {[string match {*Are you sure?*} $buffer]==1} {
      TelnetSend $unit n\r stam 1
    }    
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit su\r stam 0.5]
      set ret [TelnetSend $unit 1234\r "Utilities"]
      $gaSet(runTime) configure -text ""
      TelnetClose $unit
      return $ret
    }
  }
 
  Status "Login into $unit"
  for {set i 1} {$i <= 30} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    
    puts "Login into $unit i:$i"; update
    if {[expr {$i % 4}]==0} {
      TelnetClose $unit
      after 500
      TelnetOpen $unit
    }
    $gaSet(runTime) configure -text $i; update
    TelnetSend $unit \r\33 stam 2
    
    if {[string match {*PASSWORD*} $buffer]==1} {      
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    if {[string match {*main menu*} $buffer]} {
      puts "if2 <$buffer>"
      set ret 0
      break
    } 
    after 1000
  }
  if {$ret==0} {
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit su\r stam 0.5]
      set ret [TelnetSend $unit 1234\r "Utilities"]
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to $unit fail"
  }
  TelnetClose $unit
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  return $ret
}
# ***************************************************************************
# ReadBootVersion
# ***************************************************************************
proc ReadBootVersion {wdMode} {
  global gaSet buffer
  puts "ReadBootVersion $wdMode"
  set com $gaSet(comDut)
  set ::buff ""
  set gaSet(uutBootVers) ""
  set ret -1
  for {set sec 1} {$sec<20} {incr sec} {
    if {$gaSet(act)==0} {return -2}
    RLSerial::Waitfor $com buffer xxx 1
    ##RLCom::Waitfor $com buffer xxx 1
    puts "sec:$sec buffer:<$buffer>" ; update
    append ::buff $buffer
    if {[string match {*to view available commands*} $::buff]==1 || \
        [string match {*available commands*} $::buff]==1 || \
        [string match {*to view available*} $::buff]==1} {      
      set ret 0
      break
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "Can't read the boot"
    return $ret
  }
  set res [regexp {Boot version:\s([\d\.\(\)]+)\s} $::buff - value]
  if {$res==0} {
    set gaSet(fail) "Can't read the Boot version"
    return -1
  } else {
    set gaSet(uutBootVers) $value
    puts "gaSet(uutBootVers):$gaSet(uutBootVers)"
    set ret 0
  }
  
  if {$wdMode=="wd"} {
    set ret [EntryBootMenu]
    if {$ret!=0} {
      set gaSet(fail) "Can't entry into the boot"
      return $ret
    }
    set ret [Send $com "wd-test\r" "Clock Configuration" 10]
    if {$ret!=0} {
      set gaSet(fail) "WD Test fail. Verify the Dip-Switch position"
      return $ret
    }
  }
  return $ret
}


# ***************************************************************************
# SoftwareDownloadTest
# ***************************************************************************
proc SoftwareDownloadTest {unit} {
  global gaSet buffer 
  puts "\n[MyTime] SoftwareDownloadTest $unit"
  set com $gaSet(com$unit)
  
  Status "Wait for download to image1 / writing to flash of $unit"
  set gaSet(fail) "Application download to $unit fail"
  Send $com "dl\r" "stam" 3
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 60]
  if {$ret!=0} {return $ret}
 
  Status "Wait for download to image0 / writing to flash of $unit"
  set gaSet(fail) "Application download to $unit fail"
  Send $com "dl\r" "stam" 3
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 60]
  if {$ret!=0} {return $ret}
  
  Status "Wait for loading start .."
  set ret [Send $com "@\r" "Loading" 10]
  return $ret
} 

# ***************************************************************************
# SetSWDownload
# ***************************************************************************
proc SetSWDownload {unit} {
  global gaSet buffer
  set com $gaSet(com$unit)
  Status "Set SW Download on $unit"
  
  set ret [EntryBootMenu $unit]
  if {$ret!=0} {return $ret}
  
  set gaSet(SWCF) c:/download/125.img                               
  if {[file exists $gaSet(SWCF)]!=1} {
    set gaSet(fail) "The SW file ($gaSet(SWCF)) doesn't exist"
    return -1
  }
     
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 1000
  }
    
  file copy -force $gaSet(SWCF) c:/download/temp 
  
  # Config Setup:
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup of $unit fail"
    return -1
  }
  Send $com "c\r" "(sn)" 
  Send $com "server\r" "(fn)"
  Send $com "$tail\r" "(ip)"
  Send $com "192.168.205.1\r" "(dm)"
  Send $com "255.255.255.0\r" "(sip)"
  Send $com "10.10.10.10\r" "(g)"
  Send $com "192.168.205.254\r" "(u)"
  Send $com "\r" "(pw)" ;# vxworks
   set ret [Send $com "\r" "(dn)"] 
  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "ftp" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "tftp\r" "115200" ;# 9600
  Send $com "\r" "\[boot\]:"                                                            
  
  return $ret  
}
# ***************************************************************************
# E1Loop
# ***************************************************************************
proc E1Loop {loop unit} {
  global gaSet buffer
  Status "Set E1Loop $loop $unit"
  Power all on
  
  if {$loop=="No loop"} {
    set line 1
  } elseif {$loop=="LLB"} {
    set line 2
  } elseif {$loop=="RLB"} {
    set line 3
  }
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  Status "Set $loop E1 loops on $unit"
  set gaSet(fail) "Set $loop E1 loop of $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret==0} {   
    TelnetSend $unit "\33" "stam" 1
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
    } elseif {[string match *main* $buffer]} {
      set ret [TelnetSend $unit "!" "Utilities"]
    }
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "4\r" "loops"]
  }     
  if {$ret==0} { 
    set ret [TelnetSend $unit "4\r" "Channel 4"]
  }   
  
  set qty [regexp -all "$loop" $buffer]
  puts "E1Loop $unit $loop qty:<$qty>" 
  if {$loop=="No loop" && $qty=="4"} {
    return 0
  }
  
  foreach port {1 2 3 4} {
    if {$ret==0} { 
      set ret [TelnetSend $unit "$port\r" "RLB"]
    }     
    if {$ret==0} { 
      set ret [TelnetSend $unit "$line\r" "Channel 4"]
    }     
    if {$ret==0} {   
      set ret [TelnetSend $unit "s" "Channel 4"] 
      after 500  
    }
    set qty [regexp -all "$loop" $buffer]
    puts "E1Loop $loop $unit port:<$port> qty:<$qty>"
    if {$qty!=$port} {
      if {$ret==0} { 
        set ret [TelnetSend $unit "$port\r" "RLB"]
      }     
      if {$ret==0} { 
        set ret [TelnetSend $unit "1\r" "Channel 4"]
      }     
      if {$ret==0} {   
        set ret [TelnetSend $unit "s" "Channel 4"] 
        after 500  
      }
      if {$ret==0} { 
        set ret [TelnetSend $unit "$port\r" "RLB"]
      }     
      if {$ret==0} { 
        set ret [TelnetSend $unit "$line\r" "Channel 4"]
      }     
      if {$ret==0} {   
        set ret [TelnetSend $unit "s" "Channel 4"] 
        after 500  
      }
    }
    if {$ret!=0} {
      break
    }
  } 

  TelnetClose $unit
  return $ret
}  
# ***************************************************************************
# E1ReLoop
# ***************************************************************************
proc E1ReLoop {loop unit port } {
  global gaSet buffer
  Status "E1 Reclose Loop $loop on port $port $unit"
  Power all on
  
  if {$loop=="None"} {
    set line 1
  } elseif {$loop=="LLB"} {
    set line 2
  } elseif {$loop=="RLB"} {
    set line 3
  }
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  Status "$loop E1 loops on $unit"
  set gaSet(fail) "$loop E1 loop of $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret==0} {   
    TelnetSend $unit "\33" "stam" 1
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
    } elseif {[string match *main* $buffer]} {
      set ret [TelnetSend $unit "!" "Utilities"]
    }
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "4\r" "loops"]
  }     
  if {$ret==0} { 
    set ret [TelnetSend $unit "4\r" "Channel 4"]
  }    
  if {$ret==0} { 
    set ret [TelnetSend $unit "$port\r" "RLB"]
  }     
  if {$ret==0} { 
    set ret [TelnetSend $unit "1\r" "Channel 4"]
  }     
  if {$ret==0} {   
    set ret [TelnetSend $unit "s" "Channel 4"] 
    after 500  
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "$port\r" "RLB"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "$line\r" "Channel 4"]
  }     
  if {$ret==0} {   
    set ret [TelnetSend $unit "s" "Channel 4"] 
    after 500  
  }

  TelnetClose $unit
  return $ret
}  

# ***************************************************************************
# E1TstIndication
# ***************************************************************************
proc E1TstIndication {unit} {
  global gaSet buffer
  Status "E1 Test Indication $unit"
  Power all on
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  Status "E1 Test Indication $unit"
  set gaSet(fail) "Read E1 Test Indication of $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret==0} {   
    TelnetSend $unit "\33" "stam" 1
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
    } elseif {[string match *main* $buffer]} {
      set ret [TelnetSend $unit "!" "Utilities"]
    }
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "3\r" "Layer"]
  }     
  if {$ret==0} { 
    set ret [TelnetSend $unit "2\r" "E1"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "3\r" "Unmasked"]
  }
  if {$ret==0} { 
    foreach port {1 2 3 4} {
      TelnetSend $unit "2\r$port\r" "Unmasked"
      set res [regexp {Operation Status[\s\>]+\((\w+)\)\s} $buffer ma val]
      if {$res==0} {
        set gaSet(fail) "Read Operation Status of Port $port in $unit fail"
        set ret -1
        break
      }
      if {$val!="Testing"} {
        set gaSet(fail) "Operation Status of Port $port in $unit is \'$val\'. Should be \'Testing\'"
        set ret -1
        break
      }
      
      set res [regexp {Test Indication[\s\>]+\((\w+)\)\s} $buffer ma val]
      if {$res==0} {
        set gaSet(fail) "Read Test Indication of Port $port in $unit fail"
        set ret -1
        break
      }
      if {$val!="On"} {
        set gaSet(fail) "Test Indication of Port $port in $unit is \'$val\'. Should be \'On\'"
        set ret -1
        break
      }
    }  
  }
  
  TelnetClose $unit
  return $ret
}
# ***************************************************************************
# LinkTstIndication
# ***************************************************************************
proc LinkTstIndication {loop unit} {
  global gaSet buffer
  Status "Link Test Indication $loop $unit"
  Power all on
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  Status "Link Test Indication $unit"
  set gaSet(fail) "Read Link Test Indication of $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret==0} {   
    set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "3\r" "Layer"]
  }     
  if {$ret==0} { 
    set ret [TelnetSend $unit "2\r" "E1"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "2\r" "Unmasked"]
  }
  if {$ret==0} { 
    if {$loop=="RLB"} {
      set res [regexp {Operation Status[\s\>]+\((\w+)\)\s} $buffer ma val]
      if {$res==0} {
        set gaSet(fail) "Read Operation Status of Link in $unit fail"
        set ret -1      
      }
    
      if {$ret==0} { 
        if {$val!="Testing"} {
          set gaSet(fail) "Operation Status of Link in $unit is \'$val\'. Should be \'Testing\'"
          set ret -1    
        } 
      }
    }
    if {$loop=="LLB"} {
      set res [regexp {Alarm Indication[\s\>]+\((\w+)\)\s} $buffer ma val]
      if {$res==0} {
        set gaSet(fail) "Read Alarm Indication of Link in $unit fail"
        set ret -1      
      }
    
      if {$ret==0} { 
        if {$val!="Loss Of Frame"} {
          set gaSet(fail) "Alarm Indication of Link in $unit is \'$val\'. Should be \'Loss Of Frame\'"
          set ret -1    
        } 
      }
    }
    
    set res [regexp {Test Indication[\s\>]+\((\w+)\)\s} $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read Test Indication of Link in $unit fail"
      set ret -1      
    }
    if {$ret==0} { 
      if {$val!="On"} {
        set gaSet(fail) "Test Indication of Link in $unit is \'$val\'. Should be \'On\'"
        set ret -1    
      } 
    }
  }
  
  TelnetClose $unit
  return $ret
}


# ***************************************************************************
# LoopsOff
# ***************************************************************************
proc LoopsOff {unit} {
  global gaSet buffer
  Status "Loops Off on $unit"
  Power all on
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  Status "Loops Off on $unit"
  set gaSet(fail) "Loops Off on $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret==0} {   
    TelnetSend $unit "\33" "stam" 1
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
    } elseif {[string match *main* $buffer]} {
      set ret [TelnetSend $unit "!" "Utilities"]
    }
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "4\r" "loops"]
  }     
  if {$ret==0} { 
    set ret [TelnetSend $unit "2\r" "RLB"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "1\r" "loops"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "s" "loops"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "5\r" "loops" 20]
  }
  TelnetClose $unit
#   if {$ret==0} {
#     set ret [E1Loop "No loop" $unit]
#   }  
  return $ret
}  
# ***************************************************************************
# UplinkLoop
# ***************************************************************************
proc UplinkLoop {loop unit} {
  global gaSet buffer
  if {$loop=="None"} {
    set line 1
  } elseif {$loop=="LLB"} {
    set line 2
  } elseif {$loop=="RLB"} {
    set line 3
  }
  Status "Set Uplink $loop on $unit"
  Power all on
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  Status "Set Uplink $loop on $unit"
  set gaSet(fail) "Set Uplink $loop on $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret==0} {  
    TelnetSend $unit "\33" "stam" 1
    if {[string match *PASSWORD* $buffer]} {
      set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
    } elseif {[string match *main* $buffer]} {
      set ret [TelnetSend $unit "!" "Utilities"]
    }
  }  
  if {$ret==0} { 
    set ret [TelnetSend $unit "4\r" "loops"]
  }     
#     if {$ret==0} { 
#     set ret [TelnetSend $unit "5\r" "loops" 20]
#   }
  if {$ret==0} { 
    set ret [TelnetSend $unit "2\r" "RLB"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "$line\r" "loops"]
  }
  if {$ret==0} { 
    set ret [TelnetSend $unit "s" "loops"]
  }
  TelnetClose $unit
  return 0
}  
# ***************************************************************************
# FaultPropagationOn
# ***************************************************************************
proc FaultPropagation {state unit} {
  global gaSet buffer
  Status "Set Fault Propagation to $state $unit"
  Power all on
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config FaultPropagation of $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret!=0} {return $ret}   
  TelnetSend $unit "\33" "stam" 1
  if {[string match *PASSWORD* $buffer]} {
    set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
  } elseif {[string match *main* $buffer]} {
    set ret [TelnetSend $unit "!" "Utilities"]
  }
  if {$ret==0} {  
    set ret [TelnetSend $unit "2\r" "Layer"]
  }    
  if {$ret==0} {  
    set ret [TelnetSend $unit "2\r" "Defaults"]
  }   
  if {$ret==0} { 
    set res [regexp {Fault Propagation\s+\((\w+)\)\s} $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read Fault Propagation of $unit fail"
      set ret -1
    }  
    if {$ret==0 && $val!="$state"} { 
      TelnetSend $unit "4\r" "Defaults"
      TelnetSend $unit "s" "Defaults"
    }
  }
  TelnetClose $unit   
  return $ret 
}
# ***************************************************************************
# ChangeIp
# ***************************************************************************
proc ChangeIp {unit} {
  global gaSet buffer
  Status "Change Ip in $unit"
  Power all on
  set ret [Login $unit]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Change Ip in $unit fail"
  set ret [TelnetOpen $unit]
  if {$ret!=0} {return $ret}   
  TelnetSend $unit "\33" "stam" 1
  if {[string match *PASSWORD* $buffer]} {
    set ret [TelnetSend $unit "su\r1234\r" "Utilities"]
  } elseif {[string match *main* $buffer]} {
    set ret [TelnetSend $unit "!" "Utilities"]
  }
  if {$ret==0} {  
    set ret [TelnetSend $unit "2\r" "Layer"]
  }    
  if {$ret==0} {  
    set ret [TelnetSend $unit "1\r" "Gateway"]
  } 
  if {$ret==0} {  
    set ret [TelnetSend $unit "1\r123.123.123.$gaSet(pair)[string index $unit end]\r" "Gateway"]
  }
  if {$ret==0} {  
    TelnetSend $unit "s" "stam" 0.5
  }
  TelnetClose $unit   
  return $ret 
}
# ***************************************************************************
# NoTelnet
# ***************************************************************************
proc NoTelnet {unit} {
  global gaSet buffer
  Status "No Telnet to $unit"
  Power all on
  set ret [TelnetOpen $unit]
  if {$ret==0} {
    TelnetSend $unit \r\33 stam 0.5
    if [string length $buffer] {
      set gaSet(fail) "IP of $unit does not changed"
      set ret -1
    } else {
      set ret 0
    } 
  }
  TelnetClose $unit   
  return $ret 
}