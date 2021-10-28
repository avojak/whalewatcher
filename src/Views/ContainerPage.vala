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

public class WhaleWatcher.Views.ContainerPage : Granite.SettingsPage {

    private Gtk.Label image_value_label;
    private Gtk.Label created_value_label;
    private Gtk.Label size_value_label;

    public ContainerPage (string name, string status, Granite.SettingsPage.StatusType status_type) {
        Object (
            header: null,
            icon_name: "application-default-icon",
            title: name,
            status: status,
            status_type: status_type
        );
    }

    construct {
        var content_area = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin = 30,
            row_spacing = 12,
            column_spacing = 12
        };

        var header_icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        header_icon.pixel_size = 48;
        header_icon.valign = Gtk.Align.START;
        header_icon.halign = Gtk.Align.START;

        var header_label = new Gtk.Label (title);
        header_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_label.halign = Gtk.Align.START;

        content_area.attach (header_icon, 0, 0);
        content_area.attach (header_label, 1, 0);
        content_area.attach (create_details_grid (), 0, 1, 2, 1);

        add (content_area);

        show_all ();
    }

    public void set_container_details (WhaleWatcher.Models.DockerContainer container) {
        image_value_label.set_text (container.image);
        created_value_label.set_text (new DateTime.from_unix_utc (container.created).to_local ().format ("%x %X"));
        size_value_label.set_text (GLib.format_size (container.size_root_fs, GLib.FormatSizeFlags.DEFAULT));
    }

    private Gtk.Grid create_details_grid () {
        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        var image_label = new Gtk.Label (_("Image:")) {
            halign = Gtk.Align.END
        };
        image_value_label = new Gtk.Label ("") {
            halign = Gtk.Align.START
        };
        var created_label = new Gtk.Label (_("Created:")) {
            halign = Gtk.Align.END
        };
        created_value_label = new Gtk.Label ("") {
            halign = Gtk.Align.START
        };
        var size_label = new Gtk.Label (_("Size:")) {
            halign = Gtk.Align.END
        };
        size_value_label = new Gtk.Label ("") {
            halign = Gtk.Align.START
        };
        grid.attach (image_label, 0, 0);
        grid.attach_next_to (image_value_label, image_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (created_label, image_label, Gtk.PositionType.BOTTOM);
        grid.attach_next_to (created_value_label, created_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (size_label, created_label, Gtk.PositionType.BOTTOM);
        grid.attach_next_to (size_value_label, size_label, Gtk.PositionType.RIGHT);
        return grid;
    }

}