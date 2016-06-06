package lang.sl.runtime;

import java.util.ArrayList;
import java.util.List;

public class State extends Element {
	public List<Trans> transitions = new ArrayList<Trans>();
	public int visits = 0;
}
