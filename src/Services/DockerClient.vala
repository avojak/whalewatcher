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

    public void ping () {
        get_sync (@"/$API_VERSION/_ping");
    }

    public void get_info () {
        get_sync (@"/$API_VERSION/info");
    }

    public WhaleWatcher.Models.DockerVersion? get_version () {
        string? json_data = get_sync (@"/$API_VERSION/version");
        return parse_json (json_data, (json_obj) => {
            return WhaleWatcher.Models.DockerVersion.from_json (json_obj);
        }) as WhaleWatcher.Models.DockerVersion;
    }

    public void get_images () {
        get_sync (@"/$API_VERSION/images/json");
    }

    public void get_containers () {
        get_sync (@"/$API_VERSION/containers/json");
    }

    public void stream_events (Cancellable cancellable) {
        get_stream (@"/$API_VERSION/events", cancellable);
    }

    private GLib.Object? parse_json (string? json_data, JsonDeserializer deserializer) {
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
