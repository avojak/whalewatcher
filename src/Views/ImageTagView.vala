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

 public class WhaleWatcher.Views.ImageTagView : Gtk.Grid {

    public string image_name { get; construct; }
    public string tag { get; construct; }

    private Gtk.TreeView tree_view;
    private Gtk.ListStore placeholder_list_store;
    private Gtk.ListStore list_store;
    private Gtk.SourceView source_view;

    private Gtk.Label id_value_label;
    private Gtk.Label created_value_label;
    private Gtk.Label size_value_label;

    enum Column {
        INDEX,
        COMMAND,
        SIZE;

        public static Column[] all () {
            return { INDEX, COMMAND, SIZE };
        }
    }

    public ImageTagView (string image_name, string tag) {
        Object (
            image_name: image_name,
            tag: tag,
            orientation: Gtk.Orientation.VERTICAL,
            margin: 30,
            row_spacing: 12,
            column_spacing: 12
        );
    }

    construct {
        var header_label = new Gtk.Label (@"$image_name:$tag");
        header_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_label.halign = Gtk.Align.START;

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.wide_handle = false;
        paned.pack1 (create_history_pane (), true, false);
        paned.pack2 (create_command_pane (), true, false);

        attach (header_label, 0, 0);
        attach (create_details_grid (), 0, 1);
        attach (paned, 0, 2);

        show_all ();
    }

    public void set_image_details (WhaleWatcher.Models.DockerImageDetails image_details) {
        id_value_label.set_text (image_details.id.replace ("sha256:", ""));
        created_value_label.set_text (new DateTime.from_iso8601 (image_details.created, null).to_local ().format ("%x %X"));
        size_value_label.set_text (GLib.format_size (image_details.size, GLib.FormatSizeFlags.DEFAULT));
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

    private Gtk.Grid create_details_grid () {
        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        var id_label = new Gtk.Label (_("Image ID:")) {
            halign = Gtk.Align.END
        };
        id_value_label = new Gtk.Label ("") {
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

        grid.attach (id_label, 0, 0);
        grid.attach_next_to (id_value_label, id_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (created_label, id_label, Gtk.PositionType.BOTTOM);
        grid.attach_next_to (created_value_label, created_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (size_label, created_label, Gtk.PositionType.BOTTOM);
        grid.attach_next_to (size_value_label, size_label, Gtk.PositionType.RIGHT);
        
        return grid;
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

    //  public void clear () {
    //      tree_view.set_model (placeholder_list_store);
    //      source_view.get_buffer ().set_text ("");
    //  }

}