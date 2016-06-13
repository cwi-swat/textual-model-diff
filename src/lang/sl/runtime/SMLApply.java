package lang.sl.runtime;

import java.io.PrintStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import util.apply.*;

public class SMLApply extends Apply
{
	public SMLApply(PrintStream log)
	{
		super(log);
	}

	private Mach machine;
	
	public Mach getMachine()
	{
		return machine;
	}
	
	@Override
	public void visit(Remove remove)
	{
		if (remove.appliesToRoot() && lookup(remove.getOwnerKey()) == machine.state)
		{
			State start = machine.findInitial();
      
			if (start == null)
			{
				log.println("Removed current state and no initial found.");
			}
			else
			{
			  //machine.currentState = start;
			  apply(machine.setCurrentState(this, start));
			}
		}
		super.visit(remove);
	}
	
	@Override
	public void visit(Create create)
	{
		super.visit(create);
    boolean update = false;
		if (create.appliesToRoot() && lookup(create.getOwnerKey()) instanceof State)
		{
			log.println("Created a new state");
			update = true;
		}
		if (create.appliesToRoot() && lookup(create.getOwnerKey()) instanceof Mach)
		{
			log.println("Created a new machine");
			this.machine = (Mach) lookup(create.getOwnerKey());
			update = true;
		}
		if(update && machine != null && machine.state == null)
		{
      log.println("Reinit of initial state");
      //machine.currentState = machine.findInitial();
      State start = machine.findInitial();
      if(start != null)
      {
        apply(machine.setCurrentState(this, start));
      }
    }
	}
}
