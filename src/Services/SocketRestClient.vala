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

public abstract class WhaleWatcher.Services.SocketRestClient : GLib.Object {

    private enum HttpMethod { 
        GET,
        POST;

        public string to_string () {
            switch (this) {
                case GET:
                    return "GET";
                case POST:
                    return "POST";
                default:
                    assert_not_reached ();
            }
        }
    }

    private const string REQUEST_MESSAGE_FORMAT = "%s %s HTTP/1.1\r\nHost:\r\n\r\n";

    public string socket_file { get; construct; }

    SocketRestClient (string socket_file) {

    }

    protected string? get_sync (string endpoint) {
        debug ("Executing %s request to %s", HttpMethod.GET.to_string (), endpoint);
        return send_request (HttpMethod.GET, endpoint);
    }

    protected void post_sync () {
        // TODO
    }

    private string? send_request (HttpMethod method, string endpoint) {
        IOStream connection = connect_to_socket ();
        DataInputStream input_stream = new DataInputStream (connection.input_stream);
        DataOutputStream output_stream = new DataOutputStream (connection.output_stream);

        //  var message = "GET /_ping HTTP/1.1\r\nHost:\0\r\n\r\n";
        send_output (output_stream, REQUEST_MESSAGE_FORMAT.printf (method.to_string (), endpoint));
        //  send_output (output_stream, message);

        Cancellable cancellable = new Cancellable ();
        uint status_code = read_status_code (input_stream, cancellable);
        Soup.MessageHeaders headers = read_headers (input_stream, cancellable);
        string? body = read_body (headers, input_stream, cancellable);

        // TODO: Remove this
        debug (body);

        if (is_error (status_code)) {
            warning (body);
        }

        //  int content_length = 0;
        //  string line = "";
        //  Cancellable cancellable = new Cancellable ();
        //  do {
        //      try {
        //          line = input_stream.read_line_utf8 (null, cancellable);
        //          //  handle_line (line);
        //          if (WhaleWatcher.Application.is_dev_mode ()) {
        //              debug (@"$line\n");
        //          }
        //          if (line.contains ("Content-Length: ")) {
        //              content_length = int.parse (line.substring (15));
        //              debug (content_length.to_string ());
        //          }
        //          if (line.chomp ().chug ().length == 0) {
        //              debug ("Reading %d bytes", content_length);
        //              try {
        //                  string data = (string) input_stream.read_bytes (content_length, cancellable).get_data ();
        //                  print (data + "\n");
        //                  break;
        //              } catch (GLib.Error e) {
        //                  warning ("Error while reading payload data: %s\n", e.message);
        //              }
        //          }
        //      } catch (GLib.IOError e) {
        //          // TODO: Handle this differently on initialization (currently fails silently in the background)
        //          critical ("IOError while reading: %s\n", e.message);
        //          return "";
        //      }
        //  } while (should_keep_reading (line));
        
        try {
            connection.close ();
        } catch (GLib.IOError e) {
            warning ("IOError while closing socket connection: %s\n", e.message);
        } finally {
            cancellable.cancel ();
        }
        return body;   
    }

    private uint? read_status_code (DataInputStream input_stream, Cancellable? cancellable) {
        try {
            var line = input_stream.read_line_utf8 (null, cancellable).strip ();
            return uint.parse (line.split (" ")[1]);
        } catch (GLib.IOError e) {
            critical ("IOError while reading status: %s\n", e.message);
            return null;
        }
    }

    private Soup.MessageHeaders? read_headers (DataInputStream input_stream, Cancellable? cancellable) {
        var headers = new Soup.MessageHeaders (Soup.MessageHeadersType.RESPONSE);
        string line = null;
        try {
            while ((line = input_stream.read_line_utf8 (null, cancellable).strip ()) != "") {
                if (WhaleWatcher.Application.is_dev_mode ()) {
                    debug (@"$line\n");
                }
                int split_index = line.index_of (": ");
                headers.append (line.substring (0, split_index), line.substring (split_index + 2));
            }
        } catch (GLib.IOError e) {
            critical ("IOError while reading headers: %s\n", e.message);
            return null;
        }
        return headers;
    }

    private string? read_body (Soup.MessageHeaders headers, DataInputStream input_stream, Cancellable? cancellable) {
        if (headers.get_one ("Transfer-Encoding") == "chunked") {
            return read_chunked (input_stream, cancellable);
        } else if (headers.get_one ("Content-Length") != null) {
            int content_length = int.parse (headers.get_one ("Content-Length"));
            return read_content (input_stream, content_length, cancellable);
        } else {
            // TODO: Handle this! Read until end of stream
            assert_not_reached ();
        }
    }

