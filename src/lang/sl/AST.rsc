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
  = trans(str event, Ref ref)
  ;
  
  
data Ref
  = ref(str name)
  | ref(str name, Ref restName);

data Name
 = name(str name);

  