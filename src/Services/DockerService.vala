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

public class WhaleWatcher.Services.DockerService : GLib.Object {

    public WhaleWatcher.Services.DockerSocketClient docker_client { get; construct; }

    private static WhaleWatcher.Services.DockerService _instance = null;

    public static WhaleWatcher.Services.DockerService instance {
        get {
            if (_instance == null) {
                _instance = new WhaleWatcher.Services.DockerService (new WhaleWatcher.Services.DockerSocketClient ());
            }
            return _instance;
        }
    }

    private Thread<int>? streaming_thread;
    private Cancellable streaming_cancellable = new Cancellable ();

    private DockerService (WhaleWatcher.Services.DockerSocketClient docker_client) {
        Object (
            docker_client: docker_client
        );
    }

    private Gee.List<WhaleWatcher.Models.DockerImageSummary>? images;

    construct {
        images = new Gee.ArrayList<WhaleWatcher.Models.DockerImageSummary> ();

        // Connect to signals
        docker_client.event_received.connect (on_event_received);
    }

    public void start_streaming () {
        if (streaming_thread != null) {
            warning ("Already streaming");
            return;
        }
        streaming_thread = new Thread<int> ("Docker event streaming", do_stream);
    }

    private int do_stream () {
        debug ("Starting streaming");
        docker_client.stream_events (streaming_cancellable);
        return 0;
    }

    public void stop_streaming () {
        debug ("Stopping streaming");
        streaming_cancellable.cancel ();
    }

    public void ping () {
        docker_client.ping ();
    }

    public void request_version () {
        new Thread<void> (null, () => {
            WhaleWatcher.Models.DockerVersion? version = docker_client.get_version ();
            if (version != null) {
                version_received (version);
            }
        });
    }

    public void request_system_data_usage () {
        new Thread<void> (null, () => {
            WhaleWatcher.Models.DockerSystemDataUsage? system_data_usage = docker_client.get_system_data_usage ();
            if (system_data_usage != null) {
                layers_size_received (system_data_usage.layers_size);
                images_received (system_data_usage.images);
                //  containers_received (system_data_usage.containers);
                //  volumes_received (system_data_usage.volumes);
            }
        });
    }

    public void request_images () {
        new Thread<void> (null, () => {
            Gee.List<WhaleWatcher.Models.DockerImageSummary>? new_images = docker_client.get_images ();
            if (new_images != null) {
                this.images = new_images;
                on_images_received (images);
                images_received (images);
            }
        });
    }

    private void on_images_received (Gee.List<WhaleWatcher.Models.DockerImageSummary> images) {
        foreach (var image in images) {
            //  print ("%s\n", image.shared_size.to_string ());
        }
    }

    /*
     * Signal Handlers
     */
    
    private void on_event_received (string event) {
        Json.Object? obj = WhaleWatcher.Util.JsonUtils.get_json_object (event);
        switch (obj.get_string_member ("Type")) {
            case WhaleWatcher.Models.Event.ImageEvent.TYPE:
                on_image_event_received (WhaleWatcher.Util.JsonUtils.parse_json_obj (event, (json_obj) => {
                    return WhaleWatcher.Models.Event.ImageEvent.from_json (json_obj);
                }) as WhaleWatcher.Models.Event.ImageEvent);
                break;
            default:
                warning ("Unsupported event type");
                break;
        }
    }

    private void on_image_event_received (WhaleWatcher.Models.Event.ImageEvent event) {
        request_images ();
        switch (event.action) {
            case DELETE:
            case IMPORT:
            case LOAD:
            case PULL:
            case PUSH:
            case SAVE:
            case TAG:
            case UNTAG:
            case PRUNE:
                break;
            default:
                assert_not_reached ();
        }
    }

    public signal void layers_size_received (uint64 layers_size);
    public signal void version_received (WhaleWatcher.Models.DockerVersion version);
    public signal void images_received (Gee.List<WhaleWatcher.Models.DockerImageSummary> images);

}
