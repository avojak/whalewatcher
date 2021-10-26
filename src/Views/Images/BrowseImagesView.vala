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

public class WhaleWatcher.Views.Images.BrowseImagesView : Gtk.Grid {

    // I'm not 100% sure why this needs to be static - but they did it over
    // here: https://github.com/xfce-mirror/xfmpc/blob/921fa89585d61b7462e30bac5caa9b2f583dd491/src/playlist.vala
    // And it doesn't work otherwise...
    private static Gtk.SearchEntry search_entry;
    private static Gtk.CheckButton in_use_button;

    private Gtk.TreeView tree_view;
    private Gtk.ListStore placeholder_list_store;
    private Gtk.ListStore list_store;
    private Gtk.TreeModelFilter filter;

    private Gtk.Label disk_usage_value_label;

    private Gtk.Button inspect_button;
    private Gtk.MenuItem run_button;
    private Gtk.MenuItem export_button;
    private Gtk.MenuItem pull_button;
    //  private Gtk.Button push_button;
    private Gtk.Button cleanup_button;

    private Gtk.MenuButton menu_button;

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

    public BrowseImagesView () {
        Object (
            row_spacing: 12,
            column_spacing: 10
        );
    }

    construct {
        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search Image Names, Tags, or IDs"),
            sensitive = false,
            hexpand = true
        };
        search_entry.changed.connect (() => {
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

        var image_browsing_grid = new Gtk.Grid ();

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
        scrolled_window.propagate_natural_height = true;
        scrolled_window.margin_bottom = 0;

        tree_view = new Gtk.TreeView ();
        tree_view.expand = true;
        tree_view.headers_visible = true;
        tree_view.enable_tree_lines = true;
        //  tree_view.enable_grid_lines = Gtk.TreeViewGridLines.HORIZONTAL;
        tree_view.fixed_height_mode = true;
        tree_view.activate_on_single_click = true;

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

        //  tree_view.notify.connect (evaluate_tree_view_selection);
        //  tree_view.row_activated.connect (() => {
        //      evaluate_tree_view_selection ();
        //  });
        //  tree_view.cursor_changed.connect (() => {
        //      evaluate_tree_view_selection ();
        //  });
        tree_view.get_selection ().changed.connect (on_tree_view_selection_changed);
        tree_view.get_selection ().set_mode (Gtk.SelectionMode.MULTIPLE);

        var status_bar = new Gtk.Statusbar () {
            margin = 0
        };

        disk_usage_value_label = new Gtk.Label ("") {
            hexpand = true,
            xalign = 0
        };

        // Using the symbolic icons here because the non-symbolic search icon at this size has very poor contrast in dark mode
        inspect_button = new Gtk.Button.from_icon_name ("system-search-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Inspect…"),
            sensitive = false
        };
        inspect_button.clicked.connect (on_inspect_button_clicked);

        run_button = new Gtk.MenuItem.with_label ("Run…") {
            sensitive = false
        };
        //  run_button.clicked.connect (() => {
        //      // TODO
        //  });

        export_button = new Gtk.MenuItem.with_label ("Export…") {
            //  tooltip_text = _("Export…"),
            sensitive = false
        };
        export_button.activate.connect (on_export_button_clicked);

        pull_button = new Gtk.MenuItem.with_label ("Pull") {
            //  tooltip_text = _("Pull"),
            sensitive = false
        };
        //  pull_button.clicked.connect (on_pull_button_clicked);

        //  push_button = new Gtk.Button.from_icon_name ("document-send", Gtk.IconSize.SMALL_TOOLBAR) {
        //      tooltip_text = _("Clean up…")
        //  };
        //  push_button.clicked.connect (() => {
        //      // TODO
        //  });

        cleanup_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Remove…"),
            sensitive = false
        };
        cleanup_button.clicked.connect (on_cleanup_button_clicked);

        menu_button = new Gtk.MenuButton ();
        menu_button.image = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        menu_button.tooltip_text = _("More options…");

        var menu = new Gtk.Menu ();
        menu.add (run_button);
        menu.add (export_button);
        menu.add (pull_button);
        menu.show_all ();

        menu_button.popup = menu;

