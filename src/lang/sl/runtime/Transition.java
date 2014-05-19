package lang.sl.runtime;

public class Transition {
	String event;
	State target;
	
	// Runtime
	int numberOfFirings = 0;
}
