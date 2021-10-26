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
    private Granite.Widgets.ModeButton view_mode;
    private Gtk.Button return_button;
    private Gtk.Separator return_button_separator;

    // Image browsing button group
    private Gtk.SearchEntry image_search_entry;
    private Gtk.Button image_import_button;
    private Gtk.Button image_inspect_export_button;

    // Image inspect button group
    private Gtk.Button image_inspect_remove_button;
    private Gtk.Button image_inspect_pull_button;
    private Gtk.Button image_inspect_run_button;
    private Gtk.Separator image_inspect_separator;

    private Gtk.Button user_button;

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

        view_mode = new Granite.Widgets.ModeButton ();
        view_mode.vexpand = false;
        view_mode.valign = Gtk.Align.CENTER;
        foreach (string value in view_title_mapping.values) {
            view_mode.append_text (value);
        }

        view_mode.mode_changed.connect (() => {
            view_selected (view_title_mapping.get (view_mode.selected));
        });

        set_custom_title (view_mode);

        return_button = new Gtk.Button ();
        return_button.no_show_all = true;
        return_button.valign = Gtk.Align.CENTER;
        return_button.vexpand = false;
        return_button.get_style_context ().add_class ("back-button");
        return_button.clicked.connect (() => {
            view_return ();
        });
        return_button_separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
        return_button_separator.no_show_all = true;

        user_button = create_headerbar_button ("avatar-default", "Sign in…");
        user_button.no_show_all = false;

        create_image_inspect_button_group ();
        create_image_browsing_button_group ();

        // TODO: Revisit how these buttons are arranged

        pack_start (return_button);
        pack_start (return_button_separator);

        pack_end (user_button);
        pack_end (image_search_entry);
        //  pack_end (spinner);
        pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));

        // Image browsing button group
        pack_start (image_import_button);
        //  pack_start (image_create_button);

        // Image inspect button group
        pack_start (image_inspect_export_button);
        pack_start (image_inspect_pull_button);
        pack_end (image_inspect_run_button);
        //  pack_end (image_inspect_separator);
        pack_end (image_inspect_remove_button);

        // TODO: Add spinner for background actions

    }

    private void create_image_browsing_button_group () {
        image_import_button = create_headerbar_button ("document-import", _("Import…"));
        image_import_button.clicked.connect (() => {
            image_import_button_clicked ();
        });

        image_search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search Images")
        };
        image_search_entry.changed.connect (() => {
            image_search_entry_changed (image_search_entry.text);
        });
    }

    private void create_image_inspect_button_group () {
        image_inspect_remove_button = create_headerbar_button ("edit-delete", "Remove…");
        image_inspect_remove_button.clicked.connect (() => {
            //  image_inspect_remove_button_clicked ();
        });

        image_inspect_pull_button = create_headerbar_button ("browser-download", "Pull");
        image_inspect_pull_button.clicked.connect (() => {
            //  image_inspect_pull_button_clicked ();
        });

        image_inspect_export_button = create_headerbar_button ("document-export", _("Export…"));
        image_inspect_export_button.clicked.connect (() => {
            image_export_button_clicked ();
        });

        image_inspect_run_button = create_headerbar_button ("media-playback-start", "Run…");
        image_inspect_run_button.clicked.connect (() => {
            //  image_inspect_run_button_clicked ();
        });

        image_inspect_separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
    }

    private Gtk.Button create_headerbar_button (string icon_name, string? tooltip) {
        return new Gtk.Button.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = tooltip,
            no_show_all = true,
            valign = Gtk.Align.CENTER,
            relief = Gtk.ReliefStyle.NONE
        };
    }

    public void set_return_button_label (string? label) {
        return_button.label = label;
    }

    public void set_view_mode_button_visible (bool visible) {
        view_mode.no_show_all = !visible;
        view_mode.visible = visible;
    }

    public void set_return_button_visible (bool visible) {
        return_button.no_show_all = !visible;
        return_button.visible = visible;
        return_button_separator.no_show_all = !visible;
        return_button_separator.visible = visible;
    }

    public void set_image_inspect_buttons_visible (bool visible) {
        image_inspect_remove_button.no_show_all = !visible;
        image_inspect_remove_button.visible = visible;
        image_inspect_run_button.no_show_all = !visible;
        image_inspect_run_button.visible = visible;
        image_inspect_export_button.no_show_all = !visible;
        image_inspect_export_button.visible = visible;
        image_inspect_pull_button.no_show_all = !visible;
        image_inspect_pull_button.visible = visible;
        image_inspect_separator.no_show_all = !visible;
        image_inspect_separator.visible = visible;
    }

    public void set_image_browsing_buttons_visible (bool visible) {
        image_import_button.no_show_all = !visible;
        image_import_button.visible = visible;   
        image_search_entry.no_show_all = !visible;
        image_search_entry.visible = visible;
    }

    public void update_title (string? title) {
        if (title == null) {
            set_title (null);
            set_custom_title (view_mode);
        } else {
            set_custom_title (null);
            set_title (title);
        }
    }

    public void set_mode_selection (string view_title) {
        foreach (var entry in view_title_mapping.entries) {
            if (entry.value == view_title) {
                view_mode.selected = entry.key;
            }
        }
    }

    public signal void view_selected (string view_title);
    public signal void view_return ();
    public signal void image_import_button_clicked ();
    public signal void image_export_button_clicked ();

    public signal void image_search_entry_changed (string search_text);

}
