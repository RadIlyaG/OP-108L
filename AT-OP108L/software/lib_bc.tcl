#***************************************************************************
#** DialogBoxEnt
#** 
#** For icon option in [pwd] must be gif file with name like icon.  
#**   error.gif for icon 'error'
#**   stop.gif  for icon 'stop'
#**
#** Input parameters:
#**   -title   Specifies a string to display as the title of the message box. 
#**            The default value is an empty string. 
#**   -text    Specifies the message to display in this message box.  
#**            The default value is an empty string. 
#**   -icon    Specifies an icon to display.
#**            If this option is not specified, then no icon will be displayed. 
#**   -type    Arranges for a predefined set of buttons to be displayed.
#**            The default value is 'ok' button.
#**   -parent  Makes window the logical parent of the message box. 
#**            The message box is displayed on top of its parent window.
#**            The default value is window '.'
#**   -aspect  Specifies a non-negative integer value indicating desired 
#**            aspect ratio for the text.
#**            The aspect ratio is specified as 100*width/height.
#**            100 means the text should be as wide as it is tall, 
#**            200 means the text should be twice as wide as it is tall, 
#**            50 means the text should be twice as tall as it is wide, and so on.
#**            Used to choose line length for text if width option isn't specified. 
#**            Defaults to 150. 
#**   -default Name gives the symbolic name of the default button 
#**            for this message window ('ok', 'cancel', and so on). 
#**            If the message box has just one button it will automatically 
#**            be made the default, otherwise if this option is not specified,
#**            there won't be any default button. 
#**
#** Return value: name of the pressed button
#** Example:
#**   DialogBox
#**   DialogBox -icon error -type "ok yes TCL" -text "Move the Cables"
#***************************************************************************
proc DialogBoxEnt {args} {

  # each option & default value
  foreach {opt def} {title "DialogBoxE" text "" icon "" type ok \
                     parent . aspect 2000 default 0 entVar ""} {
    set var$opt [Opte $args "-$opt" $def]
  }
  wm deiconify $varparent
  set lOptions [list -parent $varparent -modal local -separator 0 \
      -title $vartitle -side bottom -anchor c -default $vardefault -cancel 1]

  if {[catch {Bitmap::get [pwd]\\$varicon.gif} img] == 0} {
    set lOptions [concat $lOptions "-image $img"]
  }

  #create Dialog
  set dlg [eval Dialog .tmpldlg $lOptions]

  #create Buttons
  foreach but $vartype {
    $dlg add -text $but -name $but -command [list Dialog::enddialog $dlg $but]
  }

  #create message
  set msg [message [$dlg getframe].msg -text $vartext -justify center \
     -anchor c -aspect $varaspect]  
  pack $msg -fill both -expand 1 -padx 10 -pady 3

  if {$varentVar!=""} {
    set ent [Entry [$dlg getframe].ent -justify center]
    pack  $ent
	 focus $ent
  }

  set ret [$dlg draw]
  if {$varentVar!=""} {
    set entryString  [$ent cget -text]
	  set ::$varentVar $entryString
  }
  destroy $dlg
  return $ret
}



#***************************************************************************
#** Opte
#***************************************************************************
proc Opte {lOpt opt def} {
  set tit [lsearch $lOpt $opt]
  if {$tit != "-1"} {
    set title [lindex $lOpt [incr tit]]
  } else {
    set title $def
  }
  return $title
} 

