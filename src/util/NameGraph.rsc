module util::NameGraph

alias NameGraph
  = tuple
  [
    set[loc] defs,             //definition token locations
    set[loc] uses,             //usage token locations
    rel[loc use, loc def] refs //references from uses to definitions
  ];
