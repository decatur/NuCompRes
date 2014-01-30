
import org.octave.Matrix;

/**

https://code.google.com/p/information-dynamics-toolkit/wiki/OctaveJavaArrayConversion

*/
public class JavaNuServerOctave extends JavaNuServer {
    
    public Matrix responseBodyOctave;

    public JavaNuServerOctave(int port) {
        //logMessageByThread("create");
        this.port = port;
        this.isBlocking = true;
    }
    
    @Override
    void requestInit() {
        responseBodyOctave = null;
    }
    
    @Override
    byte[] getResponseBytes() {
        responseBodyOctave.toByte();
        if ( responseBodyOctave != null ) return responseBodyOctave.toByte();
        else return new byte[]{};
    }
    
    public void debugOctave() {
    	System.out.println(this.responseBodyOctave);
    	System.out.println(this.responseBodyOctave.getClassName());
    	
    	byte[] rb = this.responseBodyOctave.toByte();
    	
    	for (int i=0; i<rb.length; i++) System.out.print(rb[i]);
    }
    

}
