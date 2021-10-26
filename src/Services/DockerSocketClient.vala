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

    public bool validate_socket_file () {
        return GLib.File.new_for_path (SOCKET_FILE).query_exists ();
    }

    public string? test_socket_connection () {
        return test_socket ();
    }

    public WhaleWatcher.Models.DockerServerState ping () {
        string? json_data;
        get_sync (@"/$API_VERSION/_ping", out json_data);
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
        string? json_data;
        get_sync (@"/$API_VERSION/info", out json_data);
    }

    public WhaleWatcher.Models.DockerVersion? get_version () {
        string? json_data;
        get_sync (@"/$API_VERSION/version", out json_data);
        return WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerVersion.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerVersion;
    }

    public WhaleWatcher.Models.DockerSystemDataUsage get_system_data_usage () {
        string? json_data;
        get_sync (@"/$API_VERSION/system/df", out json_data);
        return WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerSystemDataUsage.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerSystemDataUsage;
    }

    public Gee.List<WhaleWatcher.Models.DockerImageSummary> get_images () {
        string? json_data;
        get_sync (@"/$API_VERSION/images/json", out json_data);
        return WhaleWatcher.Util.JsonUtils.parse_json_array (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerImageSummary.from_json (json_obj);
        }) as Gee.List<WhaleWatcher.Models.DockerImageSummary>;
    }

    public void remove_image (string image_name, bool force) {
        var query_params = new Gee.HashMap<string, string> ();
        query_params.set ("force", force.to_string ());
        string? json_data;
        if (!delete_sync (@"/$API_VERSION/images/$image_name", out json_data, query_params)) {
            var error_response = WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
                return WhaleWatcher.Models.DockerEngineErrorResponse.from_json (json_obj);
            }) as WhaleWatcher.Models.DockerEngineErrorResponse;
            error_received ("Error while removing image", "There was an error while attempting to remove the image %s. The image may be in use by a running container, or have descendant images.\n\nYou may be able to force remove the image.".printf (image_name), error_response.message);
        }
    }

    // TODO: This should be handled as a stream
    public void pull_image (string image_name) {
        // TODO: Add optional auth here
        var query_params = new Gee.HashMap<string, string> ();
        query_params.set ("fromImage", image_name);
        string? json_data;
        if (!post_sync (@"/$API_VERSION/images/create", out json_data, query_params)) {
            var error_response = WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
                return WhaleWatcher.Models.DockerEngineErrorResponse.from_json (json_obj);
            }) as WhaleWatcher.Models.DockerEngineErrorResponse;
            error_received ("Error while pulling image", "There was an error while attempting to pull the image %s.".printf (image_name), error_response.message);
        }
        // TODO: This comes back as a fake "list" of JSON elements, when handled as a stream this won't be an issue anymore
        debug (@"$json_data");
    }

    public WhaleWatcher.Models.DockerImageDetails? inspect_image (string image_name) {
        string? json_data;
        get_sync (@"/$API_VERSION/images/$image_name/json", out json_data);
        return WhaleWatcher.Util.JsonUtils.parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerImageDetails.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerImageDetails;
    }

    public Gee.List<WhaleWatcher.Models.DockerImageLayer> get_image_history (string image_name) {
        string? json_data;
        get_sync (@"/$API_VERSION/images/$image_name/history", out json_data);
        return WhaleWatcher.Util.JsonUtils.parse_json_array (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerImageLayer.from_json (json_obj);
        }) as Gee.List<WhaleWatcher.Models.DockerImageLayer>;
    }

    public bool import_image (GLib.File file) {
        string? json_data;
        return send_file (@"/$API_VERSION/images/load", file, out json_data);
    }

    public bool export_image (string image_name, GLib.File file) {
        string? json_data;
        return receive_file (@"/$API_VERSION/images/$image_name/get", file, out json_data);
    }

    public void get_containers () {
        string? json_data;
        get_sync (@"/$API_VERSION/containers/json", out json_data);
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
            string? line = input_stream.read_line_utf8 (null, cancellable);
            if (line == null) {
                return null;
            }
            long content_length = long.parse (line.replace ("\r", ""), 16);
            // 2. The content
            // TODO: Should this be read_body or read_chunk since that handles chunked content?
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
    public signal void error_received (string error, string description, string? error_details);

}
