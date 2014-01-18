
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


/**

@see https://code.google.com/p/matlabcontrol/source/browse/
@see http://svncisd.ethz.ch/repositories/youscope/csb/matlab-scripting/trunk/src/ch/ethz/csb/matlabscripting/JMIWrapper.java
@see http://svncisd.ethz.ch/repositories/youscope/csb/matlab-scripting/trunk/src/ch/ethz/csb/matlabscripting/JMIWrapper.java

Friendly error messages: Limits on content length, see
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\ErrorThresholds
@see http://support.microsoft.com/kb/218155

*/
public class JavaNuServer implements HttpHandler, Runnable {
    
    public String method;
    public String uri;
    public String requestBody;
    public String[][] requestHeaders;
    public String accept;
    
    public String responseStatus;
    public String responseBody;
    public String responseContentType;

    public String logLevel = "DEBUG";
    private boolean DEBUG = false;
    private boolean isdeployed;
    private HttpServer httpServer;
    private int port;
        
    public static JavaNuServer create(int port, boolean isdeployed) {
        //System.out.println("JavaNuServer currentThread " + Thread.currentThread().getId());
        JavaNuServer server = new JavaNuServer();
        
        server.port = port;
        server.isdeployed = isdeployed;
        
        return server;
    }

    private static void yield() {
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
        DEBUG = logLevel.equals("DEBUG");
        InetSocketAddress adr = new InetSocketAddress(port);
        httpServer = HttpServer.create(adr, 0);
        
        httpServer.createContext("/", this);
        // Default uses the thread which was created by the start() method.
        //httpServer.setExecutor(null);
        httpServer.start();
        System.out.println("Started JavaNuServer on port " + port);
    }
    
    public void stop() throws IOException {
        // Stopping is idempotent.
        if ( this.httpServer == null ) return;
    
        this.httpServer.stop(0);
        this.httpServer = null;
        System.out.println("NuServer has now stopped.");
    }
    
    public boolean waitForRequest() throws IOException {
        if ( httpServer == null ) {
            start();
        }

        if ( this.isdeployed ) {
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
        String uri = ex.getRequestURI().toASCIIString();
        
        if ( DEBUG ) {
            System.out.println("JavaNuServer: " + ex.getRequestMethod() + " " + uri);
            Map<String,List<String>> headers = ex.getRequestHeaders();
            System.out.println("Headers");
            for (Map.Entry<String,List<String>> entry : headers.entrySet()) {
                System.out.print(entry.getKey() + ": ");
                List<String> item = entry.getValue();
                for (int i=0; i<item.size(); i++) {                    
                    System.out.print(item.get(i) + "; ");
                }
                System.out.print("\n");
            }
            // System.out.println("JavaNuServer: " + ex.getRequestHeaders());
        }
        
        Map<String,List<String>> headers = ex.getRequestHeaders();
        this.requestHeaders = new String[headers.size()][2];
        int count = 0;
        
        System.out.println("Headers");
        for (Map.Entry<String,List<String>> entry : headers.entrySet()) {
            System.out.print(entry.getKey() + ": ");
            requestHeaders[count][0] = entry.getKey();
            List<String> item = entry.getValue();
            requestHeaders[count][1] = "";
            String sep = "";
            for (int i=0; i<item.size(); i++) {                    
                requestHeaders[count][1] += sep + item.get(i);
                sep = ";";
            }
            System.out.print("\n");
            count++;
        }
        
        try {

            InputStream is = ex.getRequestBody();
            String requestBody = convertStreamToString(is);
            is.close();
            
            this.method = ex.getRequestMethod();
            this.uri = uri;
            this.requestBody = requestBody;
            this.accept = ex.getRequestHeaders().getFirst("Accept");
            
            if ( DEBUG ) {
                System.out.println("Scheduling function");
            }            
            
            if ( this.isdeployed ) {
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
            
            String status = this.responseStatus;
            String responseBody = this.responseBody;
            
            if ( DEBUG ) {
                System.out.println("Response: " + 
                    status + '\n' + responseBody);
            }
            
            ex.getResponseHeaders().add("Content-Type", this.responseContentType);
            ex.getResponseHeaders().add("Cache-Control", "no-cache");
            ex.getResponseHeaders().add("Pragma", "no-cache");
            ex.getResponseHeaders().add("Expires", "-1");

            if ( responseBody == null ) responseBody = "";
            
            ex.sendResponseHeaders(Integer.parseInt(status.substring(0, 3)), responseBody.length());
            OutputStream os = ex.getResponseBody();
            os.write(responseBody.getBytes());
            os.close();
            ex.close();
        
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        if ( uri.matches("^/admin/stop(/)?") ) {
            this.httpServer.stop(0);
            this.httpServer = null;
            JavaNuServer.yield();
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
