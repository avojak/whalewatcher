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

public class WhaleWatcher.Widgets.HeaderBar : Hdy.HeaderBar {

    private Gee.Map<int, string> view_title_mapping = new Gee.HashMap<int, string> ();

    public HeaderBar () {
        Object (
            title: Constants.APP_NAME,
            show_close_button: true,
            has_subtitle: false
        );
    }

    construct {
        //  var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        //  mode_switch.primary_icon_tooltip_text = _("Light background");
        //  mode_switch.secondary_icon_tooltip_text = _("Dark background");
        //  mode_switch.valign = Gtk.Align.CENTER;
        //  mode_switch.halign = Gtk.Align.CENTER;
        //  mode_switch.bind_property ("active", Gtk.Settings.get_default (), "gtk_application_prefer_dark_theme");
        //  WhaleWatcher.Application.settings.bind ("prefer-dark-style", mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        view_title_mapping.set (0, WhaleWatcher.Views.ImagesView.TITLE);
        view_title_mapping.set (1, WhaleWatcher.Views.ContainersView.TITLE);
        view_title_mapping.set (2, WhaleWatcher.Views.VolumesView.TITLE);
        view_title_mapping.set (3, WhaleWatcher.Views.NetworksView.TITLE);

        var view_mode = new Granite.Widgets.ModeButton ();
        foreach (string value in view_title_mapping.values) {
            view_mode.append_text (value);
        }

        view_mode.mode_changed.connect (() => {
            view_selected (view_title_mapping.get (view_mode.selected));
        });

        set_custom_title (view_mode);

        //  pack_end (mode_switch);
    }

    public signal void view_selected (string view_title);

}
