module lang::Delta::Interpreter

import lang::Delta::AST;
import lang::Delta::Model;

public Model eval(Model m, Delta delta)
{
  for(Operation op <- delata.renames)
  {
    m = eval(m, op);
  }
  for(Operation op <- delta.additions)
  {
    m = eval(m, op);
  }
  for(Operation op <- delta.changes)
  {
    m = eval(m, op);
  }
  for(Operation op <- delta.deletions)
  {
    m = eval(m, op);
  }
  return m;
}

private Model eval(Model m, Operation op: op_rename(loc id /*new*/, loc id2 /*old*/))
  = (id : replace(m[l],id,id2) | l <- m, l == id2) + (l : replace(m[l],id,id2) | l <- m, l != id2);

private Element replace(Element e, loc id /*new*/, loc id2 /*old*/)
  = <e.t, replace(values, id, id2), replace(links, id, id2), replace(oLinks, id, id2)>;

private map[loc, val] replace(map[loc, val] m, loc id /*new*/, loc id2 /*old*/)
  = (id : m[l] | l <- m, l == id2) + (l : m[l] | l <- m, l != id2);
  
private Model eval(Model m, Operation op: op_new(loc id, str typeName))
  = m + (id : <typeName, (),(),()>);

private Model eval(Model m, Operation op: op_del(loc id, str typeName))
  = m - (id : m[id]);
  
private Model eval(Model m, Operation op: op_set(loc id, str name /*attributeName*/, str valNew, str valOld))
{
  m[id].values += (name: valNew);
  return m;
}

private Model eval(Model m, Operation op: op_insert(loc id /*from*/, str name /*featureName*/, loc id2 /*to*/))
{
  if(name in m.elements[id].links)
  {
    m[id].links[name] += {id2};
  }
  else
  {
    m[id].links += (name : {id2});
  }  
  return m;
}

private Model eval(Model m, Operation op: op_remove (loc id /*from*/, str name /*featureName*/, loc id2 /*to*/))
{
  m[id].links[name] -= id2;
  return m;
}

private Model eval(Model m, op_instertAt(loc id /*from*/, str name /*featureName*/, loc id2 /*to*/, int index))
{
  list[loc] l = m[id].links[name];
  list[loc] front = l[0..index];
  list[loc] back = l[index..size(l)];
  
  if(index >= 0 && index < size(l))
  {
    m[id].links[name] = front + [id2] + back;
  }

  return m;
}

private Model eval(Model m, Operation op: op_removeAt(loc id /*from*/, str name /*featureName*/, loc id2 /*to*/, int index))
{
  list[loc] l = m[id].links[name];
  list[loc] front = l[0..index];
  list[loc] back = l[index+1..size(l)];

  if(index >= 0 && index < size(l))
  {
    //if(l[index] == id2)
    //{
      m[id].links[name] = front + back;
    //}
  }
  
  return m;
}
