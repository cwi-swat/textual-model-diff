package lang.sl.runtime;

import java.io.PrintStream;

import util.apply.Create;
import util.apply.Patch;
import util.apply.Remove;

public class SLPatch extends Patch {

	public SLPatch(PrintStream log) {
		super(log);
	}

	private Mach machine;
	
	public Mach getMachine() {
		return machine;
	}
	
	@Override
	public void visit(Remove remove) {
		if (remove.appliesToRoot() && lookup(remove.getOwnerKey()) == machine.currentState) {
			State start = machine.findInitial();
			if (start == null) {
				log.println("Removed current state and no initial found.");
			}
			machine.currentState = start;
		}
		super.visit(remove);
	}
	
	@Override
	public void visit(Create create) {
		super.visit(create);
		if (create.appliesToRoot() && lookup(create.getOwnerKey()) instanceof State) {
			log.println("Created a new state");
			// Hmm, why the duplication...
			if (machine != null && machine.currentState == null) {
				log.println("Reinit of initial state");
				machine.currentState = machine.findInitial();
			}
		}
		if (create.appliesToRoot() && lookup(create.getOwnerKey()) instanceof Mach) {
			log.println("Created a new machine");
			this.machine = (Mach) lookup(create.getOwnerKey());
			if (machine != null && machine.currentState == null) {
				log.println("Reinit of initial state");
				machine.currentState = machine.findInitial();
			}
		}
	}
}
