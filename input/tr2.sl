machine m 
   state x
     foo => bar.w
   end
   
   
   bar {
     state w
       foo => x
     end
   }
end