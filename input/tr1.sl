machine m 
   state x
     foo => bar.w
   end

   bar {
     state w
       foo => riemer
     end
   }
   
   
   
   state riemer
     foo => x
   end
end