
import org.octave.Matrix;

/**

https://code.google.com/p/information-dynamics-toolkit/wiki/OctaveJavaArrayConversion

*/
public class JavaNuServerOctave extends JavaNuServer {
    
    public Matrix requestBody;
    private Matrix m;

    public JavaNuServerOctave(int port) {
        //logMessageByThread("create");
        this.port = port;
        this.isBlocking = true;
    }
    
    @Override
    void requestInit() {
        m = null;
    }
    
    /*
     * Workaround for Octaves byte mapping bugs. Usage from Octave
     *   obj.setBytes([data 0], length(data))
     * where data is a 1xN array of int8.
    */
    public void setBytes(Matrix data, int length) {
        if ( length > 1 ) m = data;
        else if ( length == 1 ) m = new Matrix(new byte[]{data.toByte()[0]}, new int[]{1, length});
        else if ( length == 0 ) m = null;
        else throw new IllegalArgumentException();
    }
    
    @Override
    void setRequestBytes(byte[] body) {
        requestBody = new Matrix(body, new int[]{1, body.length});
    }
    
    @Override
    byte[] getResponseBytes() {
        if ( m != null ) return m.toByte();
        else return new byte[]{};
    }
}
