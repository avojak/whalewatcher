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

    public DockerClient () {
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
        return parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerServerState.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerServerState;
    }

    public void get_info () {
        string? json_data = get_sync (@"/$API_VERSION/info");
    }

    public WhaleWatcher.Models.DockerVersion? get_version () {
        string? json_data = get_sync (@"/$API_VERSION/version");
        return parse_json_obj (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerVersion.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerVersion;
    }

    public Gee.List<WhaleWatcher.Models.DockerImage> get_images () {
        string? json_data = get_sync (@"/$API_VERSION/images/json");
        return parse_json_array (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerImage.from_json (json_obj);
        }) as Gee.List<WhaleWatcher.Models.DockerImage>;
    }

    public void get_containers () {
        string? json_data = get_sync (@"/$API_VERSION/containers/json");
    }

    public void stream_events (Cancellable cancellable) {
        get_stream (@"/$API_VERSION/events", cancellable);
    }

    private Gee.List<GLib.Object>? parse_json_array (string? json_data, JsonDeserializer deserializer) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (json_data);
            var root_array = parser.get_root ().get_array ();
            var results = new Gee.ArrayList<GLib.Object> ();
            foreach (var item in root_array.get_elements ()) {
                results.add (deserializer (item.get_object ()));
            }
            return results;
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    private GLib.Object? parse_json_obj (string? json_data, JsonDeserializer deserializer) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (json_data);
            var root_object = parser.get_root ().get_object ();
            return deserializer (root_object);
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    private delegate GLib.Object? JsonDeserializer (Json.Object? json_obj);

}
