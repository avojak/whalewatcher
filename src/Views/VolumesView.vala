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

public class WhaleWatcher.Views.VolumesView : Gtk.Grid {

    public const string TITLE = _("Volumes");

    private WhaleWatcher.Widgets.VolumesSourceList volumes_source_list;
    private Gtk.Stack volumes_stack;

    public VolumesView () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        Gtk.Paned paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            position = 300
        };

        volumes_source_list = new WhaleWatcher.Widgets.VolumesSourceList ();
        volumes_stack = new Gtk.Stack ();

        paned.pack1 (volumes_source_list, true, true);
        paned.pack2 (volumes_stack, true, true);

        add (paned);

        volumes_source_list.volume_selected.connect ((volume_name) => {
            volumes_stack.set_visible_child_name (volume_name);
        });
        volumes_source_list.delete_button_clicked.connect ((volume_name) => {
            delete_button_clicked (volume_name);
        });
        volumes_source_list.browse_button_clicked.connect ((volume_name) => {
            browse_button_clicked (volume_name);
        });
    }

    public void set_volumes (Gee.List<WhaleWatcher.Models.DockerVolume> volumes) {
        // Update the source list
        volumes_source_list.set_volumes (volumes);
        // Create the details views in the stack
        foreach (var volume in volumes) {
            var view = new WhaleWatcher.Views.VolumeView (volume.name);
            view.set_volume_details (volume);
            volumes_stack.add_named (view, volume.name);
        }
    }

    public void filter_volumes (string search_text) {
        volumes_source_list.filter (search_text);
    }

    public signal void delete_button_clicked (string volume_name);
    public signal void browse_button_clicked (string volume_name);

}