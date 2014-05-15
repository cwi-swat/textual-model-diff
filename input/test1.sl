machine m

  state init
    bang => foo.bar when bar > 1 + init
  end
  
  foo
  {    

    state bar
      biach => init
    end
    
    
  }
end