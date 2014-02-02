
import org.octave.Matrix;

/**

Test some quirks and bugs in the Octave<->Java data mapping.
It seems that double array are well supported, but byte arrays are not.
Even more bugs are reported for matrices, see
https://code.google.com/p/information-dynamics-toolkit/wiki/OctaveJavaArrayConversion

However, we only want to find a stable solution for byte array mapping.
This is tested only with Octave Release 3.6.4

Usage:
    javaaddpath('test');
    obj = javaObject('TestJavaNuServerOctave');
    
    java_unsigned_conversion(0);    % Correct setting
    java_convert_matrix(1);         % Correct setting
    obj.setLength(3);
    obj.m                           % Java -> Octave: Returns [0 -1 2]
    obj.dump();                     % Prints [0 -1 2]
    obj.m = int8([2 -1 0]);         % Octave -> Java
    obj.dump();                     % Prints [2 -1 0]
  
    % Passing scalar value
    obj.setLength(1);
    obj.m                           % Java -> Octave: Returns [0]
    obj.m = int8([2]);              % Octave -> Java
    obj.dump();                     % Prints null
    
    % Passing empty
    obj.setLength(0);
    obj.m                           % Java -> Octave: Returns []
    obj.m = int8([]);               % Octave -> Java: java.lang.NullPointerException
  
    obj.setBytes(int8([2 -1 0]), 3);
    obj.dump();                     % Prints [2 -1 0]
    paddingByte = 0;
    obj.setBytes(int8([2 paddingByte]), 1);
    obj.dump();                     % Prints [2]
    obj.setBytes(int8([paddingByte]), 0);
    obj.dump();                     % Prints null
    
    
    obj.setLength(3);
    
    java_unsigned_conversion(1);    % Incorrect setting
    java_convert_matrix(1);         % Correct setting
    obj.m                           % Java -> Octave: Returns [0 255 2]
    obj.m = int8([2 -1 0]);         % Octave -> Java
    obj.dump();                     % Prints [2 -1 0]
    
    java_unsigned_conversion(0);    % Correct setting; Setting to 1 does not change behaviour.
    java_convert_matrix(0);         % Incorrect setting
    obj.m                           % Java -> Octave: Returns <Java object: org.octave.Matrix>
    obj.m = uint8([2 -1 0]);        % Octave -> Java: Sets obj.m to null.
    obj.dump();                     % Prints null

*/
public class TestJavaNuServerOctave {
    
    public Matrix m;

    public TestJavaNuServerOctave() {
    }
    
    // Creates a sample byte array of specified length.
    public void setLength(int l) {
        byte[] data = new byte[l];
        int sign = 1;
        for (int i=0; i<l; i++, sign*=-1) {
            data[i] = (byte) (sign*i);
        }
        m = new Matrix(data, new int[]{1, data.length});
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
    
    public void dump() {
        System.out.println(m==null?"null":m.toString());
    }
    

}
