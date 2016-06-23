module util::RuntimeDiff

import util::Diff;

@javaClass{util.RuntimeDiff}
java int requestSystem();

@javaClass{util.RuntimeDiff}
java void sendDelta(int id, Delta delta);

@javaClass{util.RuntimeDiff}
java void runInterpreter(int id, str appClass);