
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

/**

Friendly error messages: Limits on content length, see
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\ErrorThresholds
@see http://support.microsoft.com/kb/218155

*/
public class JavaNuServer implements HttpHandler {
    
    public String method;
    public String uri;
    public String requestBody;
    public String[][] requestHeaders;
    public String accept;
    
    public String responseStatus;
    public byte[] responseBodyMatlab;
    public String responseContentType;

    // This is so 1960-ish, but so is MATLAB/Octave: Avoid boolean-to-numeric cast problems.
    public int logRequestLine = 1;
    public int logResponseStatus = 0;
    public int logHeaders = 0;
    public int logMethodInvokation = 1;
    public int logBody = 0;
    
    public boolean isBlocking;
    
    int port;
    private HttpServer httpServer;
    
    public JavaNuServer(int port) {
        //logMessageByThread("create");
        this.port = port;
        this.isBlocking = true;
    }
    
    private void logMessageByThread(String msg) {
    	if ( logMethodInvokation == 1 ) {
    		System.out.println(msg + ": " + Thread.currentThread().toString());
    	}
    }

    private void yield() {
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
            yield();
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

    void requestInit() {
        this.responseBodyMatlab = null;
    }
    
    byte[] getResponseBytes() {
        if ( responseBodyMatlab != null ) return responseBodyMatlab;
        else return new byte[]{};
    }
    
    void enterComputationalThread() {
        logMessageByThread("enterComputationalThread");
        yield();
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
            
            requestInit();
            
            this.method = ex.getRequestMethod();
            this.uri = uri;
            this.requestBody = requestBody;
            this.accept = ex.getRequestHeaders().getFirst("Accept");
            
            enterComputationalThread();
            
            byte[] rb = getResponseBytes();
            
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



}
