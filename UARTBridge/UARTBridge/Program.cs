using System.Globalization;
using System.IO.Ports;

public static class Entrypoint {
    private static bool closing = false;

    private static SerialPort input_port  = null!;
    private static SerialPort output_port = null!;

    private static Thread uart_thread = null!;

    private static void UARTRoutine() {
        byte[] data = [0];

        while (!closing) {
            try {
                data[0] = (byte) input_port.ReadByte();
                output_port.Write(data, 0, 1);
            } catch (Exception e) {
                Console.WriteLine(e);
            }
        }
    }

    private static void PrintingUARTRoutine() {
        byte[] data = [0];

        while (!closing) {
            try {
                data[0] = (byte) input_port.ReadByte();
                Console.WriteLine(data[0].ToString(NumberFormatInfo.CurrentInfo));
                output_port.Write(data, 0, 1);
            } catch (Exception e) {
                Console.WriteLine(e);
            }
        }
    }

    private static void Main(string[] args) {
        Console.WriteLine("These are the following COM devices:");
        var device_port_names = SerialPort.GetPortNames();
        foreach (var port_name in device_port_names) {
            Console.WriteLine($" . {port_name}");
        }

        var input_name  = string.Empty;
        var output_name = string.Empty;

        while (!device_port_names.Contains(input_name)) {
            Console.WriteLine("Please enter the name of input device:");
            input_name = Console.ReadLine() ?? string.Empty;

            if (!device_port_names.Contains(input_name))
                Console.WriteLine("Invalid Port Name!");
        }

        while (!device_port_names.Contains(output_name)) {
            Console.WriteLine("Please enter the name of output device:");
            output_name = Console.ReadLine() ?? string.Empty;

            if (!device_port_names.Contains(output_name))
                Console.WriteLine("Invalid Port Name!");
        }

        Console.WriteLine("Print transmitted bytes: [y/n]");
        var key = Console.ReadKey();

        input_port  = new SerialPort(input_name,  9600, Parity.None, 8, StopBits.One);
        output_port = new SerialPort(output_name, 9600, Parity.None, 8, StopBits.One);

        input_port.ReadTimeout = 10000;
        input_port.DtrEnable   = true;

        input_port.Open();
        output_port.Open();

        uart_thread = new Thread(key.Key == ConsoleKey.Y ? PrintingUARTRoutine : UARTRoutine);

        uart_thread.Start();

        Console.WriteLine("Bridging Data...");
        Console.WriteLine("Press enter to exit...");
        Console.ReadLine();

        Console.WriteLine("Terminating...");

        closing = true;
        uart_thread.Join();

        input_port.Close();
        output_port.Close();

        input_port.Dispose();
        output_port.Dispose();

        Console.WriteLine("Successfully terminated.");
    }
}