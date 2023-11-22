# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName)\n"
  
  RetriveDutFam 
    
  set lTestsAllTests [list SoftwareDownload1]
  if $gaSet(Uut2asUut) {
    lappend lTestsAllTests SoftwareDownload2
  }
  
  lappend lTestsAllTests ID1
  if $gaSet(Uut2asUut) {
    lappend lTestsAllTests ID2
  }
  
  lappend lTestsAllTests DataTransmission
  
  lappend lTestsAllTests E1LocalLoop1
  if $gaSet(Uut2asUut) {
    lappend lTestsAllTests E1LocalLoop2
  }
  
  lappend lTestsAllTests UplinkLocalLoop1
  if $gaSet(Uut2asUut) {
    lappend lTestsAllTests UplinkLocalLoop2
  }
  
  lappend lTestsAllTests E1RemoteLoop1
  if $gaSet(Uut2asUut) {
    lappend lTestsAllTests E1RemoteLoop2
  }
  
  lappend lTestsAllTests UplinkRemoteLoop1
  if $gaSet(Uut2asUut) {
    lappend lTestsAllTests UplinkRemoteLoop2
  }
  
  if {[string match *.ETH.* $gaSet(DutInitName)]==1} {
    lappend lTestsAllTests FaultPropagation1
    if $gaSet(Uut2asUut) {
      lappend lTestsAllTests FaultPropagation2
    }
  }
  
  lappend lTestsAllTests SetDefButton  
  
  lappend lTestsAllTests Leds
  
  lappend lTestsAllTests Mac_BarCode
  
  
  set glTests ""
  
  for {set i 0; set k 1} {$i<[llength $lTestsAllTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTestsAllTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
}
# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* Test start *********..[MyTime].."
  Status "Test start"
  set gaSet(curTest) ""
  update
    
#   AddToLog "********* DUT start *********"
  AddToPairLog $gaSet(pair) "********* Test start *********"
#   if {$gaSet(dutBox)!="DNFV"} {
#     AddToLog "$gaSet(1.barcode1)"
#   }     
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
#     AddToLog "Test \'$testName\' started"
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n[MyTime] **** Test $numberedTest finish;  ret of $numberedTest is: $ret;\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }

  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
  return $ret
}

# ***************************************************************************
# ID1
# ***************************************************************************
proc ID1 {run} {
  global gaSet
  Power all on
  set ret [IDTest Uut1]
  if {$ret!=0} {return $ret}
  set ret [ReadMac Uut1]
  return $ret
}
# ***************************************************************************
# ID2
# ***************************************************************************
proc ID2 {run} {
  global gaSet
  Power all on
  set ret [IDTest Uut2]
  if {$ret!=0} {return $ret}
  set ret [ReadMac Uut2]
  return $ret
}
# ***************************************************************************
# DataTransmission
# ***************************************************************************
proc DataTransmission {run} {
  global gaSet gRelayState
  
  set ret [LoopsOffAll 1]
  if {$ret!=0} {return $ret}
  
  if {$gaSet(dut.eth)=="ETH"} {
    Status "Init GENERATOR"
    InitEtxGen 1
    #Status "EtxGen Gen Configuration"
  }
  SetDxc4
  
  set ret [Wait "Waiting for stabilization" 10 white]
  if {$ret!=0} {return $ret}
  
  
  set ret [DataTransmissionTestPerf 10]  
  if {$ret!=0} {
    set ret [DataTransmissionTestPerf 10]  
    if {$ret!=0} {return $ret} 
  } 
  
  set ret [DataTransmissionTestPerf 60]  

  return $ret
}
# ***************************************************************************
# DataTransmissionTestPerf
# ***************************************************************************
proc DataTransmissionTestPerf {checkTime} {
  global gaSet
  puts "[MyTime] DataTransmissionTestPerf $checkTime"
  Power all on 
  
  
  if {$gaSet(dut.eth)=="ETH"} {
    Etx204Start
  }
  
  Dxc4Start
  
  set ret [Wait "Data is running" $checkTime white]
  if {$ret!=0} {return $ret}
  
  if {$gaSet(dut.eth)=="ETH"} {
    set ret [Etx204Check "1 2" 8000]
    if {$ret!=0} {return $ret}
  }
  
  set ret [Dxc4Check [list 1 2 3 4 5 6 7 8]]
  if {$ret!=0} {return $ret}
  
  return $ret
}  


