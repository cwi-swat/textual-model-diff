module util::Equals

import util::NameGraph;
import util::Mapping;
import Node;
import List;
import IO;

bool modelEquals(value x, value y, NameGraph g1, NameGraph g2, IDMatching mapping, IDAccess ia) {
  if (node xn := x, node yn := y, isDef(xn, g1, ia), isDef(yn, g2, ia), getDefId(xn, g1, ia) in mapping.id) {
    return mapping.id[getDefId(xn, g1, ia)] == getDefId(yn, g2, ia);
  }
  else if (node xn := x, node yn := y, ia.isRefId(xn, g1), ia.isRefId(yn, g2)) {
    //println("G1.refs");
    //iprintln(g1.refs);
    //println("G2.refs");
    //iprintln(g2.refs);
    //println("xn = <xn>");
    //println("yn = <yn>");
    
    if (d1 <- g1.refs[ia.getId(xn)], d2 <- g2.refs[ia.getId(yn)]) {
      //println("d1 = <d1>");
      //println("d2 = <d2>");
      //println("Mapping");
      //iprintln(mapping);
      if (d1 in mapping.id) {
        return mapping.id[d1] == d2;
      }
      return false;
    }
    assert false: "BUG: Could not find use in ref graph.";
  }
  else if (node xn := x, node yn := y, ia.isRefId(xn, g1), isDef(yn, g2, ia)) {
    if (d1 <- g1.refs[ia.getId(xn)]) {
      return mapping.id[d1] == getDefId(yn, g, ia);
    }
    assert false: "BUG: Could not find use in ref graph.";
  }
  else if (node xn := x, node yn := y, isDef(xn, g1, ia), ia.isRefId(yn, g2)) {
    if (d2 <- g2.refs[ia.getId(yn)]) {
      return mapping[getDefId(xn, g1, ia)] == d2;
    }
    assert false: "BUG: Could not find uses in ref graph.";
  }
  else if (node xn := x, node yn := y, isContains(xn, g1, ia), isContains(yn, g2, ia)) {
    xks = getChildren(xn);
    yks = getChildren(yn);
    if (getName(xn) != getName(yn)) {
      return false;
    }
    if (size(xks) != size(yks)) {
      return false;
    }
    for (<a, b> <- zip(xks, yks)) {
      if (!modelEquals(a, b, g1, g2, mapping, ia)) {
        return false;
      }
    }
    return true;
  }
  else if (list[value] xl := x, list[value] yl := y) {
    if (size(xl) != size(yl)) {
      return false;
    }
    for (i <- [0..size(xl)]) {
      if (!modelEquals(xl[i], yl[i], g1, g2, mapping, ia)) {
        return false;
      }
    }
    return true;
  }
  else if (isAtom(x, g1, ia), isAtom(y, g2, ia)) {
    return x == y;
  }
  return false;
}
