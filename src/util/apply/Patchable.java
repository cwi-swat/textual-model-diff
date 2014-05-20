package util.apply;

import java.util.Queue;

public interface Patchable extends Runnable {
	
	Queue<Delta> getQueue();
	void setSystem(Patch patch);

}
