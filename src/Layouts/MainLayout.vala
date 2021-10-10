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

public class WhaleWatcher.Layouts.MainLayout : Gtk.Grid {

    private const string DOCKER_BLUE = "#2496ed";
    private const string BLUEBERRY_100 = "#8cd5ff";

    public unowned WhaleWatcher.MainWindow window { get; construct; }

    private WhaleWatcher.Widgets.HeaderBar header_bar;
    //  private WhaleWatcher.Widgets.Sidebar.SidebarWidget side_bar;
    private Gtk.Stack stack;

    //  private Gee.Map<int, string> view_title_mapping = new Gee.HashMap<int, string> ();

    private WhaleWatcher.Views.ImagesView images_view;
    private WhaleWatcher.Views.ContainersView containers_view;
    private WhaleWatcher.Views.VolumesView volumes_view;
    private WhaleWatcher.Views.NetworksView networks_view;

    private string? prior_view = null;

    public MainLayout (WhaleWatcher.MainWindow window) {
        Object (
            window: window
        );
    }

    construct {
        header_bar = new WhaleWatcher.Widgets.HeaderBar ();
        header_bar.view_selected.connect (on_view_selected);
        header_bar.view_return.connect (on_view_return);
        //  unowned Gtk.StyleContext header_context = header_bar.get_style_context ();
        //  header_context.add_class ("default-decoration");

        //  side_bar = new WhaleWatcher.Widgets.Sidebar.SidebarWidget ();
        //  side_bar.row_selected.connect ((entry_name) => {
        //      stack.set_visible_child_name (entry_name);
        //  });

        // Depending on the configured system style preferences, the contrast with a color header bar with selected buttons may look very poor
        //  Gdk.RGBA primary_color = Gdk.RGBA ();
        //  primary_color.parse (DOCKER_BLUE);
        //  Granite.Widgets.Utils.set_color_primary (window, primary_color);

        images_view = new WhaleWatcher.Views.ImagesView ();
        images_view.cleanup_images_button_clicked.connect (on_cleanup_images_button_clicked);
        images_view.pull_images_button_clicked.connect (on_pull_images_button_clicked);
        images_view.inspect_image_button_clicked.connect (on_inspect_image_button_clicked);
        containers_view = new WhaleWatcher.Views.ContainersView ();
        volumes_view = new WhaleWatcher.Views.VolumesView ();
        networks_view = new WhaleWatcher.Views.NetworksView ();

        //  view_title_mapping.set (0, WhaleWatcher.Views.ImagesView.TITLE);
        //  view_title_mapping.set (1, WhaleWatcher.Views.ContainersView.TITLE);
        //  view_title_mapping.set (2, WhaleWatcher.Views.VolumesView.TITLE);
        //  view_title_mapping.set (3, WhaleWatcher.Views.NetworksView.TITLE);

        //  var view_mode = new Granite.Widgets.ModeButton ();
        //  foreach (string value in view_title_mapping.values) {
        //      view_mode.append_text (value);
        //  }

        //  view_mode.mode_changed.connect (() => {
        //      on_view_selected (view_title_mapping.get (view_mode.selected));
        //  });

        //  var navbar = new Gtk.Grid () {
        //      hexpand = true,
        //      halign = Gtk.Align.CENTER,
        //      margin_top = 8,
        //      margin_left = 8,
        //      margin_right = 8
        //  };
        //  navbar.attach (view_mode, 0, 0);

        stack = new Gtk.Stack ();
        stack.add_named (new WhaleWatcher.Views.WelcomeView (window), "welcome");
        stack.add_named (images_view, WhaleWatcher.Views.ImagesView.TITLE);
        stack.add_named (containers_view, WhaleWatcher.Views.ContainersView.TITLE);
        stack.add_named (volumes_view, WhaleWatcher.Views.VolumesView.TITLE);
        stack.add_named (networks_view, WhaleWatcher.Views.NetworksView.TITLE);

        //  Gtk.Paned paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        //  paned.position = 240;
        //  paned.expand = true;
        //  paned.pack1 (side_bar, true, false);
        //  paned.pack2 (stack, true, false);

        attach (header_bar, 0, 0);
        //  attach (navbar, 0, 1);
        attach (stack, 0, 1);

        show_all ();
    }

    private void on_view_selected (string view_title) {
        debug ("%s selected", view_title);
        Idle.add (() => {
            stack.set_visible_child_name (view_title);
            header_bar.set_image_browsing_buttons_visible (view_title == WhaleWatcher.Views.ImagesView.TITLE);
            return false;
        });
    }

    private void on_view_return () {
        if (prior_view == null) {
            warning ("Attempting to return to view, but no prior view was found");
            return;
        }
        Idle.add (() => {
            header_bar.update_title (null);
            header_bar.set_return_button_label (null);
            header_bar.set_view_mode_button_visible (true);
            header_bar.set_return_button_visible (false);
            header_bar.set_image_inspect_buttons_visible (false);
            header_bar.set_image_browsing_buttons_visible (prior_view == WhaleWatcher.Views.ImagesView.TITLE);
            switch (prior_view) {
                case WhaleWatcher.Views.ImagesView.TITLE:
                    images_view.show_browse_images_view ();
                    break;
            }
            prior_view = null;
            return false;
        });
    }

    private void on_cleanup_images_button_clicked (Gee.List<string> images) {
        cleanup_images_button_clicked (images);
    }

    private void on_pull_images_button_clicked (Gee.List<string> images) {
        pull_images_button_clicked (images);
    }

    private void on_inspect_image_button_clicked (string image) {
        prior_view = WhaleWatcher.Views.ImagesView.TITLE;
        Idle.add (() => {
            header_bar.update_title (image);
            header_bar.set_return_button_label (_("Images"));
            header_bar.set_view_mode_button_visible (false);
            header_bar.set_return_button_visible (true);
            header_bar.set_image_inspect_buttons_visible (true);
            header_bar.set_image_browsing_buttons_visible (false);
            images_view.show_inspect_image_view ();
            return false;
        });
        inspect_image_button_clicked (image);
    }

    public void show_layers_size (uint64 layers_size) {
        images_view.show_layers_size (layers_size);
    }

    public void show_images (Gee.List<WhaleWatcher.Models.DockerImageSummary> images) {
        images_view.set_images (images);
    }

    public void show_image_details (WhaleWatcher.Models.DockerImageDetails image_details) {
        images_view.set_image_details (image_details);
    }

    public void show_image_history (Gee.List<WhaleWatcher.Models.DockerImageLayer> image_history) {
        images_view.set_image_history (image_history);
    }

    public signal void cleanup_images_button_clicked (Gee.List<string> images);
    public signal void pull_images_button_clicked (Gee.List<string> images);
    public signal void inspect_image_button_clicked (string image);

}