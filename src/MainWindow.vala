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

    private Gtk.FileFilter all_files_filter;
    private Gtk.FileFilter archive_files_filter;

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
        main_layout.delete_image_button_clicked.connect (on_delete_image_button_clicked);
        main_layout.pull_image_button_clicked.connect (on_pull_image_button_clicked);
        main_layout.import_image_button_clicked.connect (on_import_image_button_clicked);
        main_layout.export_image_button_clicked.connect (on_image_export_button_clicked);
        main_layout.retry_connection.connect (run_startup_checks);
        main_layout.image_selected.connect (on_image_selected);
        main_layout.browse_volume_button_clicked.connect (on_browse_volume_button_clicked);
        add (main_layout);

        move (WhaleWatcher.Application.settings.get_int ("pos-x"), WhaleWatcher.Application.settings.get_int ("pos-y"));
        resize (WhaleWatcher.Application.settings.get_int ("window-width"), WhaleWatcher.Application.settings.get_int ("window-height"));

        all_files_filter = new Gtk.FileFilter ();
        all_files_filter.set_filter_name (_("All files"));
        all_files_filter.add_pattern ("*");

        archive_files_filter = new Gtk.FileFilter ();
        archive_files_filter.set_filter_name (_("Archive files"));
        archive_files_filter.add_pattern ("*.tar");
        archive_files_filter.add_pattern ("*.tar.gz");
        archive_files_filter.add_pattern ("*.tgz");
        archive_files_filter.add_pattern ("*.bzip");
        archive_files_filter.add_pattern ("*.tar.xz");
        archive_files_filter.add_pattern ("*.txz");

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
        WhaleWatcher.Application.docker_service.containers_received.connect (on_containers_received);
        WhaleWatcher.Application.docker_service.volumes_received.connect (on_volumes_received);
        WhaleWatcher.Application.docker_service.image_details_received.connect (on_image_details_received);
        WhaleWatcher.Application.docker_service.image_history_received.connect (on_image_history_received);

        WhaleWatcher.Application.docker_service.image_exported.connect (on_image_exported);

        WhaleWatcher.Application.docker_service.invalid_connection.connect ((title, message) => {
            main_layout.show_error_view (title, message);
        });
        WhaleWatcher.Application.docker_service.valid_connection.connect (() => {
            WhaleWatcher.Application.docker_service.start_streaming ();
            WhaleWatcher.Application.docker_service.request_system_data_usage ();
            main_layout.show_last_view ();
        });

        show_app ();

        run_startup_checks ();
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

    private void run_startup_checks () {
        debug ("Running startup checks...");
        WhaleWatcher.Application.docker_service.validate_connection ();
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
        Idle.add (() => {
            main_layout.show_images (images);
            return false;
        });
    }

    private void on_containers_received (Gee.List<WhaleWatcher.Models.DockerContainer> containers) {
        Idle.add (() => {
            main_layout.show_containers (containers);
            return false;
        });
    }

    private void on_volumes_received (Gee.List<WhaleWatcher.Models.DockerVolume> volumes) {
        Idle.add (() => {
            main_layout.show_volumes (volumes);
            return false;
        });
    }

    private void on_image_details_received (string image_name, WhaleWatcher.Models.DockerImageDetails image_details) {
        Idle.add (() => {
            main_layout.show_image_details (image_name, image_details);
            return false;
        });
    }

    private void on_image_history_received (string image_name, Gee.List<WhaleWatcher.Models.DockerImageLayer> image_history) {
        Idle.add (() => {
            main_layout.show_image_history (image_name, image_history);
            return false;
        });
    }

    private void on_image_exported (string image_name) {
        Idle.add (() => {
            main_layout.show_toast_alert (_("Exported %s".printf (image_name)));
            return false;
        });
    }

    private void on_delete_image_button_clicked (string image_name) {
        var images = new Gee.ArrayList<string> ();
        images.add (image_name);

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

    private void on_pull_image_button_clicked (string image_name) {
        var images = new Gee.ArrayList<string> ();
        images.add (image_name);
        WhaleWatcher.Application.docker_service.pull_images (images);
    }

    private void on_image_selected (string image_name) {
        WhaleWatcher.Application.docker_service.inspect_image (image_name);
        WhaleWatcher.Application.docker_service.request_image_history (image_name);
    }

    //  private void on_inspect_image_button_clicked (string image) {
    //      WhaleWatcher.Application.docker_service.inspect_image (image);
    //      WhaleWatcher.Application.docker_service.request_image_history (image);
    //  }

    private void on_import_image_button_clicked () {
        var file_chooser = new Gtk.FileChooserNative (_("Select image file"), this, Gtk.FileChooserAction.OPEN, _("Import"), _("Cancel"));
        file_chooser.add_filter (all_files_filter);
        file_chooser.add_filter (archive_files_filter);
        file_chooser.set_filter (archive_files_filter);
        // TODO: This should be supported in the future
        file_chooser.select_multiple = false;
        // TODO: Remember last location
        file_chooser.set_current_folder_uri (GLib.Environment.get_home_dir ());
        
        var response = file_chooser.run ();
        file_chooser.destroy ();
        
        if (response == Gtk.ResponseType.ACCEPT) {
            // TODO: Update last visited path
            foreach (string uri in file_chooser.get_uris ()) {
                debug (@"Importing $uri");
                WhaleWatcher.Application.docker_service.import_image (uri);
            }
        }

        // Result of loading seems to just be a single stream message:
        // {"stream":"Loaded image: hello-world:latest\n"}
        // Similarly, a single engine image event
    }

    private void on_image_export_button_clicked (string image) {
        var file_chooser = new Gtk.FileChooserNative (_("Export Image"), this, Gtk.FileChooserAction.SAVE, _("Export"), _("Cancel"));
        file_chooser.add_filter (all_files_filter);
        file_chooser.add_filter (archive_files_filter);
        file_chooser.set_filter (archive_files_filter);
        // TODO: This should be supported in the future
        file_chooser.select_multiple = false;
        // TODO: Remember last location
        file_chooser.set_current_folder_uri (GLib.Environment.get_home_dir ());
        file_chooser.set_current_name ("%s.tar".printf (image.replace (":", "-").replace ("/", "-")));
        file_chooser.do_overwrite_confirmation = true;
        
        var response = file_chooser.run ();
        file_chooser.destroy ();
        
        if (response == Gtk.ResponseType.ACCEPT) {
            // TODO: Update last visited path
            foreach (string uri in file_chooser.get_uris ()) {
                debug (@"Exporting $uri");
                WhaleWatcher.Application.docker_service.export_image (image, uri);
            }
        }
    }

    private void on_browse_volume_button_clicked (string volume_name) {
        // TODO: This path should really be provided by the volume mountpoint property
        string uri = @"file:///var/lib/docker/volumes/$volume_name/_data/";
        try {
            // Lookup the executable for the default file browser
            var executable = GLib.AppInfo.get_default_for_type ("inode/directory", true).get_executable ();
            // The /var/lib/docker directory is restricted, so launch the file browser with pkexec
            new GLib.SubprocessLauncher (GLib.SubprocessFlags.NONE).spawnv (new string[] { "pkexec", executable, uri });
        } catch (GLib.Error e) {
            warning ("Failed to open URI (%s): %s", uri, e.message);
        }
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
