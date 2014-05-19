module util::RuntimeDiff

import util::Diff;

@javaClass{util.RuntimeDiff}
java int requestSystem();

@javaClass{util.RuntimeDiff}
java void sendDelta(int id, Delta delta, map[loc, loc] mapping);