        //  status_bar.attach (disk_usage_value_label, 0, 0, 1, 1);
        //  status_bar.attach (cleanup_button, 1, 0, 1, 1);

        status_bar.get_message_area ().pack_start (disk_usage_value_label, true, true, 4);
        status_bar.get_message_area ().pack_end (menu_button, false, false, 4);
        status_bar.get_message_area ().pack_end (inspect_button, false, false, 4);
        //  status_bar.get_message_area ().pack_end (run_button, false, false, 4);
        //  status_bar.get_message_area ().pack_end (export_button, false, false, 4);
        //  status_bar.get_message_area ().pack_end (pull_button, false, false, 4);
        status_bar.get_message_area ().pack_end (cleanup_button, false, false, 4);

        scrolled_window.add (tree_view);
        image_browsing_grid.attach (scrolled_window, 0, 1, 2, 1);
        image_browsing_grid.attach (status_bar, 0, 2, 2, 1);

        attach (search_entry, 0, 0, 1, 1);
        attach (in_use_button, 1, 0, 1, 1);
        attach (image_browsing_grid, 0, 1, 2, 1);
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

    private void on_tree_view_selection_changed () {
        evaluate_tree_view_selection ();
        image_selection_changed (get_selected_images ());
    }

    private void evaluate_tree_view_selection () {
        // Get the selection
        Gtk.TreeSelection selection = tree_view.get_selection ();
        int num_selected_rows = selection.count_selected_rows ();

        // Update the buttons depending on how many rows are selected
        inspect_button.sensitive = num_selected_rows == 1;
        run_button.sensitive = num_selected_rows == 1;
        export_button.sensitive = num_selected_rows > 0;
        pull_button.sensitive = num_selected_rows == 1;
        cleanup_button.sensitive = num_selected_rows > 0;

        if (num_selected_rows == 1) {
            // TODO: Do this better... don't need to iterate
            selection.selected_foreach ((model, path, iter) => {
                GLib.Value name_value;
                model.get_value (iter, Column.NAME, out name_value);
                GLib.Value tag_value;
                model.get_value (iter, Column.TAG, out tag_value);
                if (name_value.get_string () == "<none>" && tag_value.get_string () == "<none>") {
                    pull_button.sensitive = false;
                }
            });
        }
    }

    private void on_cleanup_button_clicked () {
        cleanup_images_button_clicked (get_selected_images ());
    }

    private void on_pull_button_clicked () {
        pull_images_button_clicked (get_selected_images ());
    }

    private void on_inspect_button_clicked () {
        inspect_image_button_clicked (get_selected_images ().get (0));
    }

    private void on_export_button_clicked () {
        export_button_clicked ();
    }

    // Gets the selected images as either name:tag, or ID in the case of <none>:<none>
    private Gee.List<string> get_selected_images () {
        var images = new Gee.ArrayList<string> ();
        tree_view.get_selection ().selected_foreach ((model, path, iter) => {
            GLib.Value name_value;
            model.get_value (iter, Column.NAME, out name_value);
            GLib.Value tag_value;
            model.get_value (iter, Column.TAG, out tag_value);
            GLib.Value id_value;
            model.get_value (iter, Column.ID, out id_value);
            string name = name_value.get_string ();
            string tag = tag_value.get_string ();
            string id = id_value.get_string ();
            if (name == "<none>" && tag == "<none>") {
                images.add (id);
            } else {
                images.add (@"$name:$tag");
            }
        });
        return images;
    }

    public void show_layers_size (uint64 layers_size) {
        var display_size = GLib.format_size (layers_size, GLib.FormatSizeFlags.DEFAULT);
        disk_usage_value_label.set_text (_(@"Total size: $display_size"));
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
                list_store.set (iter, Column.IN_USE_ICON, entry.containers > 0 ? "emblem-enabled" : null,
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
        search_entry.sensitive = images.size > 0;
    }

    public signal void image_selection_changed (Gee.List<string> images);
    public signal void cleanup_images_button_clicked (Gee.List<string> images);
    public signal void pull_images_button_clicked (Gee.List<string> images);
    public signal void inspect_image_button_clicked (string image);
    public signal void export_button_clicked ();

}