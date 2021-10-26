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
        POST,
        DELETE;

        public string to_string () {
            switch (this) {
                case GET:
                    return "GET";
                case POST:
                    return "POST";
                case DELETE:
                    return "DELETE";
                default:
                    assert_not_reached ();
            }
        }
    }

    private const int SOCKET_TIMEOUT = 30;
    private const string CRLF = "\r\n";
    private const string REQUEST_MESSAGE_FORMAT = "%s %s%s HTTP/1.1\r\nHost:\r\n\r\n";
    private const size_t BUFFER_SIZE = 256;

    public string socket_file { get; construct; }

    protected string? test_socket () {
        IOStream connection;
        try {
            SocketClient client = new SocketClient ();
            client.set_timeout (SOCKET_TIMEOUT);
            client.event.connect (on_socket_client_event);
            connection = client.connect (new UnixSocketAddress (socket_file));
        } catch (GLib.Error e) {
            critical ("Error while connecting to socket: %s", e.message);
            return e.message;
        }
        try {
            connection.close ();
        } catch (GLib.IOError e) {
            warning ("IOError while closing socket connection: %s", e.message);
        }
        return null;
    }

    protected bool get_sync (string endpoint, out string response_body, Gee.Map<string, string> query_params=new Gee.HashMap<string, string> ()) {
        return send_request (HttpMethod.GET, endpoint, out response_body, query_params);
    }

    protected void get_stream (string endpoint, Cancellable cancellable) {
        // Open the connection
        IOStream? connection = connect_to_socket ();
        DataInputStream input_stream = new DataInputStream (connection.input_stream);
        DataOutputStream output_stream = new DataOutputStream (connection.output_stream);

        // Send the request for the stream
        send_output (output_stream, format_request_message (HttpMethod.GET, endpoint, new Gee.HashMap<string, string> ()));
        uint status_code = read_status_code (input_stream, cancellable);
        Soup.MessageHeaders headers = read_headers (input_stream, cancellable);
        
        // Read the stream until cancelled
        while (!cancellable.is_cancelled ()) {
            read_stream (input_stream, cancellable);
        }
    }

    protected bool post_sync (string endpoint, out string response_body, Gee.Map<string, string> query_params=new Gee.HashMap<string, string> ()) {
        return send_request (HttpMethod.POST, endpoint, out response_body, query_params);
    }

    protected bool delete_sync (string endpoint, out string response_body, Gee.Map<string, string> query_params=new Gee.HashMap<string, string> ()) {
        return send_request (HttpMethod.DELETE, endpoint, out response_body, query_params);
    }

    private bool send_request (HttpMethod method, string endpoint, out string response_body, Gee.Map<string, string> query_params) {
        debug ("Executing %s request to %s", method.to_string (), endpoint);

        IOStream connection = connect_to_socket ();
        DataInputStream input_stream = new DataInputStream (connection.input_stream);
        DataOutputStream output_stream = new DataOutputStream (connection.output_stream);

        send_output (output_stream, format_request_message (method, endpoint, query_params));

        Cancellable cancellable = new Cancellable ();
        uint status_code = read_status_code (input_stream, cancellable);
        Soup.MessageHeaders headers = read_headers (input_stream, cancellable);
        response_body = read_body (headers, input_stream, cancellable);

        // TODO: Remove this
        //  debug (body);
        
        try {
            connection.close ();
        } catch (GLib.IOError e) {
            warning ("IOError while closing socket connection: %s", e.message);
        } finally {
            cancellable.cancel ();
        }

        if (is_error (status_code)) {
            warning (response_body);
            return false;
        }

        return true;   
    }

    // TODO: Look into this implementation a bit more - it works, but is slow for larger images
    protected bool send_file (string endpoint, GLib.File file, out string response_body) {
        IOStream? connection = connect_to_socket ();
        DataInputStream input_stream = new DataInputStream (connection.input_stream);
        DataOutputStream output_stream = new DataOutputStream (connection.output_stream);
        Cancellable cancellable = new Cancellable ();

        try {
            // Determine the file size
            var file_size = file.query_info ("*", GLib.FileQueryInfoFlags.NONE, cancellable).get_size ();
            debug ("File size: %s", file_size.to_string ());

            // Send the request line and headers
            send_output (output_stream, "POST %s HTTP/1.1\r\nHost:\r\nContent-Type:application/x-tar\r\nContent-Length:%s\r\n\r\n".printf (endpoint, file_size.to_string ()));

            // Stream the file in chunks rather than loading the entire thing into memory
            FileInputStream file_input_stream = file.read (cancellable);
            ssize_t bytes_read = 0;
            uint8[] buffer = new uint8[BUFFER_SIZE];
            while ((bytes_read = file_input_stream.read (buffer, cancellable)) != 0) {
                for (int i = 0; i < bytes_read; i++) {
                    output_stream.put_byte (buffer[i], cancellable);
                }
            }
        } catch (GLib.Error e) {
            critical ("Error while importing image: %s", e.message);
        }
        
        // Read the response        
        uint status_code = read_status_code (input_stream, cancellable);
        Soup.MessageHeaders headers = read_headers (input_stream, cancellable);
        response_body = read_body (headers, input_stream, cancellable);
        
        try {
            connection.close ();
        } catch (GLib.IOError e) {
            warning ("IOError while closing socket connection: %s", e.message);
        } finally {
            cancellable.cancel ();
        }

        if (is_error (status_code)) {
            warning (response_body);
            return false;
        }

        return true;   
    }

    protected bool receive_file (string endpoint, GLib.File file, out string response_body) {
        IOStream connection = connect_to_socket ();
        DataInputStream input_stream = new DataInputStream (connection.input_stream);
        DataOutputStream output_stream = new DataOutputStream (connection.output_stream);

        send_output (output_stream, format_request_message (HttpMethod.GET, endpoint, new Gee.HashMap<string, string> ()));

        Cancellable cancellable = new Cancellable ();
        uint status_code = read_status_code (input_stream, cancellable);
        Soup.MessageHeaders headers = read_headers (input_stream, cancellable);
        receive_chunked_file (input_stream, file, cancellable);

        // TODO
        response_body = "";

        try {
            connection.close ();
        } catch (GLib.IOError e) {
            warning ("IOError while closing socket connection: %s", e.message);
        } finally {
            cancellable.cancel ();
        }

        if (is_error (status_code)) {
            warning (response_body);
            return false;
        }

        return true;   
    }

    private void receive_chunked_file (DataInputStream input_stream, GLib.File file, Cancellable? cancellable) {
        try {
            FileOutputStream file_output_stream = file.create (GLib.FileCreateFlags.REPLACE_DESTINATION, cancellable);
            while (receive_file_chunk (input_stream, file_output_stream, cancellable)) {
                // Keep reading
            }
        } catch (GLib.Error e) {
            warning ("Error while receiving chunked file: %s", e.message);
        }
    }

    private bool receive_file_chunk (DataInputStream input_stream, FileOutputStream file_output_stream, Cancellable? cancellable) {
        string? line = null;
        try {
            // Read content length followed by CRLF
            line = input_stream.read_upto (CRLF, 1, null, cancellable);
            input_stream.read_bytes (CRLF.length, cancellable);

            // Last chunk is simply "0" followed by CRLF
            if (line == "0") {
                return false;
            }

            // Parse the chunk size
            long chunk_size = long.parse (line, 16);
            
            // Read the chunk content - don't assume that it can all be read in one go, so loop until full chunk is read
            size_t bytes_to_read = chunk_size;
            while (bytes_to_read != 0) {
                GLib.Bytes bytes = input_stream.read_bytes (bytes_to_read, cancellable);
                size_t bytes_read = bytes.get_size ();
                debug ("Read %s bytes", bytes_read.to_string ());
                file_output_stream.write (bytes.get_data (), cancellable);
                file_output_stream.flush (cancellable);
                bytes_to_read -= bytes_read;
            }

            // Read the CRLF at the end of the chunk
            input_stream.read_bytes (CRLF.length, cancellable);
        } catch (GLib.IOError e) {
            critical ("IOError while reading chunk content: %s [%s]", e.message, line);
            return false;
        } catch (GLib.Error e) {
            critical ("Error while reading chunk content: %s [%s]", e.message, line);
            return false;
        }
        return true;
    }

    private uint? read_status_code (DataInputStream input_stream, Cancellable? cancellable) {
        try {
            var line = input_stream.read_line_utf8 (null, cancellable).strip ();
            return uint.parse (line.split (" ")[1]);
        } catch (GLib.IOError e) {
            critical ("IOError while reading status: %s", e.message);
            return null;
        }
    }

    private Soup.MessageHeaders? read_headers (DataInputStream input_stream, Cancellable? cancellable) {
        var headers = new Soup.MessageHeaders (Soup.MessageHeadersType.RESPONSE);
        string line = null;
        try {
            while ((line = input_stream.read_line_utf8 (null, cancellable).strip ()) != "") {
                if (WhaleWatcher.Application.is_dev_mode ()) {
                    debug (@"$line");
                }
                int split_index = line.index_of (": ");
                headers.append (line.substring (0, split_index), line.substring (split_index + 2));
            }
        } catch (GLib.IOError e) {
            critical ("IOError while reading headers: %s", e.message);
            return null;
        }
        return headers;
    }

    private string? read_body (Soup.MessageHeaders headers, DataInputStream input_stream, Cancellable? cancellable) {
        string content_type = headers.get_one ("Content-Type");
        if (headers.get_one ("Transfer-Encoding") == "chunked") {
            return read_chunked (input_stream, cancellable);
        } else if (headers.get_one ("Content-Length") != null) {
            //  if (content_type.contains ("application/json")) {
            //      return read_line (input_stream, cancellable);
            //  } else if (content_type.contains ("text/plain")) {
                long content_length = long.parse (headers.get_one ("Content-Length"));
                //  return read_content (input_stream, content_length - 1, cancellable); // XXX: Why do we need -1 here? Newline char?
                var content = read_content (input_stream, content_length, cancellable);
                //  var content = read_line (input_stream, cancellable);
                //  while (content.contains ("\u0001")) {
                //      content = content.subcontent.index_of_char ('\u0001', 0);
                //  }
                return content;
            //  } else {
            //      // TODO
            //      return null;
            //  }
        } else {
            // TODO: Handle this! Read until end of stream
            //  assert_not_reached ();
            return null;
        }
    }

    // XXX: This works, but ignoring the content_length means our reads aren't completely efficient
    protected string? read_content (DataInputStream input_stream, long content_length, Cancellable? cancellable) {
        try {
            uint8[] buffer = new uint8[content_length];
            size_t bytes_read = input_stream.read (buffer, cancellable);
            //  size_t bytes_read;
            //  string line = input_stream.read_line_utf8 (out bytes_read, cancellable).strip ();
            debug ("Read %s bytes", bytes_read.to_string ());
            string line = ((string) buffer).substring (0, content_length).strip ();
            if (WhaleWatcher.Application.is_dev_mode ()) {
                debug (@"$line");
            }
            return line;
        } catch (GLib.Error e) {
            critical ("Error while reading content: %s", e.message);
            return null;
        }
    }

    private string? read_line (DataInputStream input_stream, Cancellable? cancellable) {
        try {
            size_t bytes_read;
            string? line = input_stream.read_line_utf8 (out bytes_read, cancellable); //.strip ();
            //  debug ("Read %s bytes", bytes_read.to_string ());
            //  string line = ((string) buffer); //.strip ();
            if (WhaleWatcher.Application.is_dev_mode ()) {
                //  debug (@"$line");
            }
            return line;
        } catch (GLib.Error e) {
            critical ("Error while reading content: %s", e.message);
            return null;
        }
    }

    private string? read_chunked (DataInputStream input_stream, Cancellable? cancellable) {
        var sb = new GLib.StringBuilder ();
        string? chunk = null;
        while ((chunk = read_chunk (input_stream, cancellable)) != null) {
            sb.append (chunk);
        }
        return sb.str;
    }

    private string? read_chunk (DataInputStream input_stream, Cancellable? cancellable) {
        try {
            //  // Read content length followed by CRLF
            //  string line = input_stream.read_upto (CRLF, 1, null, cancellable);
            //  input_stream.read_bytes (CRLF.length, cancellable);

            //  // Last chunk is simply "0" followed by CRLF
            //  if (line == "0") {
            //      return null;
            //  }

            //  // Parse the chunk size
            //  long chunk_size = long.parse (line, 16);
            
            //  // Read the chunk content - don't assume that it can all be read in one go, so loop until full chunk is read
            //  uint8[] chunk = new uint8[chunk_size];
            //  size_t bytes_to_read = chunk_size;
            //  while (bytes_to_read != 0) {
            //      GLib.Bytes bytes = input_stream.read_bytes (bytes_to_read, cancellable);
            //      size_t bytes_read = bytes.get_size ();
            //      debug ("Read %s bytes", bytes_read.to_string ());
            //      for (size_t i = 0; i < bytes_read; i++) {
            //          chunk[chunk_size - bytes_to_read + i] = bytes.get_data ()[i];
            //      }
            //      //  file_output_stream.write (bytes.get_data (), cancellable);
            //      //  file_output_stream.flush (cancellable);
            //      bytes_to_read -= bytes_read;
            //  }

            //  // Read the CRLF at the end of the chunk
            //  input_stream.read_bytes (CRLF.length, cancellable);

            //  return ((string) chunk).make_valid ();

            // 1. Content length followed by a carriage return. Read this as a hexidecimal string.
            //  string? line = input_stream.read_line_utf8 (null, cancellable).strip ();
            string? line = read_line (input_stream, cancellable);
            if (line == null) {
                return null;
            }
            line = line.strip ();
            //  print (@"$line\n");
            if (line == "0") {
                // Last chunk
                return null;
            }
            long content_length = long.parse (line, 16);
            if (content_length == 0) {
                // Nothing to read, so don't try (otherwise will get an I/O timeout)
                return "";
            }
            debug ("Chunk length: %s", content_length.to_string ());
            // Last chunk when reading chunked data is simply length 0, so return null to signify end
            //  if (content_length == 0) {
            //      //  read_content (input_stream, CRLF.length, cancellable);
            //      return null;
            //  }
            // 2. The content
            //  return read_content (input_stream, content_length - 1, cancellable).strip ();
            string content = read_content (input_stream, content_length, cancellable).strip ();
            input_stream.read_bytes (CRLF.length, cancellable);
            return content;
            // Last chunk when reading chunked data is simply "0", so return null to signify end
            //  if (content == "0") {
            //      return null;
            //  }
            //  return content;
        } catch (GLib.IOError e) {
            critical ("IOError while reading chunk content: %s", e.message);
            return null;
        } catch (GLib.Error e) {
            critical ("Error while reading chunk content: %s", e.message);
            return null;
        }
    }

    private IOStream? connect_to_socket () {
        try {
            SocketClient client = new SocketClient ();
            client.set_timeout (SOCKET_TIMEOUT);
            client.event.connect (on_socket_client_event);
            return client.connect (new UnixSocketAddress (socket_file));
        } catch (GLib.Error e) {
            critical ("Error while connecting to socket: %s", e.message);
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
                break;
            default:
                // Do nothing - per documentation, unrecognized events should be ignored as there may be
                // additional event values in the future
                break;
        }
    }

    private void send_output (DataOutputStream output_stream, string output) {
        try {
            //  debug ("Sending output: %s", output);
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

    private string format_request_message (HttpMethod method, string endpoint, Gee.Map<string, string> query_params) {
        var sb = new GLib.StringBuilder ();
        if (query_params.size > 0) {
            foreach (var entry in query_params.entries) {
                // TODO: Check URL encoding
                sb.append ("&%s=%s".printf (entry.key, entry.value));
            }
            sb.overwrite (0, "?");
        }
        return REQUEST_MESSAGE_FORMAT.printf (method.to_string (), endpoint, sb.str);
    }

    protected abstract void read_stream (DataInputStream input_stream, Cancellable? cancellable);

}