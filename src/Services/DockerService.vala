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
        docker_client.error_received.connect (on_error_received);
        docker_client.event_received.connect (on_event_received);
    }

    public void validate_connection () {
        new Thread<void> (null, () => {
            debug ("Validating socket file...");
            if (!docker_client.validate_socket_file ()) {
                invalid_connection (_("Docker socket file not found"), _("The Docker socket file was not found at %s. Verify that Docker is correctly installed.\n\nFor instructions on installing Docker, see: <a href=\"https://docs.docker.com/engine/install/ubuntu/\">Installing Docker Engine</a>.".printf ("/var/run/docker.sock")));
                return;
            }
            debug ("Testing socket connection...");
            string? socket_test_error = docker_client.test_socket_connection ();
            if (socket_test_error != null) {
                invalid_connection (_("Unable to establish socket connection"), _("There was an error while attempting to connect to the socket: %s".printf (socket_test_error)));
                return;
            }
            debug ("Pinging server...");
            if (WhaleWatcher.Models.DockerServerState.State.ERROR == docker_client.ping ().state) {
                invalid_connection (_("Docker server is in an errored state"), _("The Docker server responded with an error state. Verify that Docker is running without errors."));
                return;
            }
            debug ("Connection OK");
            valid_connection ();
        });
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

    public WhaleWatcher.Models.DockerServerState ping () {
        return docker_client.ping ();
    }

    public void request_version () {
        new Thread<void> (null, () => {
            WhaleWatcher.Models.DockerVersion? version = docker_client.get_version ();
            if (version != null) {
                version_received (version);
            }
        });
    }

    // This is kind of a catch-all for images, containers, and volumes
    public void request_system_data_usage () {
        new Thread<void> (null, () => {
            WhaleWatcher.Models.DockerSystemDataUsage? system_data_usage = docker_client.get_system_data_usage ();
            if (system_data_usage != null) {
                layers_size_received (system_data_usage.layers_size);
                images_received (system_data_usage.images);
                containers_received (system_data_usage.containers);
                volumes_received (system_data_usage.volumes);
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

    public void remove_images (Gee.List<string> image_names, bool force=false) {
        foreach (var image_name in image_names) {
            new Thread<void> (null, () => {
                // An image name is either a name:tag pair or an ID
                docker_client.remove_image (image_name, force);
            });
        }
    }

    public void pull_images (Gee.List<string> image_names) {
        foreach (var image_name in image_names) {
            new Thread<void> (null, () => {
                // An image name is either a name:tag pair or an ID
                docker_client.pull_image (image_name);
            });
        }
    }

    public void inspect_image (string image_name) {
        new Thread<void> (null, () => {
            // An image name is either a name:tag pair or an ID
            var image_details = docker_client.inspect_image (image_name);
            if (image_details != null) {
                image_details_received (image_name, image_details);
            }
        });
    }

    public void request_image_history (string image_name) {
        new Thread<void> (null, () => {
            // An image name is either a name:tag pair or an ID
            var image_history = docker_client.get_image_history (image_name);
            if (image_history != null) {
                image_history_received (image_name, image_history);
            }
        });
    }

    public void import_image (string uri) {
        new Thread<void> (null, () => {
            var file = GLib.File.new_for_uri (uri);
            if (docker_client.import_image (file)) {
                //  image_imported ()
            } else {
                // TODO
            }
        });
    }

    public void export_image (string image, string uri) {
        new Thread<void> (null, () => {
            var file = GLib.File.new_for_uri (uri);
            if (file.query_exists ()) {
                try {
                    file.delete ();
                } catch (GLib.Error e) {
                    warning ("Error while deleting file: %s", e.message);
                    return;
                }
            }
            if (docker_client.export_image (image, file)) {
                image_exported (image);
            } else {
                // TODO
            }
        });
    }

    public void request_volumes () {
        new Thread<void> (null, () => {
            // An image name is either a name:tag pair or an ID
            var volumes = docker_client.get_volumes ();
            if (volumes != null) {
                volumes_received (volumes);
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
    
    private void on_error_received (string error, string description, string? error_details) {
        error_received (error, description, error_details);
    }

    private void on_event_received (string event) {
        Json.Object? obj = WhaleWatcher.Util.JsonUtils.get_json_object (event);
        switch (obj.get_string_member ("Type")) {
            case WhaleWatcher.Models.Event.ImageEvent.TYPE:
                on_image_event_received (WhaleWatcher.Util.JsonUtils.parse_json_obj (event, (json_obj) => {
                    return WhaleWatcher.Models.Event.ImageEvent.from_json (json_obj);
                }) as WhaleWatcher.Models.Event.ImageEvent);
                break;
            case WhaleWatcher.Models.Event.ContainerEvent.TYPE:
                on_container_event_received (WhaleWatcher.Util.JsonUtils.parse_json_obj (event, (json_obj) => {
                    return WhaleWatcher.Models.Event.ContainerEvent.from_json (json_obj);
                }) as WhaleWatcher.Models.Event.ContainerEvent);
                break;
            default:
                warning ("Unsupported event type");
                break;
        }
    }

    private void on_image_event_received (WhaleWatcher.Models.Event.ImageEvent event) {
        //  request_images ();
        request_system_data_usage ();
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

    private void on_container_event_received (WhaleWatcher.Models.Event.ContainerEvent event) {
        request_system_data_usage ();
        switch (event.action) {
            case ATTACH:
            case COMMIT:
            case COPY:
            case CREATE:
            case DESTROY:
            case DETACH:
            case DIE:
            case EXEC_CREATE:
            case EXEC_DETACH:
            case EXEC_START:
            case EXEC_DIE:
            case EXPORT:
            case HEALTH_STATUS:
            case KILL:
            case OOM:
            case PAUSE:
            case RENAME:
            case RESIZE:
            case RESTART:
            case START:
            case STOP:
            case TOP:
            case UNPAUSE:
            case UPDATE:
            case PRUNE:
                break;
            default:
                assert_not_reached ();
        }
    }

    public signal void invalid_connection (string title, string details);
    public signal void valid_connection ();

    // Signals for responding to data received from the Docker engine
    public signal void error_received (string error, string description, string? details);
    public signal void layers_size_received (uint64 layers_size);
    public signal void version_received (WhaleWatcher.Models.DockerVersion version);
    public signal void images_received (Gee.List<WhaleWatcher.Models.DockerImageSummary> images);
    public signal void containers_received (Gee.List<WhaleWatcher.Models.DockerContainer> containers);
    public signal void volumes_received (Gee.List<WhaleWatcher.Models.DockerVolume> volumes);
    public signal void image_details_received (string image_name, WhaleWatcher.Models.DockerImageDetails image_details);
    public signal void image_history_received (string image_name, Gee.List<WhaleWatcher.Models.DockerImageLayer> image_history);

    // Signals for responding to actions performed
    public signal void image_exported (string image_name);

}
