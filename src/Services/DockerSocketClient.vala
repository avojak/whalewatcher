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

public class WhaleWatcher.Services.DockerSocketClient : WhaleWatcher.Services.SocketRestClient {

    private const string SOCKET_FILE = "/var/run/docker.sock";
    private const string API_VERSION = "v1.41";

    public DockerSocketClient () {
        Object (
            socket_file: SOCKET_FILE
        );
    }

    public WhaleWatcher.Models.DockerServerState ping () {
        string? json_data = get_sync (@"/$API_VERSION/_ping");
        if (json_data != null && json_data == "OK") {
            return new WhaleWatcher.Models.DockerServerState () {
                state = WhaleWatcher.Models.DockerServerState.State.OK
            };
        }
        return WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerServerState.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerServerState;
    }

    public void get_info () {
        string? json_data = get_sync (@"/$API_VERSION/info");
    }

    public WhaleWatcher.Models.DockerVersion? get_version () {
        string? json_data = get_sync (@"/$API_VERSION/version");
        return WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerVersion.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerVersion;
    }

    public WhaleWatcher.Models.DockerSystemDataUsage get_system_data_usage () {
        string? json_data = get_sync (@"/$API_VERSION/system/df");
        return WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerSystemDataUsage.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerSystemDataUsage;
    }

    public Gee.List<WhaleWatcher.Models.DockerImageSummary> get_images () {
        string? json_data = get_sync (@"/$API_VERSION/images/json");
        return WhaleWatcher.Util.JsonUtils.parse_json_array (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerImageSummary.from_json (json_obj);
        }) as Gee.List<WhaleWatcher.Models.DockerImageSummary>;
    }

    public void get_containers () {
        string? json_data = get_sync (@"/$API_VERSION/containers/json");
    }

    public void stream_events (Cancellable cancellable) {
        get_stream (@"/$API_VERSION/events", cancellable);
    }

    protected override void read_stream (GLib.DataInputStream input_stream, GLib.Cancellable? cancellable) {
        var event = read_event (input_stream, cancellable);
        if (event != null) {
            event_received (event);
        }
    }

    private string? read_event (DataInputStream input_stream, Cancellable? cancellable) {
        // Events come in sets of three lines:
        try {
            // 1. Content length followed by a carriage return. Read this as a hexidecimal string.
            long content_length = long.parse (input_stream.read_line_utf8 (null, cancellable).replace ("\r", ""), 16);
            // 2. The content
            var content = read_content (input_stream, content_length, cancellable).strip ();
            // 3. A single carriage return
            var carriage_return = input_stream.read_line_utf8 (null, cancellable);
            if (carriage_return != "\r") {
                warning ("Expected carriage return at end of event, but was %s", carriage_return);
            }
            return content;
        } catch (GLib.IOError e) {
            if (e.message == "Socket I/O timed out") {
                // Suppress these timeouts which are expected if there are no events on the stream
            } else {
                critical ("IOError while reading stream: %s", e.message);
            }
            return null;
        }
    }

    public signal void event_received (string event);

}
