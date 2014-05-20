package lang.sl.runtime;

import java.awt.Container;
import java.awt.EventQueue;
import java.awt.FlowLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import java.io.StringWriter;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JTextField;

import util.apply.Delta;
import util.apply.Patch;
import util.apply.Patchable;

public class Main implements Patchable {
	private Queue<Delta> deltaQueue;
	private SLPatch system;

	public Main() {
		this.deltaQueue = new ConcurrentLinkedQueue<Delta>();
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

	protected void setup() {
		JFrame frame = new JFrame();
		frame.setLayout(new FlowLayout());
		frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		Container panel = frame.getContentPane();
		final JLabel status = new JLabel("");
		final JTextField event = new JTextField(10);
		final JTextField output = new JTextField(40);
		JButton update = new JButton("Update");
		JButton step = new JButton("Step");
		
		update.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent e) {
				Delta d = deltaQueue.poll();
				if (d != null) {
					status.setText("applying delta");
					system.apply(d);
					Mach m = system.getMachine();
					if (m.currentState == null) {
						m.init(m.findInitial());
					}
				}
			}
		});
		
		step.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent arg0) {
				StringWriter w = new StringWriter();
				try {
					system.getMachine().step(event.getText(), w);
				} catch (IOException e1) {
					e1.printStackTrace();
				}
				output.setText(w.toString() + ";" + output.getText());
			}
		});
		
		panel.add(event);
		panel.add(step);
		panel.add(update);
		panel.add(status);
		panel.add(output);
		
		frame.pack();
		frame.setLocationRelativeTo(null);
		frame.setLocation(800, 100);
		frame.setVisible(true);		
	}

	@Override
	public Queue<Delta> getQueue() {
		return deltaQueue;
	}

	@Override
	public void setSystem(Patch patch) {
		system = (SLPatch) patch;
	}
}
