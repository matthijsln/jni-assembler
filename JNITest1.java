public class JNITest1 {
    static native int inc(int i);

    public static void main(String[] args) {
        /* Load the library containing the inc() function */
        System.loadLibrary("JNICode1");

        /* Call the native method */
        System.out.println("" + inc(1));
    }
}
