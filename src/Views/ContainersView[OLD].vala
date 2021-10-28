//  /*
//   * Copyright (c) 2021 Andrew Vojak (https://avojak.com)
//   *
//   * This program is free software; you can redistribute it and/or
//   * modify it under the terms of the GNU General Public
//   * License as published by the Free Software Foundation; either
//   * version 2 of the License, or (at your option) any later version.
//   *
//   * This program is distributed in the hope that it will be useful,
//   * but WITHOUT ANY WARRANTY; without even the implied warranty of
//   * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//   * General Public License for more details.
//   *
//   * You should have received a copy of the GNU General Public
//   * License along with this program; if not, write to the
//   * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
//   * Boston, MA 02110-1301 USA
//   *
//   * Authored by: Andrew Vojak <andrew.vojak@gmail.com>
//   */

//  public class WhaleWatcher.Views.ContainersView : Gtk.Grid {

//      public const string TITLE = _("Containers");

//      private static Gtk.SearchEntry search_entry;

//      private Gtk.Stack stack;
//      private Gtk.Grid browse_containers_view;
//      private Gtk.Grid inspect_container_view;

//      private Gtk.TreeView tree_view;
//      private Gtk.ListStore placeholder_list_store;
//      private Gtk.ListStore list_store;
//      private Gtk.TreeModelFilter filter;

//      private Gtk.Button inspect_button;
//      private Gtk.Button cli_button;
//      private Gtk.Button start_button;
//      private Gtk.Button restart_button;
//      private Gtk.Button delete_button;

//      enum Column {
//          STATUS_ICON,
//          STATUS_LABEL,
//          NAME,
//          IMAGE;

//          public static Column[] all () {
//              return { STATUS_ICON, STATUS_LABEL, NAME, IMAGE };
//          }
//      }

//      public ContainersView () {
//          Object (
//              margin: 30,
//              row_spacing: 12,
//              column_spacing: 10
//          );
//      }

//      construct {
//          //  var disk_space_usage_grid = new Gtk.Grid ();
//          //  disk_space_usage_grid.margin = 30;
//          //  disk_space_usage_grid.vexpand = false;

//          //  var info = GLib.File.new_for_path ("/var").query_filesystem_info (GLib.FileAttribute.FILESYSTEM_SIZE, null);
//          //  var size = info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_SIZE);
//          //  var total_usage = size / 2;
//          //  var storage = new Granite.Widgets.StorageBar.with_total_usage (size, total_usage);

//          //  var disk_usage_label = new Gtk.Label (_("Total size: "));
//          //  disk_usage_value_label = new Gtk.Label ("");

//          //  disk_space_usage_grid.attach (disk_usage_label, 0, 0);
//          //  disk_space_usage_grid.attach (disk_usage_value_label, 1, 0);

//          browse_containers_view = construct_browse_containers_view ();
//          inspect_container_view = construct_inspect_container_view ();

//          stack = new Gtk.Stack ();
//          stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
//          stack.add (browse_containers_view);
//          stack.add (inspect_container_view);
//          stack.set_visible_child (browse_containers_view);

//          attach (stack, 0, 0);
//      }

//      private Gtk.Grid construct_browse_containers_view () {
//          var grid = new Gtk.Grid () {
//              row_spacing = 12,
//              column_spacing = 10
//          };

//          search_entry = new Gtk.SearchEntry () {
//              placeholder_text = _("Search Container Names or Associated Images"),
//              sensitive = false,
//              hexpand = true
//          };
//          search_entry.changed.connect (() => {
//              filter.refilter ();
//          });
//          search_entry.icon_release.connect ((icon_pos, event) => {
//              if (icon_pos == Gtk.EntryIconPosition.SECONDARY) {
//                  search_entry.set_text ("");
//              }
//          });

//          var container_browsing_grid = new Gtk.Grid ();

//          var scrolled_window = new Gtk.ScrolledWindow (null, null);
//          scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
//          scrolled_window.propagate_natural_height = true;
//          scrolled_window.margin_bottom = 0;

