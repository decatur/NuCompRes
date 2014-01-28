
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.Reader;

import java.util.Map;
import java.util.List;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;

import com.mathworks.jmi.Matlab;
import org.octave.Matrix;

/**

@see https://code.google.com/p/matlabcontrol/source/browse/
@see http://svncisd.ethz.ch/repositories/youscope/csb/matlab-scripting/trunk/src/ch/ethz/csb/matlabscripting/JMIWrapper.java
@see http://svncisd.ethz.ch/repositories/youscope/csb/matlab-scripting/trunk/src/ch/ethz/csb/matlabscripting/JMIWrapper.java

Friendly error messages: Limits on content length, see
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\ErrorThresholds
@see http://support.microsoft.com/kb/218155
https://code.google.com/p/information-dynamics-toolkit/wiki/OctaveJavaArrayConversion

*/
public class JavaNuServer implements HttpHandler, Runnable {
    
    public String method;
    public String uri;
    public String requestBody;
    public String[][] requestHeaders;
    public String accept;
    
    public String responseStatus;
    public byte[] responseBodyMatlab;
    public Matrix responseBodyOctave;
    public String responseContentType;

    // This is so 1960-ish, but so is MATLAB/Octave: Avoid boolean-to-numeric cast problems.
    public static int logRequestLine = 1;
    public static int logResponseStatus = 0;
    public static int logHeaders = 0;
    public static int logMethodInvokation = 0;
    public static int logBody = 0;
    
    private boolean isBlocking;
    private HttpServer httpServer;
    private int port;
        
    public static JavaNuServer create(int port, boolean isBlocking) {
    	logMessageByThread("create");
        JavaNuServer server = new JavaNuServer();
        
        server.port = port;
        server.isBlocking = isBlocking;
        
        return server;
    }
    
    private static void logMessageByThread(String msg) {
    	if ( logMethodInvokation == 1 ) {
    		System.out.println(msg + ": " + Thread.currentThread().toString());
    	}
    }

    private static void yield() {
    	logMessageByThread("yield");
        synchronized( JavaNuServer.class )   {
            JavaNuServer.class.notifyAll();
        
            // Pause this thread.
            try {   
                JavaNuServer.class.wait();
            } catch ( InterruptedException e ) {
                e.printStackTrace();
            }
        }
    }
    
    JavaNuServer() {  
    }
    
    public void start() throws IOException {
    	logMessageByThread("start");
        InetSocketAddress adr = new InetSocketAddress(port);
        httpServer = HttpServer.create(adr, 0);
        
        httpServer.createContext("/", this);
        // Default uses the thread which was created by the start() method.
        //httpServer.setExecutor(null);
        httpServer.start();
        System.out.println("Started JavaNuServer on port " + port);
    }
    
    public void stop() throws IOException {
    	logMessageByThread("stop");
        // Stopping is idempotent.
        if ( this.httpServer == null ) return;
    
        this.httpServer.stop(0);
        this.httpServer = null;
        System.out.println("NuServer has now stopped.");
    }
    
    public boolean waitForRequest() throws IOException {
    	logMessageByThread("waitForRequest");
        if ( httpServer == null ) {
            start();
        }

        if ( this.isBlocking ) {
            JavaNuServer.yield();
            return httpServer != null;
        } else {
            return true;
        }
    }
    
    String convertStreamToString(InputStream is) throws IOException {
        // TODO: Pass encoding!
        String encoding = "UTF-8";
        int bufferSize = 1024;
        Reader reader = new BufferedReader(new InputStreamReader(is, encoding));
        StringBuffer content = new StringBuffer();
        char[] buffer = new char[bufferSize];
        int n;
        while ( ( n = reader.read(buffer)) != -1 ) {
            content.append(buffer,0,n);
        }
        return content.toString(); 
    }

    @Override
    public void handle(HttpExchange ex) throws IOException {
    	logMessageByThread("handle");
    	
        String uri = ex.getRequestURI().toASCIIString();
        
        if ( logRequestLine == 1 ) {
        	System.out.println("NuCompRes " + new java.util.Date().toString() +  " " + ex.getRequestMethod() + " " + uri);
        }
        
        Map<String,List<String>> headers = ex.getRequestHeaders();
        this.requestHeaders = new String[headers.size()][2];
        int count = 0;
        
        if ( logHeaders == 1 ) System.out.println("Headers");
        for (Map.Entry<String,List<String>> entry : headers.entrySet()) {
        	if ( logHeaders == 1 ) System.out.print(entry.getKey() + ": ");
            requestHeaders[count][0] = entry.getKey();
            List<String> item = entry.getValue();
            requestHeaders[count][1] = "";
            String sep = "";
            for (int i=0; i<item.size(); i++) {
            	if ( logHeaders == 1 ) System.out.print(sep + item.get(i));
                requestHeaders[count][1] += sep + item.get(i);
                sep = ";";
            }
            if ( logHeaders == 1 ) System.out.print("\n");
            count++;
        }
        
        try {

            InputStream is = ex.getRequestBody();
            String requestBody = convertStreamToString(is);
            is.close();
            
            this.responseBodyOctave = null;
            this.responseBodyMatlab = null;
            
            this.method = ex.getRequestMethod();
            this.uri = uri;
            this.requestBody = requestBody;
            this.accept = ex.getRequestHeaders().getFirst("Accept");
            
            if ( this.isBlocking ) {
                JavaNuServer.yield();
            } else {
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

            
            byte[] rb;
            
            if ( this.responseBodyOctave != null ) {
            	rb = this.responseBodyOctave.toByte();
        	} else if ( this.responseBodyMatlab != null ) {
            	rb = responseBodyMatlab;
        	} else {
        		rb = new byte[]{};
        	}
            
            if ( logRequestLine == 1 ) {
                System.out.println("Response Status: " + this.responseStatus);
            }
            
            ex.getResponseHeaders().add("Content-Type", this.responseContentType + ";charset=utf-8");
            ex.getResponseHeaders().add("Cache-Control", "no-cache");
            ex.getResponseHeaders().add("Pragma", "no-cache");
            ex.getResponseHeaders().add("Expires", "-1");
            
            int statusCode = Integer.parseInt(this.responseStatus.substring(0, 3));
            boolean stopping = false;
            
            if ( statusCode == 999 ) {
            	stopping = true;
            	statusCode = 200;
            }
            
            ex.sendResponseHeaders(statusCode, rb.length);
            OutputStream os = ex.getResponseBody();
            os.write(rb);
            os.close();
            ex.close();
            
            if ( stopping ) {
            	// Only now can we stop the HTTP-Server and wake up the MATLAB thread.
                this.stop();
                synchronized( JavaNuServer.class )   {
                    JavaNuServer.class.notifyAll();
                }
            }
        
        } catch (Exception e) {
            e.printStackTrace();
            //this.stop();
            //synchronized( JavaNuServer.class )   {
            //    JavaNuServer.class.notifyAll();
            //}
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
    
    public void debugOctave() {
    	System.out.println(this.responseBodyOctave);
    	System.out.println(this.responseBodyOctave.getClassName());
    	
    	byte[] rb = this.responseBodyOctave.toByte();
    	
    	for (int i=0; i<rb.length; i++) System.out.print(rb[i]);
    }
    

}
