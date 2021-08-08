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

    public WhaleWatcher.Services.DockerClient docker_client { get; construct; }

    private static WhaleWatcher.Services.DockerService _instance = null;

    public static WhaleWatcher.Services.DockerService instance {
        get {
            if (_instance == null) {
                _instance = new WhaleWatcher.Services.DockerService (new WhaleWatcher.Services.DockerClient ());
            }
            return _instance;
        }
    }

    private Thread<int>? streaming_thread;
    private Cancellable streaming_cancellable = new Cancellable ();

    private DockerService (WhaleWatcher.Services.DockerClient docker_client) {
        Object (
            docker_client: docker_client
        );
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

    public void request_version () {
        new Thread<void> (null, () => {
            WhaleWatcher.Models.DockerVersion? version = docker_client.get_version ();
            if (version != null) {
                version_received (version);
            }
        });
    }

    public signal void version_received (WhaleWatcher.Models.DockerVersion version);

}