//          tree_view = new Gtk.TreeView ();
//          tree_view.expand = true;
//          tree_view.headers_visible = true;
//          tree_view.enable_tree_lines = true;
//          //  tree_view.enable_grid_lines = Gtk.TreeViewGridLines.HORIZONTAL;
//          tree_view.fixed_height_mode = true;
//          tree_view.activate_on_single_click = true;

//          placeholder_list_store = new Gtk.ListStore (Column.all ().length, typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (bool));
//          list_store = new Gtk.ListStore (Column.all ().length, typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (bool));

//          // TODO: Set sort func on list_store
//          filter = new Gtk.TreeModelFilter (list_store, null);
//          filter.set_visible_func ((Gtk.TreeModelFilterVisibleFunc) filter_func);

//          var cell_renderer = new Gtk.CellRendererText ();
//          cell_renderer.ellipsize = Pango.EllipsizeMode.END;

//          tree_view.insert_column_with_attributes (-1, "", new Gtk.CellRendererPixbuf (), "icon-name", Column.STATUS_ICON);
//          tree_view.insert_column_with_attributes (-1, _("Status"), cell_renderer, "text", Column.STATUS_LABEL);
//          tree_view.insert_column_with_attributes (-1, _("Name"), cell_renderer, "text", Column.NAME);
//          tree_view.insert_column_with_attributes (-1, _("Image"), cell_renderer, "text", Column.IMAGE);

//          for (int i = 0; i < tree_view.get_n_columns (); i++) {
//              if (i == 0) {
//                  tree_view.get_column (i).resizable = false;
//                  tree_view.get_column (i).min_width = 20;
//              } else {
//                  tree_view.get_column (i).resizable = true;
//                  tree_view.get_column (i).min_width = 250;
//              }
//          }

//          // Use a placeholder list store with no data to ensure that the tree view will render the column
//          // headers and the proper size while the real data is being loaded in the background.
//          tree_view.set_model (placeholder_list_store);

//          tree_view.get_selection ().changed.connect (evaluate_tree_view_selection);
//          tree_view.get_selection ().set_mode (Gtk.SelectionMode.MULTIPLE);

//          var status_bar = new Gtk.Statusbar () {
//              margin = 0
//          };

//          // Using the symbolic icons here because the non-symbolic search icon at this size has very poor contrast in dark mode
//          inspect_button = new Gtk.Button.from_icon_name ("system-search-symbolic", Gtk.IconSize.BUTTON) {
//              tooltip_text = _("Inspect…"),
//              sensitive = false
//          };
//          inspect_button.clicked.connect (on_inspect_button_clicked);

//          start_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.BUTTON) {
//              tooltip_text = _("Start…"),
//              sensitive = false
//          };
//          start_button.clicked.connect (() => {
//              // TODO
//          });

//          restart_button = new Gtk.Button.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.BUTTON) {
//              tooltip_text = _("Restart…"),
//              sensitive = false
//          };
//          restart_button.clicked.connect (() => {
//              // TODO
//          });

//          cli_button = new Gtk.Button.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.BUTTON) {
//              tooltip_text = _("CLI…"),
//              sensitive = false
//          };
//          cli_button.clicked.connect (() => {
//              //  Posix.system ("io.elementary.terminal --execute=\"docker ps\"");
//              //  AppInfo.create_from_commandline ("docker ps", "", GLib.AppInfoCreateFlags.NEEDS_TERMINAL);
//              // TODO
//          });

//          delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON) {
//              tooltip_text = _("Delete…"),
//              sensitive = false
//          };
//          delete_button.clicked.connect (on_delete_button_clicked);

//          //  status_bar.attach (disk_usage_value_label, 0, 0, 1, 1);
//          //  status_bar.attach (delete_button, 1, 0, 1, 1);

//          status_bar.get_message_area ().pack_end (inspect_button, false, false, 4);
//          status_bar.get_message_area ().pack_end (start_button, false, false, 4);
//          status_bar.get_message_area ().pack_end (restart_button, false, false, 4);
//          status_bar.get_message_area ().pack_end (cli_button, false, false, 4);
//          status_bar.get_message_area ().pack_end (delete_button, false, false, 4);

//          scrolled_window.add (tree_view);
//          container_browsing_grid.attach (scrolled_window, 0, 1, 2, 1);
//          container_browsing_grid.attach (status_bar, 0, 2, 2, 1);

