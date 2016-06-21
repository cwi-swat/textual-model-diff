package lang.sml.runtime;

import java.awt.Container;
import java.awt.Dimension;
import java.awt.EventQueue;
import java.awt.FlowLayout;
import java.awt.Frame;

import javax.swing.BoxLayout;

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

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.Timer;

import util.apply.Delta;
import util.apply.Patchable;

public class Main implements Patchable
{
  private static final int      FRAME_WIDTH      = 260;
  private static final int      FRAME_HEIGHT     = 210;
  private static final int      FRAME_X_POSITION = 400;
  private static final int      FRAME_Y_POSTION  = 100;
  private static final int      EVENTS_HEIGHT    = 64;
  private static final int      FONT_SIZE        = 14;
  private static final int      BUTTON_FONT_SIZE = 14;

  private Queue<Delta>          deltaQueue;
  private SMLApply              system;
  private ByteArrayOutputStream boas             = new ByteArrayOutputStream();

  public Main()
  {
    this.deltaQueue = new ConcurrentLinkedQueue<Delta>();
    this.system = new SMLApply(new PrintStream(boas));
  }

  @Override
  public void run()
  {
    EventQueue.invokeLater(new Runnable()
    {

      @Override
      public void run()
      {
        setup();
      }
    });
  }

  private void printMachine(Mach m, StringWriter w)
  {
    // * <name> <visited> {<events>}
    w.append("  | State  | # | Events\n");
    w.append("--+--------+---+---------------\n");
    List<Element> states = new ArrayList<>();
    states.addAll(m.states);
    while (!states.isEmpty())
    {
      Element s = states.remove(0);
      if (s instanceof State)
      {
        String cur = m.state == s ? "*" : " ";
        List<Trans> ts = ((State) s).transitions;
        List<String> es = new ArrayList<>();
        for (Trans t : ts)
        {
          es.add(t.event);
        }
        w.append(String.format("%s | %6s | %1d | %s\n", cur, s.id, ((State) s).count, Arrays.toString(es.toArray())));
      }
      else if (s instanceof Group)
      {
        states.addAll(((Group) s).states);
      }
    }
  }

  private void addEventButtons(final Mach m, JFrame frame, JPanel events, final JTextArea status)
  {
    List<Element> states = new ArrayList<>();
    states.addAll(m.states);
    String name = "State Machine: " + m.id;
    frame.setTitle(name);

    while (!states.isEmpty())
    {
      Element s = states.remove(0);
      if (s instanceof State)
      {
        for (final Trans t : ((State) s).transitions)
        {
          System.out.println("Adding button for " + t.event);
          JButton b = new JButton(t.event);
          // b.setPreferredSize(new Dimension(80, 40));
          Font font = new Font("Monaco", Font.PLAIN, BUTTON_FONT_SIZE);
          b.setFont(font);
          b.setAlignmentX(JButton.CENTER_ALIGNMENT);
          b.addActionListener(new ActionListener()
          {

            @Override
            public void actionPerformed(ActionEvent e)
            {
              StringWriter w = new StringWriter();
              try
              {
                Delta delta = system.getMachine().step(system, t.event, w);
                deltaQueue.add(delta);
              } catch (IOException e1)
              {
                e1.printStackTrace();
              }
              showMachine(m, status);
            }

            private void showMachine(final Mach m, final JTextArea status)
            {
              StringWriter sw = new StringWriter();
              printMachine(m, sw);
              status.setText(sw.toString());
            }
          });
          events.add(b);
        }
      }
      else if (s instanceof Group)
      {
        states.addAll(((Group) s).states);
      }
    }
  }

  protected void setup()
  {
    final JFrame frame = new JFrame("State machine");
    frame.setLayout(new FlowLayout());
    frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);

    final Container panel = frame.getContentPane();
    panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
    Font font = new Font("Monaco", Font.PLAIN, FONT_SIZE);
    final JTextArea status = new JTextArea(5, 20);
    status.setFont(font);
    JScrollPane logPane = new JScrollPane(status);
    status.setEditable(false);

    final JPanel events = new JPanel();
    // events.setLayout(new BoxLayout(events, BoxLayout.X_AXIS));
    events.setLayout(new FlowLayout(FlowLayout.CENTER, 0, 2));
    Dimension eventsDimension = new Dimension(FRAME_WIDTH, EVENTS_HEIGHT);
    events.setPreferredSize(eventsDimension);
    events.setMaximumSize(eventsDimension);

    Timer poller = new Timer(100, new ActionListener()
    {

      @Override
      public void actionPerformed(ActionEvent arg0)
      {
        Delta d = deltaQueue.poll();
        if (d != null)
        {

          status.setText("applying delta");
          system.apply(d);
          Mach m = system.getMachine();
          StringWriter sw = new StringWriter();
          printMachine(m, sw);
          status.setText(sw.toString());
          events.removeAll();
          addEventButtons(m, frame, events, status);
          frame.pack();
          frame.setSize(FRAME_WIDTH, FRAME_HEIGHT);
          events.invalidate();
          events.repaint();
        }
      }
    });

    panel.add(events);
    panel.add(logPane);

    frame.pack();
    frame.setLocationRelativeTo(null);
    frame.setSize(FRAME_WIDTH, FRAME_HEIGHT);
    frame.setAlwaysOnTop(true);
    frame.setVisible(true);
    poller.start();

  }

  @Override
  public Queue<Delta> getQueue()
  {
    return deltaQueue;
  }

}
