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

public class WhaleWatcher.MainWindow : Hdy.Window {

    public unowned WhaleWatcher.Application app { get; construct; }

    private WhaleWatcher.Widgets.ErrorDialog? error_dialog;

    private WhaleWatcher.Layouts.MainLayout main_layout;

    public MainWindow (WhaleWatcher.Application application) {
        Object (
            application: application,
            app: application,
            border_width: 0,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        main_layout = new WhaleWatcher.Layouts.MainLayout (this);
        main_layout.cleanup_images_button_clicked.connect (on_cleanup_images_button_clicked);
        main_layout.pull_images_button_clicked.connect (on_pull_images_button_clicked);
        main_layout.inspect_image_button_clicked.connect (on_inspect_image_button_clicked);
        add (main_layout);

        move (WhaleWatcher.Application.settings.get_int ("pos-x"), WhaleWatcher.Application.settings.get_int ("pos-y"));
        resize (WhaleWatcher.Application.settings.get_int ("window-width"), WhaleWatcher.Application.settings.get_int ("window-height"));

        // Close streaming connection when the window is closed
        this.destroy.connect (() => {
            //  // Disconnect this signal so that we don't modify the setting to
            //  // show servers as disabled, when in reality they were enabled prior
            //  // to closing the application.
            //  main_layout.side_panel.server_row_disabled.disconnect (Iridium.Application.connection_repository.on_server_row_disabled);

            // TODO: Not sure if this is right…
            //  WhaleWatcher.Application.docker_client.close ();
            WhaleWatcher.Application.docker_service.stop_streaming ();
            GLib.Process.exit (0);
        });

        this.delete_event.connect (before_destroy);

        WhaleWatcher.Application.docker_service.error_received.connect (on_error_received);
        WhaleWatcher.Application.docker_service.layers_size_received.connect (on_layers_size_received);
        WhaleWatcher.Application.docker_service.version_received.connect (on_version_received);
        WhaleWatcher.Application.docker_service.images_received.connect (on_images_received);
        WhaleWatcher.Application.docker_service.image_details_received.connect (on_image_details_received);
        WhaleWatcher.Application.docker_service.image_history_received.connect (on_image_history_received);

        WhaleWatcher.Application.docker_service.start_streaming ();
        //  WhaleWatcher.Application.docker_service.request_version ();
        WhaleWatcher.Application.docker_service.request_system_data_usage ();
        

        show_app ();
    }

    public void show_app () {
        show_all ();
        show ();
        present ();
    }

    public bool before_destroy () {
        update_position_settings ();
        destroy ();
        return true;
    }

    private void update_position_settings () {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        WhaleWatcher.Application.settings.set_int ("pos-x", x);
        WhaleWatcher.Application.settings.set_int ("pos-y", y);
        WhaleWatcher.Application.settings.set_int ("window-width", width);
        WhaleWatcher.Application.settings.set_int ("window-height", height);
    }

    private void on_layers_size_received (uint64 layers_size) {
        Idle.add (() => {
            main_layout.show_layers_size (layers_size);
            return false;
        });
    }

    private void on_version_received (WhaleWatcher.Models.DockerVersion version) {
        print (version.to_string ());
    }

    private void on_images_received (Gee.List<WhaleWatcher.Models.DockerImageSummary> images) {
        //  foreach (var image in images) {
        //      print (image.to_string ());
        //  }
        Idle.add (() => {
            main_layout.show_images (images);
            return false;
        });
    }

    private void on_image_details_received (WhaleWatcher.Models.DockerImageDetails image_details) {
        Idle.add (() => {
            main_layout.show_image_details (image_details);
            return false;
        });
    }

    private void on_image_history_received (Gee.List<WhaleWatcher.Models.DockerImageLayer> image_history) {
        Idle.add (() => {
            main_layout.show_image_history (image_history);
            return false;
        });
    }

    private void on_cleanup_images_button_clicked (Gee.List<string> images) {
        int result = -1;
        bool should_force_remove = false;
        Idle.add (() => {
            var dialog = new WhaleWatcher.Widgets.RemoveImagesWarningDialog (this);
            dialog.force_button_toggled.connect ((active) => {
                should_force_remove = active;
            });
            dialog.destroy.connect (() => {
                if (result != Gtk.ResponseType.CANCEL) {
                    WhaleWatcher.Application.docker_service.remove_images (images, should_force_remove);
                }
            });
            result = dialog.run ();
            dialog.dismiss ();
            return false;
        });
    }

    private void on_pull_images_button_clicked (Gee.List<string> images) {
        WhaleWatcher.Application.docker_service.pull_images (images);
    }

    private void on_inspect_image_button_clicked (string image) {
        WhaleWatcher.Application.docker_service.inspect_image (image);
        WhaleWatcher.Application.docker_service.request_image_history (image);
    }

    private void on_error_received (string error, string description, string? error_details) {
        Idle.add (() => {
            if (error_dialog == null) {
                error_dialog = new WhaleWatcher.Widgets.ErrorDialog (this, error, description);
                if (error_details != null) {
                    error_dialog.show_error_details (error_details);
                }
                error_dialog.show_all ();
                error_dialog.destroy.connect (() => {
                    error_dialog = null;
                });
            }
            error_dialog.present ();
            return false;
        });
    }

}
