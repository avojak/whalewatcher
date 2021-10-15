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

    private const string REQUEST_MESSAGE_FORMAT = "%s %s%s HTTP/1.1\r\nHost:\r\n\r\n";

    public string socket_file { get; construct; }

    protected bool get_sync (string endpoint, out string json_data, Gee.Map<string, string> query_params=new Gee.HashMap<string, string> ()) {
        return send_request (HttpMethod.GET, endpoint, out json_data, query_params);
    }

    protected void get_stream (string endpoint, Cancellable cancellable) {
        // Open the connection
        IOStream connection = connect_to_socket ();
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

    protected bool post_sync (string endpoint, out string json_data, Gee.Map<string, string> query_params=new Gee.HashMap<string, string> ()) {
        return send_request (HttpMethod.POST, endpoint, out json_data, query_params);
    }

    protected bool delete_sync (string endpoint, out string json_data, Gee.Map<string, string> query_params=new Gee.HashMap<string, string> ()) {
        return send_request (HttpMethod.DELETE, endpoint, out json_data, query_params);
    }

    private bool send_request (HttpMethod method, string endpoint, out string body, Gee.Map<string, string> query_params) {
        debug ("Executing %s request to %s", method.to_string (), endpoint);

        IOStream connection = connect_to_socket ();
        DataInputStream input_stream = new DataInputStream (connection.input_stream);
        DataOutputStream output_stream = new DataOutputStream (connection.output_stream);

        send_output (output_stream, format_request_message (method, endpoint, query_params));

        Cancellable cancellable = new Cancellable ();
        uint status_code = read_status_code (input_stream, cancellable);
        Soup.MessageHeaders headers = read_headers (input_stream, cancellable);
        body = read_body (headers, input_stream, cancellable);

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
            warning (body);
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
        if (headers.get_one ("Transfer-Encoding") == "chunked") {
            return read_chunked (input_stream, cancellable);
        } else if (headers.get_one ("Content-Length") != null) {
            long content_length = long.parse (headers.get_one ("Content-Length"));
            return read_content (input_stream, content_length - 1, cancellable); // XXX: Why do we need -1 here? Newline char?
        } else {
            // TODO: Handle this! Read until end of stream
            assert_not_reached ();
        }
    }

    protected string? read_content (DataInputStream input_stream, long content_length, Cancellable? cancellable) {
        try {
            uint8[] buffer = new uint8[content_length];
            size_t bytes_read = input_stream.read (buffer, cancellable);
            debug ("Read %s bytes", bytes_read.to_string ());
            string line = ((string) buffer).strip ();
            if (WhaleWatcher.Application.is_dev_mode ()) {
                debug (@"$line");
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
            if (WhaleWatcher.Application.is_dev_mode ()) {
                sb.append (chunk);
            }
        }
        // Read the trailer
        input_stream.read_line_utf8 (null, cancellable);
        return sb.str;
    }

    private string? read_chunk (DataInputStream input_stream, Cancellable? cancellable) {
        try {
            // 1. Content length followed by a carriage return. Read this as a hexidecimal string.
            long content_length = long.parse (input_stream.read_line_utf8 (null, cancellable).replace ("\r", ""), 16);
            debug ("Chunk length: %s", content_length.to_string ());
            // Last chunk when reading chunked data is simply length 0, so return null to signify end
            if (content_length == 0) {
                return null;
            }
            // 2. The content
            return read_content (input_stream, content_length - 1, cancellable).strip ();
            // Last chunk when reading chunked data is simply "0", so return null to signify end
            //  if (content == "0") {
            //      return null;
            //  }
            //  return content;
        } catch (GLib.IOError e) {
            critical ("IOError while reading chunk content: %s", e.message);
            return null;
        }
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