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

public class WhaleWatcher.MainLayout : Gtk.Grid {

    public unowned WhaleWatcher.MainWindow window { get; construct; }

    private WhaleWatcher.Widgets.HeaderBar header_bar;
    //  private WhaleWatcher.Widgets.Sidebar.SidebarWidget side_bar;
    private Gtk.Stack stack;

    private WhaleWatcher.Views.ImagesView images_view;
    private WhaleWatcher.Views.ContainersView containers_view;
    private WhaleWatcher.Views.VolumesView volumes_view;
    private WhaleWatcher.Views.NetworksView networks_view;

    public MainLayout (WhaleWatcher.MainWindow window) {
        Object (
            window: window
        );
    }

    construct {
        header_bar = new WhaleWatcher.Widgets.HeaderBar ();
        header_bar.view_selected.connect (on_view_selected);
        //  unowned Gtk.StyleContext header_context = header_bar.get_style_context ();
        //  header_context.add_class ("default-decoration");

        //  side_bar = new WhaleWatcher.Widgets.Sidebar.SidebarWidget ();
        //  side_bar.row_selected.connect ((entry_name) => {
        //      stack.set_visible_child_name (entry_name);
        //  });

        // Depending on the configured system style preferences, the contrast with a color header bar with selected buttons may look very poor
        //  Gdk.RGBA primary_color = Gdk.RGBA ();
        //  primary_color.parse ("#2496ed");
        //  Granite.Widgets.Utils.set_color_primary (window, primary_color);

        images_view = new WhaleWatcher.Views.ImagesView ();
        containers_view = new WhaleWatcher.Views.ContainersView ();
        volumes_view = new WhaleWatcher.Views.VolumesView ();
        networks_view = new WhaleWatcher.Views.NetworksView ();

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
        attach (stack, 0, 1);

        show_all ();
    }

    private void on_view_selected (string view_title) {
        debug ("%s selected", view_title);
        Idle.add (() => {
            stack.set_visible_child_name (view_title);
            return false;
        });
    }

    public void show_images (Gee.List<WhaleWatcher.Models.DockerImage> images) {
        images_view.set_images (images);
    }

}