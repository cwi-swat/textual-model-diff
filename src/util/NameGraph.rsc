module util::NameGraph


alias NameGraph
  = tuple
  [
    set[loc] defs,
    set[loc] uses,
    rel[loc use, loc def] refs
  ];
