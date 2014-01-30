# Compile the Java Classes

## *nix
export JAVA_HOME=<Path to Java Installation>
export MATLAB_HOME=<Path to MATLAB Installation>
export OCTAVE_HOME=<Path to Octave Installation>

$JAVA_HOME/bin/javac -source 1.6 -target 1.6 JavaNuServer.java
$JAVA_HOME/bin/javac -cp ./:$MATLAB_HOME/java/jar/jmi.jar -source 1.6 -target 1.6 JavaNuServerMatlab.java
$JAVA_HOME/bin/javac -cp ./:$OCTAVE_HOME/share/octave/packages/java-1.2.9/octave.jar -source 1.6 -target 1.6 JavaNuServerMatlab.java

## MS Windows
export JAVA_HOME=<Path to Java Installation>
export MATLAB_HOME=<Path to MATLAB Installation>
export OCTAVE_HOME=<Path to Octave Installation>

%JAVA_HOME%\bin\javac -source 1.6 -target 1.6 JavaNuServer.java
%JAVA_HOME%\bin\javac -cp ./;%MATLAB_HOME%/java/jar/jmi.jar -source 1.6 -target 1.6 JavaNuServerMatlab.java
%JAVA_HOME%\bin\javac -cp ./;%OCTAVE_HOME%/share/octave/packages/java-1.2.9/octave.jar -source 1.6 -target 1.6 JavaNuServerOctave.java

## Java-Interface lameness

Both MATLAB and Octave have issues when interoperation with Java.

### MATLABs errorneous Error Messages

Whenever MATLAB cannot load a class, for whatever reason so it seems, the same
(and therefore wrong in many cases) error message is given

    The class "JavaNuServer" is undefined.
    Perhaps Java is not running.
