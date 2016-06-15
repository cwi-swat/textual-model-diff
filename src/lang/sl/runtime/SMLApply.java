package lang.sl.runtime;

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
  }
  
  @Override
  public void visit(Insert insert)
  {
    super.visit(insert);
    
    Object inserted = insert.getInserted(this);
    if (inserted instanceof State && machine.state == null)
    {
      System.out.println("Inserted state in unitialized machine: set initial state");
      //machine.state = machine.findInitial();
      apply(machine.init(this));
    }
  }
  
  @Override
  public void visit(Remove remove)
  {
    Object removed = remove.getRemoved(this);
    super.visit(remove);
    if (removed == machine.state)
    {
      System.out.println("Removed initial state: set initial state");
      //machine.state = machine.findInitial();  
      apply(machine.init(this));
    }
  }
}