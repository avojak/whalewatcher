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

public class WhaleWatcher.Widgets.ImageTagListItem : Granite.Widgets.SourceList.Item {

    public string image_name { get; construct; }
    public string tag { get; construct; }
    public bool in_use { get; construct; }

    public ImageTagListItem (string image_name, string tag, bool in_use) {
        Object (
            name: tag,
            image_name: image_name,
            in_use: in_use,
            tooltip: image_name
        );
    }

    construct {
        icon = in_use ? new GLib.ThemedIcon ("emblem-enabled") : new GLib.ThemedIcon ("emblem-disabled");
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var run_item = new Gtk.MenuItem.with_label (_("Run…"));
        var push_item = new Gtk.MenuItem.with_label (_("Push…"));
        var pull_item = new Gtk.MenuItem.with_label (_("Pull…"));
        var export_item = new Gtk.MenuItem.with_label (_("Export…"));
        var delete_item = new Gtk.MenuItem.with_label (_("Delete…"));
        
        menu.append (run_item);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (push_item);
        menu.append (pull_item);
        menu.append (export_item);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (delete_item);
        menu.show_all ();

        return menu;
    }

}