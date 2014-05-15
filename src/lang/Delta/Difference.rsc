module lang::Delta::Difference

import lang::Delta::Model;
import lang::Delta::AST;

alias Element
 = tuple
 [
   str t,                                   //type
   map[str name, str val] values,           //attributes
   map[str name, set[loc] targets] links,   //unordered features
   map[str name, list[loc] targets] oLinks  //ordered features
 ];

alias Model
  = tuple
  [
    map[str path, loc id] name2id,
    map[loc id, Element element] elements
  ];
  
public Model NewModel = <(),()>;

public Delta difference
(
  Model mOld,
  Model mNew,
  rel[loc locOld, loc locNew] mapping
)
{
  list[Operation] additions = [];
  list[Operation] changes = [];
  list[Operation] deletions = [];

  //additions
  for(loc lNew <- mNew.elements)
  {
    if(lNew in mapping.locNew)
    {
      loc lOld = mapping.lOld;
    
      if(lOld notin mOld.elements)
      {
        Element e = mNew.elements[lNew];    
        additions += op_new(lNew, e.t);
      
        //value changes
        changes += [op_set (l, n, mNew.values[n], "") | n <- mNew.values];
      
        //unordered changes
        for(str n <- mNew.links)
        {
          set[loc] tgts = mNew.links[n]; 
          for(loc tgt <- tgts)
          {
            changes += [op_insert(l,n,tgt)];
          }
        }
      
        //ordered changes
        for(str n <- mNew.oLinks)
        {
          list[loc] tgts = mNew.links[n];
          for(int i <- [0..size(tgts)])
          {
            loc tgt = tgts[i];
            changes += [op_insertAt(l,n,tgt,i)];
          }
        }
      }      
    }
  }
  
  for(loc l <- mOld.elements)
  {
    if(l in mNew.elements)
    {
      ;
    }
  }
  
  //deletions
  //note, we don't check that all elements have their 'zeroValues'
  for(loc l <- mOld.elements)
  {
    if(l notin mNew.elements)
    {
      Element e = mOld.elements[l];
      deletions += [op_del(l, e.t)];
    }
  }
}