//          grid.attach (search_entry, 0, 0, 1, 1);
//          grid.attach (container_browsing_grid, 0, 1, 1, 1);

//          return grid;
//      }

//      private Gtk.Grid construct_inspect_container_view () {
//          var grid = new Gtk.Grid ();
//          return grid;
//      }

//      private static bool filter_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
//          if (search_entry == null) {
//              return true;
//          }
        
//          // Filter based on the search string
//          string search_string = search_entry.get_text () == null ? "" : search_entry.get_text ().strip ().down ();
//          if (search_string == "") {
//              return true;
//          }
//          string name = "";
//          string image = "";
//          model.get (iter, Column.NAME, out name, -1);
//          model.get (iter, Column.IMAGE, out image, -1);
//          if (name == null || image == null) {
//              return true;
//          }
//          if (name.down ().contains (search_string) || image.down ().contains (search_string)) {
//              return true;
//          }
//          return false;
//      }

//      private void evaluate_tree_view_selection () {
//          // Get the selection
//          Gtk.TreeSelection selection = tree_view.get_selection ();
//          int num_selected_rows = selection.count_selected_rows ();

//          // Update the buttons depending on how many rows are selected
//          inspect_button.sensitive = num_selected_rows == 1;
//          start_button.sensitive = num_selected_rows == 1;
//          restart_button.sensitive = num_selected_rows > 0;
//          cli_button.sensitive = num_selected_rows == 1;
//          delete_button.sensitive = num_selected_rows > 0;
//      }

//      private void on_delete_button_clicked () {
//          cleanup_images_button_clicked (get_selected_containers ());
//      }

//      private void on_pull_button_clicked () {
//          pull_images_button_clicked (get_selected_containers ());
//      }

//      private void on_inspect_button_clicked () {
//          inspect_image_button_clicked (get_selected_containers ().get (0));
//      }

//      // Gets the selected images as either name:tag, or ID in the case of <none>:<none>
//      private Gee.List<string> get_selected_containers () {
//          var containers = new Gee.ArrayList<string> ();
//          tree_view.get_selection ().selected_foreach ((model, path, iter) => {
//              GLib.Value name_value;
//              model.get_value (iter, Column.NAME, out name_value);
//              containers.add (name_value.get_string ());
//          });
//          return containers;
//      }

//      public void set_containers (Gee.List<WhaleWatcher.Models.DockerContainer> containers) {
//          // For performance reasons, unset the data model before populating it, then re-add to the tree view once fully populated
//          tree_view.set_model (placeholder_list_store);
//          search_entry.sensitive = false;
//          list_store.clear ();
//          foreach (var entry in containers) {
//              var name = entry.names.get (0);
//              var display_name = name.has_prefix ("/") ? name.substring (1) : name;
//              var display_status = entry.status;
//              var display_image = entry.image;
//              // TODO: Make this a little cleaner (official app shows things like "6 days ago")
//              //  var display_created = new DateTime.from_unix_utc (entry.created).to_local ().format ("%x %X");
            
//              Gtk.TreeIter iter;
//              list_store.append (out iter);
//              list_store.set (iter, Column.STATUS_ICON, null,
//                                   Column.STATUS_LABEL, display_status,
//                                           Column.NAME, display_name,
//                                          Column.IMAGE, display_image);
//          }
//          // With the model fully populated, we can now update the view
//          tree_view.set_model (filter);
//          //  spinner.stop ();
//          //  status_label.label = "%s channels found".printf (channels.size.to_string ());
//          search_entry.sensitive = containers.size > 0;
//      }

//      public void show_browse_containers_view () {
//          stack.set_visible_child (browse_containers_view);
//      }

//      public void show_inspect_container_view () {
//          stack.set_visible_child (inspect_container_view);
//      }

//      //  public void set_image_details (WhaleWatcher.Models.DockerImageDetails image_details) {
//      //      // TODO: update inpsect images view with details
//      //  }

//      public signal void cleanup_images_button_clicked (Gee.List<string> images);
//      public signal void pull_images_button_clicked (Gee.List<string> images);
//      public signal void inspect_image_button_clicked (string image);

//  }