# ***************************************************************************
# RegBC
# ***************************************************************************
proc RegBC {} {
  global gaSet gaDBox
  Status "BarCode Registration"
  set ret  -1
  set res1 -1
  set res2 -1
  set pair $gaSet(pair)
  
  foreach la {1 2} {
    if {$la==2 && $gaSet(Uut2asUut)==0} {
      set res2 0
      set ret 0
      break
    }
    set mac $gaSet($pair.mac$la)
    set barcode $gaSet($pair.barcode$la)
    set barcode$la $barcode
      #puts "pairIndx:$pairIndx pair:$pair"
    Status "Registration the MAC of Uut$la"
     set mr [file mtime $::RadAppsPath/MACReg.exe]
     set prevMr [clock scan "Wed Jan 22 23:20:40 2020"] ; # last working version, with 1 MAC
     if {$mr>$prevMr} {
        ## the newest MacReg
        set str "$::RadAppsPath/MACReg.exe /$mac / /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
      } else {
        set str "$::RadAppsPath/MACReg.exe /$mac /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
      }
      puts "mr:<[clock format $mr]> prevMr:<[clock format $prevMr]> \n str<$str>"
      set res$la [string trim [catch {eval exec $str} retVal$la]]
      #set res$la [string trim [catch {exec c://RADapps/MACReg.exe /$mac /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE} retVal$la]]
    puts "Uut$la mac:$mac barcode:$barcode res$la:<[set res$la]> retVal$la:<[set retVal$la]>"
    update
    AddToPairLog $gaSet(pair) "Uut$la MAC:$mac IDbarcode:$barcode"
    #after 1000
    if {[set res$la]!="0"} {
      puts "ret:[set res$la]"
      set ret -1
      break
    } else {
      set ret 0
    }
    
    if ![file exists c://logs/macHistory.txt] {
      set id [open c://logs/macHistory.txt w]
      after 100
      close $id
    }
    set id [open c://logs/macHistory.txt a]
    foreach la {1} {
      puts $id "[MyTime] Pair:$pair MAC:$gaSet($pair.mac$la) BarCode:[set barcode$la] res:[set res$la]"
    }      
    close $id
  
    if {$ret!=0} {
      break
    }
  }   
    
  Status ""	  

  if {$res1 != 0 || $res2 != 0} {
	  set gaSet(fail)  "Fail to update Data-Base"
	  return -1 
	} else {
 		return 0 
  }
} 

# ***************************************************************************
# CheckBcOk
# ***************************************************************************
proc CheckBcOk {} {
	global  gaDBox  gaSet
  puts "CheckBcOk" ;  update
  set pair 1
  if {$gaSet(useExistBarcode)==0} {
    RLSound::Play information
    SendEmail "OP-108L" "Read barcodes"
    if {$gaSet(Uut2asUut)==0} {
      set tit "Read Uut1 Barcode"
      set tex "Enter Uut1 Barcode"
      set entPerRow [set entQty 1]
      set entLab "Uut1"
    } else {
      set tit "Read Uut1 and Uut2 Barcodes"
      set tex "Enter Uut1 and Uut2 Barcodes"
      set entPerRow [set entQty 2]
      set entLab "Uut1 Uut2"
    }
    set ret [DialogBox -title $tit -text $tex -ent1focus 1 -type "Ok Cancel" \
        -entQty $entQty -entPerRow $entPerRow -entLab $entLab -icon /images/info]
    #  -type "Ok Cancel Skip" 12/10/2020 09:41:19       
    puts "[MyTime] Ret of DialogReadBarcode:<$ret>"     
  	if {$ret == "Cancel" } {
  	  return -2 
  	} elseif {$ret=="Ok"} {
      foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] {
        set barcode1 [string toupper $gaDBox($ent1)] 
        if {$ent2==""} {
          set barcode2 Ref
        } else {   
          set barcode2 [string toupper $gaDBox($ent2)]
        }  
        puts "barcode1 == $barcode1"
        puts "barcode2 == $barcode2"
  	    if ![string is xdigit $barcode1] {
          set gaSet(fail) "The barcode of Uut1 should be an HEX number"
          return -1
        }
        if {[string length $barcode1]!=11 && [string length $barcode1]!=12} {
          set gaSet(fail) "The barcode of Uut1 should be 11 or 12 HEX digits"
          return -1
        }
        if {$gaSet(Uut2asUut)==1} {
          if ![string is xdigit $barcode2] {
            set gaSet(fail) "The barcode of Uut2 should be an HEX number"
            return -1
          }
          if {[string length $barcode2]!=11 && [string length $barcode2]!=12} {
            set gaSet(fail) "The barcode of Uut2 should be 11 or 12 HEX digits"
            return -1
          }
        }
        if {$barcode1==$barcode2} {
          return -3
        }
      }
      return 0  	
  	} elseif {$ret=="Skip"} {
      set gaSet(fail) "No barcode. The reading was skipped"
      return -1
    }
  } elseif {$gaSet(useExistBarcode)==1} {
    if ![info exists gaSet($gaSet(pair).barcode1)] {
      set gaSet(useExistBarcode) 0
      return -1
    }
    set gaDBox(entVal1) $gaSet($gaSet(pair).barcode1)
    if ![info exists gaSet($gaSet(pair).barcode2)] {
      set gaSet(useExistBarcode) 0
      return -1
    }
    set gaDBox(entVal2) $gaSet($gaSet(pair).barcode2)
    set gaSet(useExistBarcode) 0
    return 0
  }
}
# ***************************************************************************
# ReadBarcode
# ***************************************************************************
proc ReadBarcode {} {
  global gaSet gaDBox
  puts "ReadBarcode" ;  update
  set ret -1
  catch {array unset gaDBox}
  while {$ret != "0" } {
    set ret [CheckBcOk]
    Status $gaSet(fail)
    puts "CheckBcOk res:$ret "
    if { $ret == "-2" ||  $ret == "-1" } {
      set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}.txt
      AddToPairLog $gaSet(pair) "$gaSet(DutFullName)"
      return $ret
    }
	}	
  Status ""
  foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] {la1 la2} {1 2} {
    set barcode1 [string toupper $gaDBox($ent1)] 
    set gaSet($gaSet(pair).barcode$la1) $barcode1
    set res [catch {exec $gaSet(javaLocation)/java.exe -jar $::RadAppsPath/checkmac.jar $barcode1 AABBCCFFEEDD} retChk]
    puts "Uut1 CheckMac $barcode1 res:<$res> retChk:<$retChk>" ; update
    if {$res=="1" && $retChk=="0"} {
      puts "No Id-MAC link"
      set gaSet($gaSet(pair).barcode$la1.IdMacLink) "noLink"
    } else {
      puts "Id-Mac link or error"
      set gaSet($gaSet(pair).barcode$la1.IdMacLink) "link"
    }
    
    if {$ent2==""} {
      set barcode2 Ref
      set gaSet($gaSet(pair).barcode$la2) $barcode2
      set gaSet($gaSet(pair).barcode$la2.IdMacLink) "link"
    } else {
      set barcode2 [string toupper $gaDBox($ent2)] 
      set gaSet($gaSet(pair).barcode$la2) $barcode2
      set res [catch {exec $gaSet(javaLocation)/java.exe -jar $::RadAppsPath/checkmac.jar $barcode2 AABBCCFFEEDD} retChk]
      puts "Uut2 CheckMac $barcode2 res:<$res> retChk:<$retChk>" ; update
      if {$res=="1" && $retChk=="0"} {
        puts "No Id-MAC link"
        set gaSet($gaSet(pair).barcode$la2.IdMacLink) "noLink"
      } else {
        puts "Id-Mac link or error"
        set gaSet($gaSet(pair).barcode$la2.IdMacLink) "link"
      }
    }
    
    set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-${barcode1}-${barcode2}.txt
    AddToPairLog $gaSet(pair) "$gaSet(DutFullName)"
    AddToPairLog $gaSet(pair) "UUT1 - $barcode1"
    AddToPairLog $gaSet(pair) "UUT2 - $barcode2"
  }    
  return $ret
}


