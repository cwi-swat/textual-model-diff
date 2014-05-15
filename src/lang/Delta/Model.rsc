module lang::Delta::Model

alias Element
 = tuple
 [
   str t,                                //type
   map[loc id, str val] values,          //attributes
   map[loc id, set[loc] targets] links,  //unordered features
   map[loc id, list[loc] targets] oLinks //ordered features
 ];

alias odel
  = map[loc id, Element element];
  
public Model NEW_Model = ();
