module lang::sl::AST
import IO;
import List;

anno loc Machine@location;
anno loc State@location;
anno loc Transition@location;
anno loc Ref@location;
anno loc Name@location;

anno list[str] Machine@scope;
anno list[str] State@scope;
anno list[str] Transition@scope;
anno list[str] Ref@scope;

anno loc Ref@ref;

data Machine
  = mach(Name id, list[State] states);
  
data State
  = state(Name id, list[Transition] transitions)
  | group(Name id, list[State] states);

data Transition
  = trans(Name id, Ref ref)
  | trans(Name id, Ref ref, Expr expr)
  ;
  
  
data Ref
  = ref(str name)
  | ref(str name, Ref restName);

data Expr
  = lit(real x)
  | var(Ref id)
  | add(Expr l, Expr r)
  | gt(Expr l, Expr r)
  ;
data Name
 = name(str name);

  