# ***************************************************************************
# SoftwareDownload
# ***************************************************************************
proc SoftwareDownload1 {run} {
  set ret [SetSWDownload Uut1]
  if {$ret!=0} {return $ret}
  set ret [SoftwareDownloadTest Uut1]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# SoftwareDownload2
# ***************************************************************************
proc SoftwareDownload2 {run} {
  set ret [SetSWDownload Uut2]
  if {$ret!=0} {return $ret}
  set ret [SoftwareDownloadTest Uut2]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# E1LocalLoop1
# ***************************************************************************
proc E1LocalLoop1 {run} {
  global gaSet gRes
  set loc Uut1
  set rem Uut2
  set ret [E1LocalLoopPerf $loc $rem]
}  
# ***************************************************************************
# E1LocalLoop2
# ***************************************************************************

proc E1LocalLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1
  set ret [E1LocalLoopPerf $loc $rem]
}  
# ***************************************************************************
# E1LocalLoopPerf
# ***************************************************************************
proc E1LocalLoopPerf {loc rem} {
  global gaSet
  set ret [LoopsOffAll 5]
  if {$ret!=0} {return $ret}
  
  set ret [E1Loop LLB $loc]
  if {$ret!=0} {return $ret}
    
  set ret [DxcInLoop $loc $rem "E1 LLB"]
  if {$ret!=0} {return $ret}
  
  set ret [E1TstIndication $loc]
  
  return $ret
}
proc neE1LocalLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1   
  set ret [LoopsOff $loc]
  if {$ret!=0} {return $ret}
  set ret [LoopsOff $rem]
  if {$ret!=0} {return $ret}
  
  set ret [E1Loop LLB $loc]
  if {$ret!=0} {return $ret}
    
  set ret [DxcInLoop $loc $rem "E1 LLB"]
  if {$ret!=0} {return $ret}
  
  set ret [E1TstIndication $loc]
  
  return $ret
}
# ***************************************************************************
# UplinkLocalLoop1
# ***************************************************************************
proc UplinkLocalLoop1 {run} {
  global gaSet gRes
  set loc Uut1
  set rem Uut2
  set ret [UplinkLocalLoopPerf $loc $rem]
} 
# ***************************************************************************
# UplinkLocalLoop2
# ***************************************************************************
proc UplinkLocalLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1
  set ret [UplinkLocalLoopPerf $loc $rem]
}  
 
# ***************************************************************************
# UplinkLocalLoopPerf
# ***************************************************************************
proc UplinkLocalLoopPerf {loc rem} {
  global gaSet
  set ret [LoopsOffAll 5]
  if {$ret!=0} {return $ret}
  
  set ret [UplinkLoop LLB $loc]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Waiting for stabilization in loop" 5 white]
  if {$ret!=0} {return $ret}
    
  set ret [DxcInLoop $loc $rem "Uplink LLB"]
  if {$ret!=0} {return $ret}
  
  set ret [LinkTstIndication UplinkLocal $loc]
  
  return $ret
}
# ***************************************************************************
# UplinkLocalLoop2
# ***************************************************************************
proc neUplinkLocalLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1
  set ret [LoopsOff $loc]
  if {$ret!=0} {return $ret}
  set ret [LoopsOff $rem]
  if {$ret!=0} {return $ret}
  
  set ret [UplinkLoop LLB $loc]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Waiting for stabilization in loop" 5 white]
  if {$ret!=0} {return $ret}
    
  set ret [DxcInLoop $loc $rem "Uplink LLB"]
  if {$ret!=0} {return $ret}
  
  set ret [LinkTstIndication UplinkLocal $loc]
  
  return $ret
}
# ***************************************************************************
# E1RemoteLoop1
# ***************************************************************************
proc E1RemoteLoop1 {run} {
  global gaSet gRes
  set loc Uut1
  set rem Uut2
  set ret [E1RemoteLoopPerf $loc $rem]
}
# ***************************************************************************
# E1RemoteLoop2
# ***************************************************************************
proc E1RemoteLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1
  set ret [E1RemoteLoopPerf $loc $rem]
}
# ***************************************************************************
# E1RemoteLoopPerf
# ***************************************************************************
proc E1RemoteLoopPerf {loc rem} {      
  global gaSet
  set ret [LoopsOffAll 5]
  if {$ret!=0} {return $ret}
  
  set ret [E1Loop RLB $loc]
  if {$ret!=0} {return $ret}
  
  set ret [E1TstIndication $rem]
  if {$ret!=0} {
    regexp {Port (\d)} $gaSet(fail) ma port
    set ret [E1ReLoop RLB $loc $port]
    if {$ret!=0} {return $ret}
  }
  set ret [E1TstIndication $rem]
  if {$ret!=0} {
    regexp {Port (\d)} $gaSet(fail) ma port
    set ret [E1ReLoop RLB $loc $port]
    if {$ret!=0} {return $ret}
  }
  set ret [E1TstIndication $rem]
  if {$ret!=0} {
    regexp {Port (\d)} $gaSet(fail) ma port
    set ret [E1ReLoop RLB $loc $port]
    if {$ret!=0} {return $ret}
  }
  set ret [E1TstIndication $rem]
  if {$ret!=0} {
    regexp {Port (\d)} $gaSet(fail) ma port
    set ret [E1ReLoop RLB $loc $port]
    if {$ret!=0} {return $ret}
  }
  set ret [E1TstIndication $rem]
  if {$ret!=0} {return $ret}
  
  
  set ret [DxcInLoop $loc $rem "E1 RLB"]
  if {$ret!=0} {return $ret}  
  
  return $ret
}

