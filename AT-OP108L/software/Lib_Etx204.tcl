proc OpenEtxGen {} {
  global gaSet gaEtx204Conf
  set gaSet(idGen1) [RLEtxGen::Open $gaSet(comEtx) -package RLCom] 
  if {[string is integer $gaSet(idGen1)] && $gaSet(idGen1)>0 } {   
    set ret 0
  } else {
    set gaSet(fail) "Open Ethernet Generator fail"
    set ret -1
  }
  if {$ret==0} {
   ## perform the init in the test
    #InitEtxGen 1  
  }
  return $ret 
}

# ***************************************************************************
# ToolsEtxGen
# ***************************************************************************
proc ToolsEtxGen {} {
  global gaSet
  
  foreach gen {1} {
    Status "Opening EtxGen-$gen..."
    set gaSet(idGen$gen) [RLEtxGen::Open $gaSet(comGen$gen) -package RLCom]
    InitEtxGen $gen
  }
  Status Done
  catch {RLEtxGen::CloseAll}
  return 0
} 
# ***************************************************************************
# InitEtxGen
# ***************************************************************************
proc InitEtxGen {gen}  {
  global gaSet
  set id $gaSet(idGen$gen)
  Status "EtxGen-$gen Ports Configuration"
  RLEtxGen::PortsConfig $id -updGen all -autoneg enbl -maxAdvertize 100-f \
      -admStatus up ; #-save yes 
  
  Status "EtxGen-$gen Gen Configuration"
  RLEtxGen::GenConfig $id -updGen all -factory yes -genMode FE -minLen 1518 -maxLen 1518 \
      -chain 1 -packRate 8000 -packType MAC 
   
  Status "EtxGen-$gen Packet Configuration"
#   set sa 000000000001
#   set da 000000000002
#   puts "EtxGen-$gen Packet Configuration  sa:$sa da:$da" 
#   RLEtxGen::PacketConfig $id MAC -updGen all -SA $sa -DA $da
  
  RLEtxGen::PacketConfig $id MAC -updGen 1 -SA 000000000001 -DA 000000000002
  RLEtxGen::PacketConfig $id MAC -updGen 2 -SA 000000000002 -DA 000000000001
  return 0
}

# ***************************************************************************
# Etx204Start
# ***************************************************************************
proc Etx204Start {} {
  global gaSet buffer
  Status "Etx204 Start"
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    puts "Etx204 Start .. [MyTime]" ; update
    RLEtxGen::Start $id 
  }  
  after 500
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Clear $id
  }  
  after 500
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Start $id 
  }  
  after 500
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Clear $id
  }
  return 0
}  

# ***************************************************************************
# Etx204Check
# ***************************************************************************
proc Etx204Check {lGens packRate} {
  global gaSet aRes
  
  set ret 0
  foreach gen {1} {
    puts "Etx204-$gen Check .. [MyTime]" ; update
    set id $gaSet(idGen$gen)    

    RLEtxGen::GetStatistics $id aRes
    if ![info exist aRes] {
      after 2000
      RLEtxGen::GetStatistics $id aRes
      if ![info exist aRes] {
        set gaSet(fail) "Read statistics of ETX204-$gen fail"
        return -1
      }
    }
    set res1 0
    set res2 0
    set res3 0
    set res4 0
  
    foreach port $lGens {
      puts "Generator Port-$port stats:"
      mparray aRes *Gen$port
      #foreach stat {ERR_CNT FRAME_ERR PRBS_ERR SEQ_ERR FRAME_NOT_RECOGN} {}
      foreach stat {ERR_CNT FRAME_ERR PRBS_ERR SEQ_ERR } {
        ## 
        set res $aRes(id$id,[set stat],Gen$port)
        if {$res!=0} {
          set gaSet(fail) "The $stat in ETH Generator Port-$port is $res. Should be 0"
          set res$port -1
          break
        }
      }
      if {[set res$port]!=0} {
        puts "stat:$stat res:$res res$port :<[set res$port]>"
        break
      }
      #puts "1" ; update
      foreach stat {PRBS_OK RCV_BPS RCV_PPS} {
        set res $aRes(id$id,[set stat],Gen$port)
        if {$res==0} {
          set gaSet(fail) "The $stat in ETH Generator Port-$port is 0. Should be more"
          set res$port -1
          break
        }
        if {$stat=="RCV_PPS"} {
          set res0 [set res].0
          set diff [expr abs([expr {$res0-$packRate}])]
          set diffDevRef [expr {$diff/$packRate}]
          set diffDevRefProc [string range [expr {$diffDevRef * 100}] 0 4]
          if {$diffDevRefProc>1} {
            puts "res1:$res1"
            puts "diff:$diff"
            puts "diffDevRefProc:$diffDevRefProc"
            puts "res1:$res1"
            update
            set gaSet(fail) "The $stat in ETH Generator Port-$port is $res. Should be $packRate"
            set res$port -1
            break  
          }
        }
      }
      if {[set res$port]!=0} {
        puts "stat:$stat res:$res res$port :<[set res$port]>"
        break
      }
      #puts "2" ; update
    }
    #puts "3 gaSet(fail):$gaSet(fail)" ; update
    if {$res1!=0 || $res2!=0 || $res3!=0 || $res4!=0} {
      set ret -1
      break
    }
  }  
  
  puts "ret of Etx204Check:<$ret>" 
  return $ret
}

# ***************************************************************************
# Etx204Stop
# ***************************************************************************
proc Etx204Stop {} {
  global gaSet
  puts "Etx204 Stop .. [MyTime]" ; update
  foreach gen {1} {
    set id $gaSet(idGen$gen)
    RLEtxGen::Stop $id
  }
  return 0
}
