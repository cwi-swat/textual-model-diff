module lang::sl::Resolve

import lang::sl::AST;
import util::NameGraph;

alias Env = map[str name, loc id];

data Scope 
  = scope(Env env)
  | nested(str name, Env env, Scope parent)
  ;

NameGraph resolve(Machine m)
{
  Env env = ( s.id.name: s.id@location | State s <- m.states );
  NameGraph g  = <{},{},{}>;
  for (s <- m.states)
  {
    g = resolve(s, scope(env), g);
  }
  return g;
}

NameGraph resolve(group(x, ss), Scope scope, NameGraph g)
{
  env = ( s.id.name: s.id@location | State s <- ss );
  for (s <- m.states)
  {
    g = resolve(s, nested(x.name, env, scope), g);
  }
  return g;
}

NameGraph resolve(state(x, ts), Scope scope, NameGraph g)
{
  for (t <- ts) {
    g = resolve(t, scope, g);
  }
  return g;
}

NameGraph resolve(trans(e, s), Scope scope, NameGraph g)
{
  switch (s) {
    case r:ref(x):
    {
      ;
    }
    case ref(x, t): {
      // record group ref.
      g.uses += {r@location};
      g.refs += <r@location, scope.env[x]>;
    }  
  }
}

NameGraph resolve(r:simple(x), Scope scope, NameGraph g)
{
  g.uses += {r@location};
  g.refs += <r@location, scope.env[x]>;
  return g;
}

NameGraph resolve(r:qualified(x,t), Scope scope, NameGraph g)
{
  g.uses += {r@location};
  g.refs += <r@location, scope.env[x]>;
  return g;
}