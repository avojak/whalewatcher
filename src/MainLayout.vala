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
    private WhaleWatcher.Widgets.Sidebar.SidebarWidget side_bar;
    private WhaleWatcher.Widgets.MainView main_view;

    public MainLayout (WhaleWatcher.MainWindow window) {
        Object (
            window: window
        );
    }

    construct {
        header_bar = new WhaleWatcher.Widgets.HeaderBar ();
        unowned Gtk.StyleContext header_context = header_bar.get_style_context ();
        header_context.add_class ("default-decoration");

        side_bar = new WhaleWatcher.Widgets.Sidebar.SidebarWidget ();

        main_view = new WhaleWatcher.Widgets.MainView ();

        Gtk.Paned paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.position = 240;
        paned.expand = true;
        paned.pack1 (side_bar, true, false);
        paned.pack2 (main_view, true, false);

        attach (header_bar, 0, 0);
        attach (paned, 0, 1);

        show_all ();
    }

}