# ***************************************************************************
# UnregIdBarcode
# UnregIdBarcode $gaSet($gaSet(pair).barcode1) $gaSet($gaSet(pair).barcode2)
# UnregIdBarcode EA100463652
# ***************************************************************************
proc UnregIdBarcode {barcode {mac {}}} {
  global gaSet
  Status "Unreg ID Barcode $barcode"
  set res [UnregIdMac $barcode $mac]
    
  puts "\nUnreg ID Barcode $barcode res:<$res>\n"
  if {$res=="OK" || [string match "*No records to Delete by ID-Number*" $res]} {
    set ret 0
  } else {
    set ret $res
  }
  AddToPairLog $gaSet(pair) "Unreg ID Barcode $barcode mac:<$mac> res:<$res> ret:<$ret>"
  return $ret
}

# ***************************************************************************
# UnregIdMac
# ***************************************************************************
proc UnregIdMac {barcode {mac {}}} {
  set ret 0
  set res ""
  set url "http://ws-proxy01.rad.com:10211/ATE_WS/ws/rest/"
  #set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param "DisconnectBarcode\?mac=[set mac]\&idNumber=[set barcode]"
  append url $param
  puts "url:<$url>"
  if [catch {set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]} res] {
    return $res
  } 
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set res "http::status: <$st> http::ncode: <$nc>"
    set ret -1
  }
  upvar #0 $tok state
  #parray state
  #puts "body:<$state(body)>"
  set ret $state(body)
  ::http::cleanup $tok
  
  return $ret
}