    private string? read_content (DataInputStream input_stream, int content_length, Cancellable? cancellable) {
        try {
            //  size_t length;
            uint8[] buffer = new uint8[content_length]; //new uint8[int.MAX];
            ssize_t length = input_stream.read (buffer, cancellable);
            //  print (length.to_string ());
            //  buffer[length] = '\0';
            string line = (string) buffer;

            //  uint8[] data = input_stream.read_bytes (content_length, cancellable).get_data ();
            //  string line = (string) data[0:data.length - "\r\n\r\n".length];
            
            //  print(line);
            //  print(length.to_string ());
            //  line = input_stream.read_line_utf8 (out length, cancellable);
            //  print(line);
            //  print(length.to_string ());
            if (WhaleWatcher.Application.is_dev_mode ()) {
                debug (@"$line\n");
            }
            return line;
        } catch (GLib.Error e) {
            critical ("Error while reading content: %s\n", e.message);
            return null;
        }
    }

    private string? read_chunked (DataInputStream input_stream, Cancellable? cancellable) {
        try {
            string line = null;
            while ((line = input_stream.read_line_utf8 (null, cancellable).strip ()) != "") {
                if (WhaleWatcher.Application.is_dev_mode ()) {
                    debug (@"$line\n");
                }
                //  int split_index = line.index_of (":");
                //  headers.append (line.substring (0, split_index), line.substring (split_index + 2, line.length));
            }
            return line;
        } catch (GLib.IOError e) {
            critical ("IOError while reading chunked content: %s\n", e.message);
            return null;
        }
    }

    private string? read_chunk () {
        // TODO
        return null;
    }

    private bool should_keep_reading (string? line) {
        return line != null;
        //  lock (should_exit) {
        //      return line != null && !should_exit;
        //  }
    }

    private IOStream? connect_to_socket () {
        try {
            SocketClient client = new SocketClient ();
            client.set_timeout (30);
            client.event.connect (on_socket_client_event);
            return client.connect (new UnixSocketAddress (socket_file));
        } catch (GLib.Error e) {
            critical ("Error while connecting to socket: %s\n", e.message);
            // TODO: Handle errors!!
        }
        return null;
    }

    private void on_socket_client_event (SocketClientEvent event, SocketConnectable connectable, IOStream? connection) {
        // See https://valadoc.org/gio-2.0/GLib.SocketClient.event.html for event definitions
        switch (event) {
            case SocketClientEvent.COMPLETE:
                debug ("[SocketClientEvent] %s COMPLETE", connectable.to_string ());
                break;
            case SocketClientEvent.CONNECTED:
                debug ("[SocketClientEvent] %s CONNECTED", connectable.to_string ());
                break;
            case SocketClientEvent.CONNECTING:
                debug ("[SocketClientEvent] %s CONNECTING", connectable.to_string ());
                break;
            case SocketClientEvent.PROXY_NEGOTIATED:
                debug ("[SocketClientEvent] %s PROXY_NEGOTIATED", connectable.to_string ());
                break;
            case SocketClientEvent.PROXY_NEGOTIATING:
                debug ("[SocketClientEvent] %s PROXY_NEGOTIATING", connectable.to_string ());
                break;
            case SocketClientEvent.RESOLVED:
                debug ("[SocketClientEvent] %s RESOLVED", connectable.to_string ());
                break;
            case SocketClientEvent.RESOLVING:
                debug ("[SocketClientEvent] %s RESOLVING", connectable.to_string ());
                break;
            case SocketClientEvent.TLS_HANDSHAKED:
                debug ("[SocketClientEvent] %s TLS_HANDSHAKED", connectable.to_string ());
                break;
            case SocketClientEvent.TLS_HANDSHAKING:
                debug ("[SocketClientEvent] %s TLS_HANDSHAKING", connectable.to_string ());
                //  ((TlsClientConnection) connection).accept_certificate.connect ((peer_cert, errors) => {
                //      return on_invalid_certificate (peer_cert, errors, connectable);
                //  });
                break;
            default:
                // Do nothing - per documentation, unrecognized events should be ignored as there may be
                // additional event values in the future
                break;
        }
    }

    private void send_output (DataOutputStream output_stream, string output) {
        try {
            debug ("Sending output: %s", output);
            bool res = output_stream.put_string (@"$output");
            debug ("done sending: %s", res ? "success" : "failure");
        } catch (GLib.IOError e) {
            critical ("Error while sending output for server connection: %s", e.message);
            // TODO: Handle errors!!
        }
    }

    private bool is_error (uint status_code) {
        bool is_4xx = status_code.to_string ()[0] == '4';
        bool is_5xx = status_code.to_string ()[0] == '5';
        return is_4xx || is_5xx;
    }

}