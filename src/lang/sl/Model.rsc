module lang::sl::Model

import lang::sl::AST;
import lang::Delta::AST;

public Delta init(Machine m: mach(str id, map[str, State] statesMap))
{
  list[Operation] additions = [op_new(m@location, "scope")];
  list[Operation] changes = [op_set(m@location,"name", id, "")];
  
  for(str stateName <- statesMap)
  {
    State s = statesMap[stateName];
    Delta d = init(s);
    additions += d.additions +
      [op_insert(m@location, "composedOf", s@location),
       op_insert(s@location, "partOf", m@location)];
    changes += d.changes;
  }
  
  return delta(additions, changes, []);
}

public Delta init(State g: group(str id, map[str, State] sMap))
{
  list[Operation] additions = [op_new(g@location, "scope")];
  list[Operation] changes = [op_set(g@location, "name", id, "")];
  
  for(str stateName <- sMap)
  {
    State s = sMap[stateName];
    Delta d = init(s);
    additions += d.additions +
      [op_insert(g@location, "composedOf", s@location),
       op_insert(s@location, "partOf", g@location)];
    changes += d.changes;
  }
  
  return delta(additions, changes, []);  
} 

public Delta init(State s: state(str id, map[str, Transition] tMap) )
{
  list[Operation] additions = [op_new(s@location, "state")];
  list[Operation] changes = [op_set(s@location, "name", id, "")];
  
  for(str tName <- tMap)
  {
    Transition t = tMap[tName];
    Delta d = init(t);
    additions += d.additions +
      [op_insert(s@location, "composedOf", t@location),
       op_insert(t@location, "partOf", s@location)];
    changes += d.changes;
  }
  
  return delta(additions, changes, []); 
}

public Delta init(Transition t: trans(str id, Ref ref))
{
  list[Operation] additions = [op_new(t@location, "transition"),
                               op_new(ref@location, "reference")];
  list[Operation] changes = [op_set(t@location, "event", "", id),
                             op_insert(t@location, "transitionTo", ref@location),
                             op_insert(ref@location, "transitionFrom", t@location)];
  //TODO: missing transition reference is not set --> scope analysis
  
  return delta(additions, changes, []); 
}
