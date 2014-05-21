package lang.sl.runtime;

public interface SLEdits<M, S, G, T> {

	S createState(Object key);
	T createTrans(Object key);
	M createMach(Object key);
	G createGroup(Object key);
	
	
	
}
