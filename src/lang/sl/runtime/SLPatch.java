package lang.sl.runtime;

import util.apply.Create;
import util.apply.Patch;
import util.apply.Remove;

public class SLPatch extends Patch {

	private Mach machine;
	
	public Mach getMachine() {
		return machine;
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
		super.visit(create);
		if (lookup(create.getOwnerKey()) instanceof State) {
			System.out.println("Created a new state");
		}
		if (lookup(create.getOwnerKey()) instanceof Mach) {
			System.out.println("Created a new machine");
			this.machine = (Mach) lookup(create.getOwnerKey());
		}
	}
}
