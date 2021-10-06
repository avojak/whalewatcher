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

    // I'm not 100% sure why this needs to be static - but they did it over
    // here: https://github.com/xfce-mirror/xfmpc/blob/921fa89585d61b7462e30bac5caa9b2f583dd491/src/playlist.vala
    // And it doesn't work otherwise...
    private static Gtk.Entry search_entry;
    private static Gtk.CheckButton in_use_button;

    private Gtk.TreeView tree_view;
    private Gtk.ListStore placeholder_list_store;
    private Gtk.ListStore list_store;
    private Gtk.TreeModelFilter filter;

    private Gtk.Label disk_usage_value_label;

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

    construct {
        var disk_space_usage_grid = new Gtk.Grid ();
        disk_space_usage_grid.margin = 30;
        disk_space_usage_grid.vexpand = false;

        //  var info = GLib.File.new_for_path ("/var").query_filesystem_info (GLib.FileAttribute.FILESYSTEM_SIZE, null);
        //  var size = info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_SIZE);
        //  var total_usage = size / 2;
        //  var storage = new Granite.Widgets.StorageBar.with_total_usage (size, total_usage);

        var disk_usage_label = new Gtk.Label (_("Total size: "));
        disk_usage_value_label = new Gtk.Label ("");

        disk_space_usage_grid.attach (disk_usage_label, 0, 0);
        disk_space_usage_grid.attach (disk_usage_value_label, 1, 0);

        var image_browsing_grid = new Gtk.Grid ();
        image_browsing_grid.margin = 30;
        image_browsing_grid.row_spacing = 12;
        image_browsing_grid.column_spacing = 10;

        search_entry = new Gtk.Entry ();
        search_entry.placeholder_text = _("Search");
        search_entry.sensitive = false;
        search_entry.hexpand = true;
        search_entry.secondary_icon_tooltip_text = _("Clear");
        search_entry.changed.connect (() => {
            if (search_entry.text != "") {
                search_entry.secondary_icon_name = "edit-clear-symbolic";
            } else {
                search_entry.secondary_icon_name = null;
            }
            filter.refilter ();
        });
        search_entry.icon_release.connect ((icon_pos, event) => {
            if (icon_pos == Gtk.EntryIconPosition.SECONDARY) {
                search_entry.set_text ("");
            }
        });

        in_use_button = new Gtk.CheckButton.with_label (_("In-use only"));
        in_use_button.toggled.connect (() => {
            filter.refilter ();
        });

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
        scrolled_window.propagate_natural_height = true;

        tree_view = new Gtk.TreeView ();
        tree_view.expand = true;
        tree_view.headers_visible = true;
        tree_view.enable_tree_lines = true;
        //  tree_view.enable_grid_lines = Gtk.TreeViewGridLines.HORIZONTAL;
        tree_view.fixed_height_mode = true;

        placeholder_list_store = new Gtk.ListStore (Column.all ().length, typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (bool));
        list_store = new Gtk.ListStore (Column.all ().length, typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (bool));

        // TODO: Set sort func on list_store
        filter = new Gtk.TreeModelFilter (list_store, null);
        filter.set_visible_func ((Gtk.TreeModelFilterVisibleFunc) filter_func);

        var cell_renderer = new Gtk.CellRendererText ();
        cell_renderer.ellipsize = Pango.EllipsizeMode.END;

        tree_view.insert_column_with_attributes (-1, "", new Gtk.CellRendererPixbuf (), "icon-name", Column.IN_USE_ICON);
        tree_view.insert_column_with_attributes (-1, _("Name"), cell_renderer, "text", Column.NAME);
        tree_view.insert_column_with_attributes (-1, _("Tag"), cell_renderer, "text", Column.TAG);
        tree_view.insert_column_with_attributes (-1, _("Image ID"), cell_renderer, "text", Column.ID);
        tree_view.insert_column_with_attributes (-1, _("Created"), cell_renderer, "text", Column.CREATED);
        tree_view.insert_column_with_attributes (-1, _("Size"), cell_renderer, "text", Column.SIZE);
        tree_view.insert_column_with_attributes (-1, "", new Gtk.CellRendererText (), "text", Column.IN_USE);

        for (int i = 0; i < tree_view.get_n_columns (); i++) {
            if (i == 0) {
                tree_view.get_column (i).resizable = false;
                tree_view.get_column (i).min_width = 20;
            } else {
                tree_view.get_column (i).resizable = true;
                tree_view.get_column (i).min_width = 150;
            }
        }

        // The IN_USE column is for data purposes, not to display
        tree_view.get_column (Column.IN_USE).set_visible (false);

        // Use a placeholder list store with no data to ensure that the tree view will render the column
        // headers and the proper size while the real data is being loaded in the background.
        tree_view.set_model (placeholder_list_store);

        tree_view.button_press_event.connect (on_tree_view_clicked);

        scrolled_window.add (tree_view);
        image_browsing_grid.attach (search_entry, 0, 0, 1, 1);
        image_browsing_grid.attach (in_use_button, 1, 0, 1, 1);
        image_browsing_grid.attach (scrolled_window, 0, 1, 2, 1);

        attach (disk_space_usage_grid, 0, 0);
        attach (image_browsing_grid, 0, 1);
    }

    private static bool filter_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
        if (search_entry == null) {
            return true;
        }

        // Filter based on whether the image is in-use
        bool in_use = true;
        model.get (iter, Column.IN_USE, out in_use, -1);
        if (in_use_button.active && !in_use) {
            return false;
        }
        
        // Filter based on the search string
        string search_string = search_entry.get_text () == null ? "" : search_entry.get_text ().strip ().down ();
        if (search_string == "") {
            return true;
        }
        string name = "";
        string tag = "";
        string id = "";
        model.get (iter, Column.NAME, out name, -1);
        model.get (iter, Column.TAG, out tag, -1);
        model.get (iter, Column.ID, out id, -1);
        if (name == null || tag == null || id == null) {
            return true;
        }
        if (name.down ().contains (search_string) || tag.down ().contains (search_string) || id.down ().contains (search_string)) {
            return true;
        }
        return false;
    }

    private bool on_tree_view_clicked (Gtk.Widget widget, Gdk.EventButton event) {
        uint button_clicked;
        event.get_button (out button_clicked);
        if (event.get_event_type () == Gdk.EventType.BUTTON_PRESS && button_clicked == 3) {
            Gtk.TreeSelection selection = tree_view.get_selection ();
            if (selection.count_selected_rows () == 1) {
                Gtk.TreeModel model;
                Gtk.TreeIter iter;
                selection.get_selected (out model, out iter);
                // TODO: Create context menu
            }
        }
        return false;
    }

    public void show_layers_size (uint64 layers_size) {
        var display_size = GLib.format_size (layers_size, GLib.FormatSizeFlags.DEFAULT);
        disk_usage_value_label.set_text (display_size);
    }

    public void set_images (Gee.List<WhaleWatcher.Models.DockerImageSummary> images) {
        // For performance reasons, unset the data model before populating it, then re-add to the tree view once fully populated
        tree_view.set_model (placeholder_list_store);
        search_entry.sensitive = false;
        list_store.clear ();
        foreach (var entry in images) {
            var display_name = entry.get_name ();
            var display_id = entry.get_short_id ();
            // TODO: Make this a little cleaner (official app shows things like "6 days ago")
            var display_created = new DateTime.from_unix_utc (entry.created).to_local ().format ("%x %X");
            var display_size = GLib.format_size (entry.size, GLib.FormatSizeFlags.DEFAULT);
            foreach (var tag in entry.repo_tags) {
                var display_tag = tag.split(":")[1];
                Gtk.TreeIter iter;
                list_store.append (out iter);
                list_store.set (iter, Column.IN_USE_ICON, entry.containers > 0 ? "user-available" : null,
                                             Column.NAME, display_name,
                                              Column.TAG, display_tag,
                                               Column.ID, display_id,
                                          Column.CREATED, display_created,
                                             Column.SIZE, display_size,
                                           Column.IN_USE, entry.containers > 0);
            }
        }
        // With the model fully populated, we can now update the view
        tree_view.set_model (filter);
        //  spinner.stop ();
        //  status_label.label = "%s channels found".printf (channels.size.to_string ());
        search_entry.sensitive = true;
    }

}