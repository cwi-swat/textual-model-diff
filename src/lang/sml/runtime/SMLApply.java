package lang.sml.runtime;

import java.io.PrintStream;

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
  public void visit(Create create)
  {
    super.visit(create);
    Object newObject = create.getCreated(this);
    if (newObject instanceof Mach)
    {
      System.out.println("Created new state machine.");
      this.machine = (Mach) newObject;
    }
    else if(newObject instanceof State)
    {
      System.out.println("Created new state.");
      State s = (State) newObject;
      apply(s.init(this));
    }
  }
  
  @Override
  public void visit(Insert insert)
  {
    super.visit(insert);
    Object owner = insert.getOwner(this);
    if (machine != null && machine.state == null && owner == machine)
    {
      System.out.println("Inserted element in unitialized machine: set initial state");
      apply(machine.init(this));
    }
  }
  
  @Override
  public void visit(Delete delete)
  {
    Object deleted = delete.getDeleted(this);
    super.visit(delete);
    if (machine != null && deleted == machine.state)
    {
      System.out.println("Deleted current state: set initial state");
      apply(machine.init(this));
    }
  }
}