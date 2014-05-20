package lang.sl.runtime;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Mach {
	public String id;
	public List<Named> states = new ArrayList<Named>();

	// Runtime
	State currentState;

	public void init(State initial) {
		currentState = initial;
	}
	
	public void step(String event, Writer output) throws IOException {
		for (Trans trans: currentState.transitions) {
			System.err.println("Checking trans " + trans + " on " + event);
			if (event.equals(trans.event)) {
				System.err.println("Fire!");
				System.err.println("Going to state: " + trans.target.id);
				State target = trans.target;
				output.write(target.id);
				trans.numberOfFirings++;
				currentState = target;
				break;
			}
		}
	}

	public State findInitial() {
		for (Named n: states) {
			if (n instanceof State) {
				return (State) n;
			}
		}
		return null;
	}
	
}
