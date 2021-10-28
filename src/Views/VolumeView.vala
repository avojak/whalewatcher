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

public class WhaleWatcher.Views.VolumeView : Gtk.Grid {

    public string volume_name { get; construct; }

    private Gtk.Label created_value_label;

    public VolumeView (string volume_name) {
        Object (
            volume_name: volume_name,
            orientation: Gtk.Orientation.VERTICAL,
            margin: 30,
            row_spacing: 12,
            column_spacing: 12
        );
    }

    construct {
        var header_label = new Gtk.Label (volume_name);
        header_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_label.halign = Gtk.Align.START;

        attach (header_label, 0, 0);
        attach (create_details_grid (), 0, 1);

        show_all ();
    }

    public void set_volume_details (WhaleWatcher.Models.DockerVolume volume_details) {
        created_value_label.set_text (new DateTime.from_iso8601 (volume_details.created, null).to_local ().format ("%x %X"));
    }

    private Gtk.Grid create_details_grid () {
        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        var created_label = new Gtk.Label (_("Created:")) {
            halign = Gtk.Align.END
        };
        created_value_label = new Gtk.Label ("") {
            halign = Gtk.Align.START
        };

        grid.attach (created_label, 0, 0);
        grid.attach_next_to (created_value_label, created_label, Gtk.PositionType.RIGHT);

        return grid;
    }

}