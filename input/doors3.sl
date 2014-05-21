machine doors
  state closed
    open => opened
    lock => locking.locked
  
  state opened
    close => closed
  
  locking {
    state locked
      unlock => closed
   }
end