proc neE1RemoteLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1
  set ret [LoopsOff $loc]
  if {$ret!=0} {return $ret}
  set ret [LoopsOff $rem]
  if {$ret!=0} {return $ret}
  
  set ret [E1Loop RLB $loc]
  if {$ret!=0} {return $ret}
  
  set ret [E1TstIndication $rem]
  if {$ret!=0} {
    regexp {Port (\d)} $gaSet(fail) ma port
    set ret [E1ReLoop RLB $loc $port]
    if {$ret!=0} {return $ret}
  }
  set ret [E1TstIndication $rem]
  if {$ret!=0} {return $ret}
  
    
  set ret [DxcInLoop $loc $rem "E1 RLB"]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# UplinkRemoteLoop1
# ***************************************************************************
proc UplinkRemoteLoop1 {run} {
  global gaSet gRes
  set loc Uut1
  set rem Uut2
  set ret [UplinkRemoteLoopPerf $loc $rem]
}
# ***************************************************************************
# UplinkRemoteLoop2
# ***************************************************************************
proc UplinkRemoteLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1
  set ret [UplinkRemoteLoopPerf $loc $rem]
}
# ***************************************************************************
# UplinkRemoteLoopPerf
# ***************************************************************************
proc UplinkRemoteLoopPerf {loc rem} { 
  global gaSet
  set ret [LoopsOffAll 5]
  if {$ret!=0} {return $ret}
  
  set ret [UplinkLoop RLB $loc]
  if {$ret!=0} {return $ret}
  
  set ret [LinkTstIndication RLB $rem]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Waiting for stabilization in loop" 5 white]
  if {$ret!=0} {return $ret}
    
  set ret [DxcInLoop $loc $rem "Uplink RLB"]
  if {$ret!=0} {return $ret}
  
  return $ret
}
proc neUplinkRemoteLoop2 {run} {
  global gaSet gRes
  set loc Uut2
  set rem Uut1
  set ret [LoopsOff $loc]
  if {$ret!=0} {return $ret}
  set ret [LoopsOff $rem]
  if {$ret!=0} {return $ret}
  
  
  set ret [UplinkLoop RLB $loc]
  if {$ret!=0} {return $ret}
  
  set ret [LinkTstIndication RLB $rem]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Waiting for stabilization in loop" 5 white]
  if {$ret!=0} {return $ret}
    
  set ret [DxcInLoop $loc $rem "Uplink RLB"]
  if {$ret!=0} {return $ret}
  
  #set ret [LinkTstIndication RLB $rem]
  
  return $ret
}

