
import com.mathworks.jmi.Matlab;

/**

@see https://code.google.com/p/matlabcontrol/source/browse/
@see http://svncisd.ethz.ch/repositories/youscope/csb/matlab-scripting/trunk/src/ch/ethz/csb/matlabscripting/JMIWrapper.java
@see http://svncisd.ethz.ch/repositories/youscope/csb/matlab-scripting/trunk/src/ch/ethz/csb/matlabscripting/JMIWrapper.java

*/
public class JavaNuServerMatlab extends JavaNuServer implements Runnable {
    
    public JavaNuServerMatlab(int port) {
        //logMessageByThread("create");
        this.port = port;
        this.isBlocking = false;
    }
    
    @Override
    void enterComputationalThread() {
        System.out.println("JavaNuServerMatlab.enterComputationalThread");
        
        Matlab.whenMatlabIdle(this);
            
        // Pause this handler thread.
        synchronized( JavaNuServer.class )   {
            try {   
                JavaNuServer.class.wait();
            } catch ( InterruptedException e ) {
                e.printStackTrace();
            }
        }
    }

    public void run() {
        // Called from matlab main thread.
        System.out.println("MatlabFevalCommand now running ...");
        try {
            // See methodsview('com.mathworks.jmi.Matlab')
            Matlab.mtFevalConsoleOutput("NuServerJavaProxy", new Object[]{this}, 0);
        } catch (Exception e) {
            e.printStackTrace();
            // This should not happen as NuServerJavaProxy must handle all exceptions
        }
        
        // Wake up handler thread.
        synchronized( JavaNuServer.class )   {
            JavaNuServer.class.notifyAll();
        }
            
    }

}
