/*
 * Java Native Interface/NASM example
 * Copyright (C) Matthijs Laan <matthijsln@xs4all.nl>, February 10th 2002
 */

/*
 * Output should be something like this:
 *
 * Java Native Interface/NASM example
 * Copyright (C) Matthijs Laan <matthijsln@xs4all.nl>, February 10th 2002
 *
 * add(23, 53): 76
 * callInstanceMethod(this):
 *   ...instanceCallback(123) called
 * callStaticMethod(this.getClass()):
 *   ...staticCallback(13) called
 * sumIntArray({-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9}): 44
 * reverseASCIIString("Hello, World!"): !dlroW ,olleH
 * reverseASCIIString("HOll), W(rld!"):
 *   ...exception:
 * java.lang.IllegalArgumentException: String passed to reverseASCIIString() is not ASCII
 *         at JNITest.reverseASCIIString(Native Method)
 *         at JNITest.<init>(JNITest.java:123)
 *         at JNITest.main(JNITest.java:153)
 * staticField = 123
 * changeStaticField():
 * staticField = 124
 * instanceField = 456
 * changeInstanceField():
 * instanceField = 457
 * pi(): 3.141592653589793
 * sqrt(2): 1.4142135623730951
 * CPUID available
 * Vendor ID: AuthenticAMD
 * Brand string: AMD Athlon(tm) Processor
 *
 */

public class JNITest {
    static {
        System.loadLibrary("JNITest");
    }

    /* Add two ints */
    public static native int add(int a, int b);

    /* Call an instance method of an object */
    public static native void callInstanceMethod(Object obj);

    /* Call a static method of a class */
    public static native void callStaticMethod(Class clazz);

    /* Add all integers in an array */
    public static native int sumIntArray(int[] array);

    /* Reverse an ASCII string, and possibly throw an exception */
    public static native String reverseASCIIString(String str) throws IllegalArgumentException;

    /* Change a static field of the class of the "this" object */
    public native void changeStaticField();

    /* Change an instance field of the "this" object */
    public native void changeInstanceField();

    /* Return pi */
    public static native double pi();

    /* Return the square root of a double */
    public static native double sqrt(double v);

    /* Does the CPU support the CPUID instruction (Pentium or higher) */
    public static native boolean haveCPUID();

    /* Return the CPU's ID string */
    public static native String vendorID();

    /* Return the CPU's brand string (only on new CPU's) */
    public static native String brandString();

    static int staticField = 123;
    int instanceField = 456;

    public static void staticCallback(int a) {
        System.out.println("  ...staticCallback(" + a + ") called");
    }

    public void instanceCallback(int a) {
        System.out.println("  ...instanceCallback(" + a + ") called");
    }

    private static void printArray(int[] array) {
        System.out.print("{");

        for(int i=0;i<array.length;i++) {
            System.out.print((i>0?", ":"") + array[i]);
        }

        System.out.print("}");
    }

    public JNITest() {
        System.out.println("Java Native Interface/NASM example");
        System.out.println("Copyright (C) Matthijs Laan <matthijsln@xs4all.nl>, February 10th 2002\n");

        System.out.println("add(23, 53): " + add(23, 53));

        System.out.println("callInstanceMethod(this):");
        callInstanceMethod(this);

        System.out.println("callStaticMethod(this.getClass()):");
        callStaticMethod(this.getClass());

        int[] array = new int[] {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9};

        System.out.print("sumIntArray(");
        printArray(array);
        System.out.println("): " + sumIntArray(array));

        System.out.println("reverseASCIIString(\"Hello, World!\"): " + reverseASCIIString("Hello, World!"));

        System.out.print("reverseASCIIString(\"Hêllõ, Wôrld!\"): ");
        try {
            System.out.print(reverseASCIIString("Hêllõ, Wôrld!"));
        } catch(IllegalArgumentException e) {
            System.out.println("\n  ...exception:");
            e.printStackTrace();
        }

        System.out.println("staticField = " + staticField);
        System.out.println("changeStaticField():");
        changeStaticField();
        System.out.println("staticField = " + staticField);

        System.out.println("instanceField = " + instanceField);
        System.out.println("changeInstanceField():");
        changeInstanceField();
        System.out.println("instanceField = " + instanceField);

        System.out.println("pi(): " + pi());

        System.out.println("sqrt(2): " + sqrt(2));

        if(haveCPUID()) {
            System.out.println("CPUID available");
            System.out.println("Vendor ID: " + vendorID());
            System.out.println("Brand string: " + brandString());
        } else {
            System.out.println("CPUID not available");
        }
    }

    public static void main(String[] args) {
        new JNITest();
    }
}