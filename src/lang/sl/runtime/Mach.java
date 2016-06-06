package lang.sl.runtime;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

public class Mach {
	public String id;
	public List<Element> states = new ArrayList<Element>();

	// Runtime
	State currentState;

	public void init(State initial) {
		currentState = initial;
		currentState.visits += 1;
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
				currentState.visits += 1;
				break;
			}
		}
	}

	public State findInitial() {
		for (Element n: states) {
			if (n instanceof State) {
				return (State) n;
			}
		}
		return null;
	}
	
}
