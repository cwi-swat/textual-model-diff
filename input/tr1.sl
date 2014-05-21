machine m 
   state x
     foo => y
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