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

public abstract class WhaleWatcher.Widgets.Sidebar.SidebarEntry : Gtk.ListBoxRow {

    public string icon_name { get; construct; }
    public string title { get; construct; }

    protected SidebarEntry (string icon_name, string title) {
        Object (
            icon_name: icon_name,
            title: title
        );
    }

    construct {
        var image = new Gtk.Image () {
            gicon = new ThemedIcon (icon_name),
            pixel_size = 32
        };

        var title_label = new Gtk.Label (title) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            valign = Gtk.Align.CENTER
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var grid = new Gtk.Grid () {
            margin = 6,
            column_spacing = 6
        };
        grid.attach (image, 0, 0);
        grid.attach (title_label, 1, 0);

        add (grid);
    }

}
