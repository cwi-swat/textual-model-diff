module lang::sml::AST
import IO;
import List;

anno loc Machine@location;
anno loc State@location;
anno loc Trans@location;
anno loc Ref@location;
anno loc Name@location;

anno list[str] Machine@scope;
anno list[str] State@scope;
anno list[str] Trans@scope;
anno list[str] Ref@scope;

anno loc Ref@ref;

data Machine
  = mach(Name id, list[State] states);
  
data State
  = state(Name id, list[Trans] transitions)
  | group(Name id, list[State] states);

data Trans
  = trans(str event, Ref target);
  
data Ref
  = simple(str name)
  | qualified(str name, Ref restName);

data Name
 = name(str name);

  