# ***************************************************************************
# FaultPropagation1
# ***************************************************************************
proc FaultPropagation1 {run} {
  global gaSet aRes
  set ethPort 1
  set psOff   2
  set unit   Uut1
  set ret [FaultPropagationPerf $unit $ethPort $psOff]
  return $ret
}  
# ***************************************************************************
# FaultPropagation2
# ***************************************************************************
proc FaultPropagation2 {run} {
  global gaSet aRes
  set ethPort 2
  set psOff   1
  set unit   Uut2
  set ret [FaultPropagationPerf $unit $ethPort $psOff]
  return $ret
}
# ***************************************************************************
# FaultPropagationPerf
# ***************************************************************************
proc FaultPropagationPerf {unit port psOff} {
  global gaSet aRes
  Power all on
  Status "Init GENERATOR"
  InitEtxGen 1
  set ret [FaultPropagation Off $unit]
  if {$ret!=0} {return $ret}
  set ret [FaultPropagation On $unit]
  if {$ret!=0} {return $ret}
  
  Status "Read Statistics on Eth Gen Port $port"  
  set secStart [clock seconds]
  while 1 {
    set nowSec [clock seconds]
    set runSec [expr {$nowSec-$secStart}]
    if {$runSec>60} {
      set ret -1
      break
    }
    RLEtxGen::GetStatistics $gaSet(idGen1) aRes
    set res $aRes(id$gaSet(idGen1),SPEED,Gen$port)
    puts "[MyTime] $runSec sec, $res"
    if {$res=="100-TFD"} {
      set ret 0
      break
    }
    after 3000
  }
  
  Power $psOff off
  set ret [Wait "Wait for Fault Propagation" 5 white]
  if {$ret!=0} {return $ret}
  
  Status "Read Statistics on Eth Gen Port $port"  
  set secStart [clock seconds]
  while 1 {
    set nowSec [clock seconds]
    set runSec [expr {$nowSec-$secStart}]
    if {$runSec>60} {
      set ret -1
      break
    }
    RLEtxGen::GetStatistics $gaSet(idGen1) aRes
    set res $aRes(id$gaSet(idGen1),SPEED,Gen$port)
    puts "[MyTime] $runSec sec, $res"
    if {$res=="10-THD"} {
      set ret 0
      break
    }
  }  
  if {$res!="10-THD"} {
    set ret -1
    set gaSet(fail) "$unit. The SPEED of Eth Gen Port $port is \'$res\'. Should be \'10-THD\'"
  }
  
  return $ret
}
# ***************************************************************************
# FaultPropagation2
# ***************************************************************************
proc neFaultPropagation2 {run} {
  global gaSet aRes
  Power all on
  Status "Init GENERATOR"
  InitEtxGen 1
  set unit Uut2
  set ret [FaultPropagation Off $unit]
  if {$ret!=0} {return $ret}
  set ret [FaultPropagation On $unit]
  if {$ret!=0} {return $ret}
  
  set port 2
  Status "Read Statistics on Eth Gen Port $port"  
  while 1 {
    RLEtxGen::GetStatistics $gaSet(idGen1) aRes
    set res $aRes(id$gaSet(idGen1),SPEED,Gen$port)
    puts "[MyTime] $res"
    if {$res=="100-TFD"} {
      set ret 0
      break
    }
    after 3000
  }
  
  Power 1 off
  set ret [Wait "Wait for Fault Propagation" 5 white]
  if {$ret!=0} {return $ret}
  
  Status "Read Statistics on Eth Gen Port $port"  
  
  set secStart [clock seconds]
  while 1 {
    set nowSec [clock seconds]
    if {[expr {$nowSec-$secStart}]>60} {
      set ret -1
      break
    }
    RLEtxGen::GetStatistics $gaSet(idGen1) aRes
    set res $aRes(id$gaSet(idGen1),SPEED,Gen$port)
    puts "[MyTime] $res"
    if {$res=="10-THD"} {
      set ret 0
      break
    }
  }  
  if {$res!="10-THD"} {
    set ret -1
    set gaSet(fail) "$unit. The SPEED of Eth Gen Port $port is \'$res\'. Should be \'10-THD\'"
  }
  
  return $ret
}
# ***************************************************************************
# SetDefButton
# ***************************************************************************
proc SetDefButton {run} {
  global gaSet
  
  set ret [ChangeIp Uut1]
  if {$ret!=0} {return $ret}
  
  if $gaSet(Uut2asUut) {
    set ret [ChangeIp Uut2]
    if {$ret!=0} {return $ret}
  }
  
  set ret [NoTelnet Uut1] 
  if {$ret!=0} {return $ret}
  
  if $gaSet(Uut2asUut) {
    set ret [NoTelnet Uut2]
    if {$ret!=0} {return $ret}
  } 
  
  set txt "Press on Set.Def Push Button on Uut1"
  if $gaSet(Uut2asUut) {
    append txt " and Uut2"
  } 
  RLSound::Play information
  set res [DialogBox -type "Ok Stop" -icon /images/info -title "SetDef Button"  -message $txt]
  if {$res=="Stop"} {
    return -2
  }
  set ret [Login Uut1]
  if {$ret!=0} {return $ret}
  
  if $gaSet(Uut2asUut) {
    set ret [Login Uut2]
    if {$ret!=0} {return $ret}
  }
  return $ret
}
# ***************************************************************************
# Leds
# ***************************************************************************
proc Leds {run} {
  global gaSet
  
  if {$gaSet(dut.eth)=="ETH"} {
    RLEtxGen::PortsConfig $gaSet(idGen1) -updGen all -admStatus up
  }
  
  set txt "Verify on Uut1"
  if $gaSet(Uut2asUut) {
    append txt " and Uut2"
  } 
  append txt ":\n\n"
  if {$gaSet(dut.eth)=="ETH"} {
    append txt "USER-ETH LED 100 Light Green and LINK Blinking Yellow\n"
  }  
  append txt "MNG-ETH LED 100 Light Green and LINK Light Yellow"
  append txt "\n\nAre the LEDs light correctly?"
  RLSound::Play information
  set res [DialogBox -type "Yes No" -icon /images/info -title "LEDs Test"  -message $txt]
  if {$res=="No"} {
    set fail "Led Test of Uut1"
    if $gaSet(Uut2asUut) {
      append fail " and Uut2"
    }
    append fail " fail"
    set gaSet(fail) $fail
    return -1
  }
  
  set txt ""
  set txt0 "Press OK and after appr. 20-30 seconds verify on Uut1"
  if $gaSet(Uut2asUut) {
    append txt0 " and Uut2"
  } 
  set txt1 ":\n\n\
  Channels LEDs: Blinking (Red + Yellow)\n\
  Link Interface LED: Blinking (Red + Yellow)\n\
  PWR LED: Light Green\n\
  SD LED (on back panel): Light Green"
  append txt $txt0 $txt1
  RLSound::Play information
  set res [DialogBox -type "Ok Stop" -icon /images/info -title "LEDs Test"  -message $txt]
  if {$res=="Stop"} {
    return -2
  }
  
  set txt ""
  set txt0 "Verify on Uut1"
  if $gaSet(Uut2asUut) {
    append txt0 " and Uut2"
  }
  append txt $txt0 $txt1
  append txt "\n\nAre the LEDs light correctly?"
  while 1 {
    Power all off
    after 2000
    Power all on
    RLSound::Play information
     
    set res [DialogBox -type "Yes No Repeat" -icon /images/question -title "LEDs Test"  -message $txt]
    if {$res=="No"} {
      set fail "Led Test of Uut1"
      if $gaSet(Uut2asUut) {
        append fail " and Uut2"
      }
      append fail " fail"
      set gaSet(fail) $fail
      return -1
    }
    if {$res=="Yes"} {
      set ret 0
      break
    }
  }
  return $ret  
}
# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  global gaSet  
  set pair $gaSet(pair) 
  puts "Mac_BarCode \"$pair\" "
  mparray gaSet *mac* ; update
  mparray gaSet *barcode* ; update
  set badL [list]
  set ret -1
  
  set unit Uut1
  if ![info exists gaSet($pair.mac[string index $unit end])] {
    set ret [ReadMac $unit]
    if {$ret!=0} {return $ret}
  } 
  if $gaSet(Uut2asUut) {
    set unit Uut2
    if ![info exists gaSet($pair.mac[string index $unit end])] {
      set ret [ReadMac $unit]
      if {$ret!=0} {return $ret}
    }
  }
  if {![info exists gaSet($pair.barcode1)] || $gaSet($pair.barcode1)=="skipped" ||\
      ![info exists gaSet($pair.barcode2)] || $gaSet($pair.barcode2)=="skipped"}  {
     set ret [ReadBarcode]
     if {$ret!=0} {
       return $ret
     }
  }  
 
  set ret [RegBC]
      
  return $ret
}
