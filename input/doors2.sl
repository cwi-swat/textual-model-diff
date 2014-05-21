machine doors
  state closed
    open => opened
    lock => locked
  
  state opened
    close => closed
    
  state locked
    unlock => closed
end