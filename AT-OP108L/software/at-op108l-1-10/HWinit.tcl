#set gaSet(javaLocation) C:\\Program\ Files\ (x86)\\Java\\jre6\\bin\\
set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin\\
switch -exact -- $gaSet(pair) {
  1  {
      set gaSet(comUut1)   11
      set gaSet(comUut2)   6
      set gaSet(comEtx)    4
      set gaSet(comDxc)    5
      #set gaSet(comSF1V)   1
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT31CSK2  
  }
  2 {
      set gaSet(comUut1)   12
      set gaSet(comUut2)   14
      set gaSet(comEtx)    15
      set gaSet(comDxc)    13
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT311ZG8         
  }
}  
set gaSet(comSF1V)   1
source lib_PackSour_Op108L.tcl
