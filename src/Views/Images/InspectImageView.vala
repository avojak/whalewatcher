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

public class WhaleWatcher.Views.Images.InspectImageView : Gtk.Grid {

    private Gtk.TreeView tree_view;
    private Gtk.ListStore placeholder_list_store;
    private Gtk.ListStore list_store;

    private Gtk.SourceView source_view;

    enum Column {
        INDEX,
        COMMAND,
        SIZE;

        public static Column[] all () {
            return { INDEX, COMMAND, SIZE };
        }
    }

    public InspectImageView () {
        Object (
            row_spacing: 12,
            column_spacing: 10
        );
    }

    construct {
        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.wide_handle = false;
        paned.pack1 (create_history_pane (), true, false);
        paned.pack2 (create_command_pane (), true, false);

        attach (paned, 0, 0, 1, 1);
    }

    private Gtk.Widget create_history_pane () {
        var grid = new Gtk.Grid ();
        grid.margin_right = 4;

        var header = new Gtk.Label (_("Image History"));
        header.hexpand = true;
        header.halign = Gtk.Align.BASELINE;
        header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

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

        placeholder_list_store = new Gtk.ListStore (Column.all ().length, typeof (string), typeof (string), typeof (string));
        list_store = new Gtk.ListStore (Column.all ().length, typeof (string), typeof (string), typeof (string));

        var cell_renderer = new Gtk.CellRendererText ();
        cell_renderer.ellipsize = Pango.EllipsizeMode.END;

        tree_view.insert_column_with_attributes (-1, "", cell_renderer, "text", Column.INDEX);
        tree_view.insert_column_with_attributes (-1, _("Command"), cell_renderer, "text", Column.COMMAND);
        tree_view.insert_column_with_attributes (-1, _("Size"), cell_renderer, "text", Column.SIZE);

        tree_view.get_column (Column.INDEX).resizable = false;
        tree_view.get_column (Column.INDEX).min_width = 30;

        tree_view.get_column (Column.COMMAND).resizable = true;
        tree_view.get_column (Column.COMMAND).min_width = 300;

        tree_view.get_column (Column.SIZE).resizable = true;
        tree_view.get_column (Column.SIZE).min_width = 75;

        // Use a placeholder list store with no data to ensure that the tree view will render the column
        // headers and the proper size while the real data is being loaded in the background.
        tree_view.set_model (placeholder_list_store);

        tree_view.get_selection ().changed.connect (on_layer_selected);
        tree_view.get_selection ().set_mode (Gtk.SelectionMode.SINGLE);

        scrolled_window.add (tree_view);

        grid.attach (header, 0, 0);
        grid.attach (scrolled_window, 0, 1);

        return grid;
    }

    private Gtk.Widget create_command_pane () {
        var grid = new Gtk.Grid ();
        grid.margin_left = 4;

        var header = new Gtk.Label (_("Command"));
        header.hexpand = true;
        header.halign = Gtk.Align.BASELINE;
        header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        source_view = new Gtk.SourceView () {
            pixels_below_lines = 3,
            border_width = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            monospace = true,
            editable = false,
            cursor_visible = false,
            vexpand = true,
            hexpand = true
        };

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
        scrolled_window.propagate_natural_height = true;
        scrolled_window.margin_bottom = 0;

        scrolled_window.add (source_view);

        grid.attach (header, 0, 0);
        grid.attach (scrolled_window, 0, 1);

        return grid;
    }

    public void set_image_details (WhaleWatcher.Models.DockerImageDetails image_details) {

    }

    public void set_image_history (Gee.List<WhaleWatcher.Models.DockerImageLayer> image_history) {
        // For performance reasons, unset the data model before populating it, then re-add to the tree view once fully populated
        tree_view.set_model (placeholder_list_store);
        list_store.clear ();
        for (int i = 0; i < image_history.size; i++) {
            var display_command = image_history.get (i).created_by;
            var display_size = GLib.format_size (image_history.get (i).size, GLib.FormatSizeFlags.DEFAULT);
            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, Column.INDEX, i.to_string (),
                                Column.COMMAND, display_command,
                                   Column.SIZE, display_size);
        }
        // With the model fully populated, we can now update the view
        tree_view.set_model (list_store);
    }

    private void on_layer_selected () {
        Gtk.TreeSelection selection = tree_view.get_selection ();
        int num_selected_rows = selection.count_selected_rows ();
        if (num_selected_rows == 1) {
            // TODO: Do this better... don't need to iterate
            selection.selected_foreach ((model, path, iter) => {
                GLib.Value command_value;
                model.get_value (iter, Column.COMMAND, out command_value);
                set_source_view_text (command_value.get_string ());
            });
        }
    }

    private void set_source_view_text (string text) {
        source_view.get_buffer ().set_text (text);
    }

    public void clear () {
        tree_view.set_model (placeholder_list_store);
        source_view.get_buffer ().set_text ("");
    }

}