module lang::sl::NameAnalyzer

import lang::sl::AST;
import util::NameGraph;
import IO;
import List;

data Scope
  = scope(str name,
          loc l,
          map[str scopeName, Scope s] scopes,
          map[str defName, loc l] defs);

loc NULL_LOC = |null://null|(0,0,<0,0>,<0,0>);

public Machine setScope(Machine m: mach(Name name, list[State] states))
 = mach(name, [setScope(scope(m), s, [name.name]) | s <- states])[@location = m.id@location][@scope = []];

public State setScope(Scope st, State s: state(Name name, list[Transition] transitions), list[str] scope)
 = state(name, [setScope(st, t, scope)| t <- transitions, bprintln(t)])[@location = s.id@location][@scope = scope];

public State setScope(Scope st, State g: group(Name name, list[State] states), list[str] scope)
 = group(name, [setScope(st, s, scope + [name.name]) | s <- states])[@location = g.id@location][@scope = scope];

public Transition setScope(Scope st, Transition t: trans(str event, Ref r), list[str] scope)
 = trans(event, setScope(st, r, [], scope))[@location = t@location][@scope = scope];

public Ref setScope(Scope st, Ref r: simple(str refName), list[str] name, list[str] scope)
 = simple(refName)[@location = r@location][@scope = scope][@ref = findLoc(st, scope, getName(r, name))];

public Ref setScope(Scope st, Ref r: qualified(str refName, Ref restName), list[str] name, list[str] scope)
 = qualified(refName, restName2)[@location = r@location][@scope = scope][@ref = restName2@ref]
 when Ref restName2 := setScope(st, restName, name+[refName], scope);


list[str] getName(Ref r: simple(str n), list[str] name)
{
  return name + [n];
}

list[str] getName(Ref r: qualified(str n, Ref ref), list[str] name)
{
  return getName(ref, name + [n]);
}

public Scope scope(Machine m: mach(Name name, list[State] states))
 = scope("",
         m@location,
         (name.name: scope(name.name,
              m.id@location,
              (g.id.name : scope(g) | g: group(_,_) <- states),
              (s.id.name : s.id@location | s: state(_,_) <- states))
         ),
         ());

public Scope scope(State g: group(Name name, list[State] states))
 = scope(name.name,
         g.id@location,
         (g.id.name : scope(g) | g: group(_,_) <- states),
         (s.id.name : s.id@location | s: state(_,_) <- states));

//st: symbol table
//scope: scope to search in (assumed exists)
//name: name to find
public loc findLoc(Scope st, list[str] curScope, list[str] name)
{
  Scope s = st;
  for(str n <- curScope)
  {
    s = s.scopes[n];
  }

  print("Search in Scope "+s.name+" for ");
  for(n <- name){ print(n+".");}
  println("");
  
  Scope find = s;
  list[str] tail = name;
  str n;
  do
  {
    <n,tail>= headTail(tail);
    println("Search "+n);  
    if(n in find.scopes)
    {
      //nested search
      if(tail != [])
      {
        find = find.scopes[n];
      }
      else
      {
        println("Found Scope "+n);
        return find.scopes[n].l;
      }
    }
    else if(n in find.defs)
    {
      //found state
      println("Found state "+n);
      
      return find.defs[n];
    }
    else
    {
      //failed to find scope or state, go up a level
      if(curScope != [])
      {
        println("Failed to find " + n);
        //iprintln(curScope);

        //println("step1");        
        list[str] step1 = reverse(curScope);
        //iprintln(step1);

        //println("step2");
        <_,step2> = pop(step1);
        //step2 = tail(step1);
        //iprintln(step2);
        
        //println("step3");
        list[str] step3 = reverse(step2);
        //iprintln(step3);
        
        return findLoc(st, step3, name);
      }
      else
      {
        break;
      }
    }    
  } while(tail != []);
  println("END");  
  return NULL_LOC;
}


public NameGraph getNameGraph(Machine m)
{
  set[loc] defs = {};
  set[loc] uses = {};
  rel[loc,loc] refs = {};
  
  visit(m)
  {
    case Machine mach:
    {
      defs += {mach@location};
    }
    case State s:
    {
      defs += {s@location};
    }
    case Transition t:
    {
      ;//defs += {t@location};
    }
    case Ref r:
    {
      uses += {r@location};
      refs +={<r@location, r@ref>};
    }
  }
  
  return <defs,uses,refs>;
}

