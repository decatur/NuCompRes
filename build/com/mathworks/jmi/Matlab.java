package com.mathworks.jmi;


public class Matlab {

	private static String MSG = "This is a compile-time stub only!"; 
	
	public static void whenMatlabIdle(Runnable r) {
		throw new RuntimeException(MSG);
	}

	public static void mtFevalConsoleOutput(String string, Object[] objects,
			int i) {
		throw new RuntimeException(MSG);
	}

}
