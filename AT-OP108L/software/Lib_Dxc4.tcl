proc ToolsDxc4 {} {
  global gaSet
  set gaSet(idDxc4)  [RLDxc4::Open $gaSet(comDxc) -package RLCom -config default]
 	catch {RLDxc4::CloseAll}
  puts "[MyTime] ToolsDxc4" ; update
  return 0
}
# ***************************************************************************
# OpenDxc4
# ***************************************************************************
proc OpenDxc4 {} {
  global gaSet
  catch {RLDxc4::CloseAll}
  after 100
  set gaSet(idDxc4)  [RLDxc4::Open $gaSet(comDxc) -package RLCom ]; #-config default
 	if {[string is integer $gaSet(idDxc4)] && $gaSet(idDxc4)>0} {   
    set ret 0
  } else {
    set ret -1
  }
  puts "[MyTime] OpenDxc4 ret:$ret" ; update
  return $ret
}

# ***************************************************************************
# SetDxc4
# ***************************************************************************
proc SetDxc4 {} {
	global gaSet
  Status "Set DXC4"
   
  set bal "yes"
  set gaSet(frameType) E1
	RLDxc4::Stop  $gaSet(idDxc4)  bert
	RLDxc4::SysConfig $gaSet(idDxc4) -srcClk int
	RLDxc4::PortConfig $gaSet(idDxc4) $gaSet(frameType) -updPort all -frameE1 unframe\
                        -intfE1 dsu -lineCodeE1 hdb3 -balanced $bal -idleCode 7C
  RLDxc4::BertConfig $gaSet(idDxc4) -updPort all -linkType $gaSet(frameType) -enabledBerts  all\
  	                   -pattern 2e15 -tsAssignm unframe -inserrRate single  -inserrBerts all
  
  return 0
}

# ***************************************************************************
# Dxc4Start
# ***************************************************************************
proc Dxc4Start {} {
  global gaSet
  Status "Dxc4 Start"
  RLDxc4::Start  $gaSet(idDxc4)  bert
  RLTime::Delay 2
  RLDxc4::Clear  $gaSet(idDxc4)  bert all 
  RLTime::Delay 1
  RLDxc4::Clear  $gaSet(idDxc4)  bert all 
}
# ***************************************************************************
# Dxc4InjErr
# ***************************************************************************
proc Dxc4InjErr {} {
  global gaSet gRes
  Status "Dxc4 Inject Errors"
  foreach dxc4Num {idDxc4-1 idDxc4-2} {   	
   	RLDxc4::BertInject $gaSet($dxc4Num)
   	RLTime::Delay 1
   	RLDxc4::BertInject $gaSet($dxc4Num)
   	RLTime::Delay 1
  }
  foreach dxc4Num {idDxc4-1 idDxc4-2} d {DXC-1 DXC-2} {
    for {set i 1} {$i <= 4} {incr i 1} {
      if {$i == 2} {
        ## ???? continue 
      }
      RLDxc4::GetStatistics $gaSet($dxc4Num)  gRes  -statistic bertStatis -port $i
     	parray gRes
    	if {$gRes(id$gaSet($dxc4Num),errorSec,Port$i) != 2 || $gRes(id$gaSet($dxc4Num),errorBits,Port$i) != 2} {
        #RLDxc4::Stop  $gaSet(idDxc4-1)  bert
        #RLDxc4::Stop  $gaSet(idDxc4-2)  bert
        set gaSet(fail) "$d port $i - Inject Error Failed"
    		return -1
    	}
      RLDxc4::Clear  $gaSet($dxc4Num)  bert $i
      if {$gaSet(dutFam)!="f35"} {
        break
      }
    }
  }
  return 0
}
# ***************************************************************************
# Dxc4Check
# ***************************************************************************
proc Dxc4Check {portL} {
  global gaSet gRes  
  Status "DXC Check $portL" ; update
  foreach port $portL {
    Status "DXC Check $port" ; update
    RLDxc4::GetStatistics $gaSet(idDxc4)  gRes  -statistic bertStatis -port $port
    parray gRes
  	if {$gRes(id$gaSet(idDxc4),syncLoss,Port$port) || \
        $gRes(id$gaSet(idDxc4),errorSec,Port$port) || \
        $gRes(id$gaSet(idDxc4),errorBits,Port$port)} {
      set gaSet(fail) "DXC port $port - Data Test Failed"
  		return -1
  	}
    puts ""    
  }

  return 0
}
# ***************************************************************************
# Dxc4Stop
# ***************************************************************************
proc Dxc4Stop {} {
  global gaSet
  puts "[MyTime] Dxc4Stop"
  RLDxc4::Stop  $gaSet(idDxc4)  bert
}
