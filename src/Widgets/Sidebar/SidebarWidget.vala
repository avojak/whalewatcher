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

public class WhaleWatcher.Widgets.Sidebar.SidebarWidget : Gtk.Grid {

    construct {
        var list = new Gtk.ListBox () {
            expand = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        list.add (new WhaleWatcher.Widgets.Sidebar.ImagesEntry ());
        list.add (new WhaleWatcher.Widgets.Sidebar.ContainersEntry ());
        list.add (new WhaleWatcher.Widgets.Sidebar.VolumesEntry ());
        list.add (new WhaleWatcher.Widgets.Sidebar.NetworksEntry ());

        list.row_selected.connect ((row) => {
            if (row != null) {
                var entry = row as WhaleWatcher.Widgets.Sidebar.SidebarEntry;
                row_selected (entry.get_name ());
            }
        });

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (list);

        orientation = Gtk.Orientation.VERTICAL;
        add (scrolled_window);
    }

    public signal void row_selected (string name);

}
