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
	
	public void step(Scanner input, Writer output) throws IOException {
		String token = input.nextLine();
		for (Trans trans: currentState.transitions) {
			if (token.equals(trans.event)) {
				State target = trans.target;
				output.write(target.id + "\n");
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
