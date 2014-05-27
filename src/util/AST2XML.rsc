module util::AST2XML

import lang::xml::DOM;

import Node;

Node ast2xml(node n) {
  x = element(none(), getName(n), []);
  i = 0;
  for (k <- getChildren(n)) {
    switch (k) {
      case node n: x.children += [ast2xml(n)];
      case list[value] l: {
         le = element(none(), "list", []);
         le.children = [ ast2xml(e) | node e <- l ];
         x.children += [le];
      }
      case value v: x.children += [attribute(none(), "attr<i>", "<v>")];
      default:
        println("Missed: <k>");
    }
  }
  return x;
}