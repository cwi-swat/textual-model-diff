package lang.sml.runtime;

import java.io.PrintStream;

import util.apply.*;

public class MigrateSML extends Apply
{ 
  public MigrateSML(PrintStream log)
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
      //State s = (State) newObject;
      //apply(s.init(this));
      Edit edit = new Set(create.getKey(), new Path(new Field("count")), 0);
      edit.accept(this);
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
      //apply(machine.init(this));
      //State s = machine.findInitial();
      //new util.apply.Set(getKey(s), new Path(new Field("count")), (s.count+1)).accept(this);
      Edit edit = new Set(insert.getKey(), new Path(new Field("state")), machine.findInitial());
      edit.accept(this);
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
      //apply(machine.init(this));
      Edit edit = new Set(getKey(machine), new Path(new Field("state")), machine.findInitial());
      edit.accept(this);
    }
  }
}