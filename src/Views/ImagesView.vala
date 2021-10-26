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

    private WhaleWatcher.Widgets.ImagesSourceList images_source_list;
    private Gtk.Stack images_stack;

    public ImagesView () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        Gtk.Paned paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            position = 300
        };

        images_source_list = new WhaleWatcher.Widgets.ImagesSourceList ();
        images_stack = new Gtk.Stack ();

        paned.pack1 (images_source_list, true, true);
        paned.pack2 (images_stack, true, true);

        add (paned);

        images_source_list.image_selected.connect (on_image_selected);
        images_source_list.delete_button_clicked.connect ((image_name) => {
            delete_button_clicked (image_name);
        });
        images_source_list.run_button_clicked.connect ((image_name) => {
            run_button_clicked (image_name);
        });
        images_source_list.export_button_clicked.connect ((image_name) => {
            export_button_clicked (image_name);
        });
        images_source_list.pull_button_clicked.connect ((image_name) => {
            pull_button_clicked (image_name);
        });
    }

    public void set_images (Gee.List<WhaleWatcher.Models.DockerImageSummary> images) {
        // Update the source list
        images_source_list.set_images (images);
        // Create the details views in the stack
        foreach (var image in images) {
            foreach (var tag in image.repo_tags) {
                images_stack.add_named (new WhaleWatcher.Views.ImageTagView (image.get_name (), tag.split (":")[1]), tag);
            }
        }
    }

    public void set_image_details (string image_name, WhaleWatcher.Models.DockerImageDetails image_details) {
        get_image_tag_view (image_name).set_image_details (image_details);
    }

    public void set_image_history (string image_name, Gee.List<WhaleWatcher.Models.DockerImageLayer> image_history) {
        get_image_tag_view (image_name).set_image_history (image_history);
    }

    public void filter_images (string search_text) {
        images_source_list.filter (search_text);
    }

    private WhaleWatcher.Views.ImageTagView? get_image_tag_view (string image_name) {
        var child = images_stack.get_child_by_name (image_name);
        if (child == null) {
            warning ("No image tag view for name: %s", image_name);
            return null;
        }
        return child as WhaleWatcher.Views.ImageTagView;
    }

    private void on_image_selected (string image_name) {
        image_selected (image_name);
        if (get_image_tag_view (image_name) == null) {
            return;
        }
        images_stack.set_visible_child_name (image_name);
    }

    public signal void image_selected (string image_name);
    public signal void delete_button_clicked (string image_name);
    public signal void run_button_clicked (string image_name);
    public signal void export_button_clicked (string image_name);
    public signal void pull_button_clicked (string image_name);

}