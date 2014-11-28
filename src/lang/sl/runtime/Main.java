package lang.sl.runtime;

import java.awt.Container;
import java.awt.Dimension;
import java.awt.EventQueue;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.Timer;

import util.apply.Delta;
import util.apply.Patchable;

public class Main implements Patchable {
	private Queue<Delta> deltaQueue;
	private SLPatch system;
	private ByteArrayOutputStream boas = new ByteArrayOutputStream();

	private JFrame frame;
	
	public Main() {
		this.deltaQueue = new ConcurrentLinkedQueue<Delta>();
		this.system = new SLPatch(new PrintStream(boas));
	}

	@Override
	public void run() {
		EventQueue.invokeLater(new Runnable() {
			
			@Override
			public void run() {
				setup();
			}
		});
	}
	
	
	private void printMachine(Mach m, StringWriter w) {
		// * <name> <visited> {<events>}
		w.append("  | State      | #  | Events\n");
		w.append("--+------------+----+---------------\n");
		List<Named> states = new ArrayList<>();
		states.addAll(m.states);
		while (!states.isEmpty()) {
			Named s = states.remove(0);
			if (s instanceof State) {
				String cur = m.currentState == s ? "*" : " ";
				List<Trans> ts = ((State)s).transitions;
				List<String> es = new ArrayList<>();
				for (Trans t: ts) {
					es.add(t.event);
				}
				w.append(String.format("%s | %10s | %2d | %s\n", cur, s.id, ((State) s).visits, Arrays.toString(es.toArray())));	
			}
			else if (s instanceof Group) {
				states.addAll(((Group)s).states);
			}
		}
	}
	
	private void addEventButtons(final Mach m, final JPanel events, final JTextArea status) {
		List<Named> states = new ArrayList<>();
//		states.addAll(m.states);
		states.add(m.currentState);
		while (!states.isEmpty()) {
			Named s = states.remove(0);
			if (s instanceof State) {
				for (final Trans t: ((State)s).transitions) {
					System.out.println("Adding button for " + t.event);
					JButton b = new JButton(t.event);
					b.addActionListener(new ActionListener() {
						
						@Override
						public void actionPerformed(ActionEvent e) {
							StringWriter w = new StringWriter();
							try {
								system.getMachine().step(t.event, w);
							} catch (IOException e1) {
								e1.printStackTrace();
							}
							showMachine(m, status);
							updateEventButtons(status, events, m);
						}

						private void showMachine(final Mach m,
								final JTextArea status) {
							StringWriter sw = new StringWriter();
							printMachine(m, sw);
							status.setText(sw.toString());
						}
					});
					events.add(b);
				}	
			}
			else if (s instanceof Group) {
				states.addAll(((Group)s).states);
			}
		}
	}

	protected void setup() {
		frame = new JFrame("State machine");
		frame.setLayout(new FlowLayout());
		frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);

		final Container panel = frame.getContentPane();
		panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
		Font font = new Font("Monaco", Font.PLAIN, 12);
		final JTextArea status = new JTextArea(6, 20);
		status.setPreferredSize(new Dimension(100, 200));
		status.setFont(font);
		JScrollPane logPane = new JScrollPane(status); 
		status.setEditable(false);
		
		final JPanel events = new JPanel();
		events.setLayout(new FlowLayout());
		
		Timer poller = new Timer(100, new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent arg0) {
				Delta d = deltaQueue.poll();
				if (d != null) {
					
					status.setText("applying delta");
					system.apply(d);
					Mach m = system.getMachine();
					if (m.currentState == null) {
						m.init(m.findInitial());
					}
					StringWriter sw = new StringWriter();
					printMachine(m, sw);
					status.setText(sw.toString());
					events.removeAll();
					updateEventButtons(status, events, m);
				}
			}
		});
		
		panel.add(events);
		panel.add(logPane);
		
		frame.pack();
		frame.setLocationRelativeTo(null);
		frame.setLocation(800, 100);
		frame.setVisible(true);
		poller.start();

	}

	private void updateEventButtons(final JTextArea status, final JPanel events, Mach m) {
		System.err.println("Updating event buttons");
		events.removeAll();
		addEventButtons(m, events, status);
//		frame.pack();
		events.revalidate();
		events.repaint();
	}
	
	@Override
	public Queue<Delta> getQueue() {
		return deltaQueue;
	}

}
