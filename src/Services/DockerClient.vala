/*
 * Copyright (c) 2021 Andrew Vojak (https://avojak.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Andrew Vojak <andrew.vojak@gmail.com>
 */

public class WhaleWatcher.Services.DockerClient : WhaleWatcher.Services.SocketRestClient {

    private const string SOCKET_FILE = "/var/run/docker.sock";
    private const string API_VERSION = "v1.41";

    private static WhaleWatcher.Services.DockerClient _instance = null;

    public static WhaleWatcher.Services.DockerClient instance {
        get {
            if (_instance == null) {
                _instance = new WhaleWatcher.Services.DockerClient ();
            }
            return _instance;
        }
    }

    private DockerClient () {
        Object (
            socket_file: SOCKET_FILE
        );
    }

    public void ping () {
        get_sync (@"/$API_VERSION/_ping");

        //  var session = new Soup.Session ();
        //  var message = new Soup.Message ("GET", "unix:///var/run/docker.sock/_ping");
        //  session.send_message (message);
        //  //  print ((string) message.response_body.flatten ().data + "\n");
        //  // Process the result:
        //  message.response_headers.foreach ((name, val) => {
        //      print ("%s = %s\n", name, val);
        //  });

        //  print ("Status Code: %u\n", message.status_code);
        //  print ("Message length: %lld\n", message.response_body.length);
        //  print ("Data: \n%s\n", (string) message.response_body.data);
    }

    public void get_info () {
        get_sync (@"/$API_VERSION/info");
    }

    //  public void get_info () {
    //      //  var uri = "unix:///var/run/docker.sock/info";
    //      //  var session = new Soup.Session ();
    //      //  var message = new Soup.Message ("GET", uri);
    //      //  debug ("sending...");
    //      //  session.send_message (message);
    //      //  debug ("done");
    //      //  print ((string) message.response_body.flatten ().data);

    //      var host = "http://localhost/info";

    //      try {
    //          // Resolve hostname to IP address
    //          //  var resolver = Resolver.get_default ();
    //          //  var addresses = resolver.lookup_by_name (host, null);
    //          //  var address = addresses.nth_data (0);
    //          //  print (@"Resolved $host to $address\n");

    //          // Connect
    //          var client = new SocketClient ();
    //          var conn = client.connect (new InetSocketAddress (new InetAddress.from_string ("/var/run/docker.sock"), 80));
    //          print (@"Connected to $host\n");

    //          // Send HTTP GET request
    //          var message = @"GET / HTTP/1.1\r\n\r\n";
    //          conn.output_stream.write (message.data);
    //          print ("Wrote request\n");

    //          // Receive response
    //          var response = new DataInputStream (conn.input_stream);
    //          var status_line = response.read_line (null).strip ();
    //          print ("Received status line: %s\n", status_line);

    //      } catch (Error e) {
    //          stderr.printf ("%s\n", e.message);
    //      }

    //      //  try {
    //      //      var parser = new Json.Parser ();
    //      //      parser.load_from_data ((string) message.response_body.flatten ().data, -1);

    //      //      var root_object = parser.get_root ().get_object ();
    //      //      print (Json.to_string (parser.get_root (), true));
    //      //  } catch (Error e) {
    //      //      stderr.printf ("I guess something is not working...\n");
    //      //  }
    //  }

    public void get_version() {
        get_sync (@"/$API_VERSION/version");
    }

    public void get_images () {
        get_sync (@"/$API_VERSION/images/json");
    }

}
