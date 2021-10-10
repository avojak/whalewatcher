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

public class WhaleWatcher.Views.ImagesView : Gtk.Grid {

    public const string TITLE = _("Images");

    private Gtk.Stack stack;
    private WhaleWatcher.Views.Images.BrowseImagesView browse_images_view;
    private WhaleWatcher.Views.Images.InspectImageView inspect_image_view;

    enum Column {
        IN_USE_ICON,
        NAME,
        TAG,
        ID,
        CREATED,
        SIZE,
        IN_USE;

        public static Column[] all () {
            return { IN_USE_ICON, NAME, TAG, ID, CREATED, SIZE, IN_USE };
        }
    }

    public ImagesView () {
        Object (
            margin: 30,
            row_spacing: 12,
            column_spacing: 10
        );
    }

    construct {
        //  var disk_space_usage_grid = new Gtk.Grid ();
        //  disk_space_usage_grid.margin = 30;
        //  disk_space_usage_grid.vexpand = false;

        //  var info = GLib.File.new_for_path ("/var").query_filesystem_info (GLib.FileAttribute.FILESYSTEM_SIZE, null);
        //  var size = info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_SIZE);
        //  var total_usage = size / 2;
        //  var storage = new Granite.Widgets.StorageBar.with_total_usage (size, total_usage);

        //  var disk_usage_label = new Gtk.Label (_("Total size: "));
        //  disk_usage_value_label = new Gtk.Label ("");

        //  disk_space_usage_grid.attach (disk_usage_label, 0, 0);
        //  disk_space_usage_grid.attach (disk_usage_value_label, 1, 0);

        browse_images_view = new WhaleWatcher.Views.Images.BrowseImagesView ();
        browse_images_view.cleanup_images_button_clicked.connect ((images) => {
            cleanup_images_button_clicked (images);
        });
        browse_images_view.pull_images_button_clicked.connect ((images) => {
            pull_images_button_clicked (images);
        });
        browse_images_view.inspect_image_button_clicked.connect ((image) => {
            inspect_image_button_clicked (image);
        });

        inspect_image_view = new WhaleWatcher.Views.Images.InspectImageView ();

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add (browse_images_view);
        stack.add (inspect_image_view);
        stack.set_visible_child (browse_images_view);

        attach (stack, 0, 0);
    }

    public void show_layers_size (uint64 layers_size) {
        browse_images_view.show_layers_size (layers_size);
    }

    public void set_images (Gee.List<WhaleWatcher.Models.DockerImageSummary> images) {
        browse_images_view.set_images (images);
    }

    public void show_browse_images_view () {
        stack.set_visible_child (browse_images_view);
        inspect_image_view.clear ();
    }

    public void show_inspect_image_view () {
        stack.set_visible_child (inspect_image_view);
    }

    public void set_image_details (WhaleWatcher.Models.DockerImageDetails image_details) {
        // TODO: update inpsect images view with details
    }

    public void set_image_history (Gee.List<WhaleWatcher.Models.DockerImageLayer> image_history) {
        inspect_image_view.set_image_history (image_history);
    }

    public signal void cleanup_images_button_clicked (Gee.List<string> images);
    public signal void pull_images_button_clicked (Gee.List<string> images);
    public signal void inspect_image_button_clicked (string image);

}