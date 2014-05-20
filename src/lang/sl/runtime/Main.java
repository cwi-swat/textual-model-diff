package lang.sl.runtime;

import java.awt.BorderLayout;
import java.awt.Container;
import java.awt.EventQueue;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.io.StringWriter;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;

import util.apply.Delta;
import util.apply.Patchable;

public class Main implements Patchable {
	private Queue<Delta> deltaQueue;
	private SLPatch system;
	private ByteArrayOutputStream boas = new ByteArrayOutputStream();

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

	protected void setup() {
		JFrame frame = new JFrame();
		frame.setLayout(new BorderLayout());
		frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		Container panel = frame.getContentPane();
		final JLabel status = new JLabel("");
		final JTextField event = new JTextField(10);
		Font font = new Font("Monaco", Font.PLAIN, 12);
		final JTextField output = new JTextField(40);
		output.setFont(font);
		final JTextArea log = new JTextArea(10, 50);
		log.setFont(font);
		JScrollPane logPane = new JScrollPane(log); 
		log.setEditable(false);
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
				log.setText(boas.toString());
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
		
		panel.add(step);
//		panel.add(update);
		panel.add(status);
		JPanel top = new JPanel(new FlowLayout());
		JLabel eventLabel = new JLabel("Enter event:");
		top.add(eventLabel);
		top.add(event);
		top.add(step);
		top.add(update);
		panel.add(top, BorderLayout.PAGE_START);
		panel.add(output, BorderLayout.CENTER);
		panel.add(logPane, BorderLayout.PAGE_END);
		
		frame.pack();
		frame.setLocationRelativeTo(null);
		frame.setLocation(800, 100);
		frame.setVisible(true);		
	}

	@Override
	public Queue<Delta> getQueue() {
		return deltaQueue;
	}

}
