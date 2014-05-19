package lang.sl.runtime;

import util.apply.Create;
import util.apply.Patch;
import util.apply.Remove;

public class SLPatch extends Patch {

	private Machine machine;

	public SLPatch(Machine machine) {
		super();
		this.machine = machine;
	}
	
	@Override
	public void visit(Remove remove) {
		if (remove.appliesToRoot() && lookup(remove.getOwnerKey()) == machine.currentState) {
			State start = machine.findInitial();
			if (start == null) {
				throw new RuntimeException("removal of last state, cannot continue");
			}
			machine.currentState = start;
		}
		super.visit(remove);
	}
	
	@Override
	public void visit(Create create) {
		if (lookup(create.getOwnerKey()) instanceof State) {
			System.out.println("Creating a new state");
		}
		super.visit(create);
	}
}
