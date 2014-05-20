machine m 
   state x
     foo => bar.w
   end

   bar {
     state w
       foo => y
     end
   }
   
   state y
     foo => x
   end
end