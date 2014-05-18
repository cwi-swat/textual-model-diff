module util::Equals

import util::NameGraph;
import util::Mapping;


bool modelEquals(value x, value y, NameGraph g1, NameGraph g2, IDMatching mapping, IDAccess ia) {
  if (node xn := x, node yn := y, isDef(xn, ia), isDef(yn, ia), getDefId(xn, ia) in mapping.id) {
    return mapping.id[getDefId(xn, ia)] == getDefId(yn, ia);
  }
  else if (node xn := x, node yn := y, ia.isId(xn), ia.isId(yn)) {
    if (d1 <- g1.refs[ia.getId(xn)], d2 <- g2.refs[ia.getId(yn)]) {
      return mapping.id[d1] == d2;
    }
    assert false: "BUG: Could not find use in ref graph.";
  }
  else if (node xn := x, node yn := y, ia.isId(xn), isDef(yn, ia)) {
    if (d1 <- g1.refs[ia.getId(xn)]) {
      return mapping.id[d1] == getDefId(yn, ia);
    }
    assert false: "BUG: Could not find use in ref graph.";
  }
  else if (node xn := x, node yn := y, isDef(xn, ia), ia.isId(yn)) {
    if (d2 <- g2.refs[ia.getId(yn)]) {
      return mapping[getDefId(xn, ia)] == d2;
    }
    assert false: "BUG: Could not find uses in ref graph.";
  }
  else if (node xn := x, node yn := y, isContains(xn, ia), ia.isContains(yn)) {
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
  else if (isAtom(x, ia), isAtom(y, ia)) {
    return x == y;
  }
  return false;
}
