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

public class WhaleWatcher.MainWindow : Gtk.ApplicationWindow {

    public unowned WhaleWatcher.Application app { get; construct; }

    private WhaleWatcher.Widgets.HeaderBar header_bar;
    private WhaleWatcher.MainLayout main_layout;

    public MainWindow (WhaleWatcher.Application application) {
        Object (
            application: application,
            app: application,
            border_width: 0,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        header_bar = new WhaleWatcher.Widgets.HeaderBar ();
        set_titlebar (header_bar);

        unowned Gtk.StyleContext header_context = header_bar.get_style_context ();
        header_context.add_class ("default-decoration");

        main_layout = new WhaleWatcher.MainLayout (this);
        add (main_layout);

        move (WhaleWatcher.Application.settings.get_int ("pos-x"), WhaleWatcher.Application.settings.get_int ("pos-y"));
        resize (WhaleWatcher.Application.settings.get_int ("window-width"), WhaleWatcher.Application.settings.get_int ("window-height"));

        // Close connections when the window is closed
        //  this.destroy.connect (() => {
        //      //  // Disconnect this signal so that we don't modify the setting to
        //      //  // show servers as disabled, when in reality they were enabled prior
        //      //  // to closing the application.
        //      //  main_layout.side_panel.server_row_disabled.disconnect (Iridium.Application.connection_repository.on_server_row_disabled);

        //      // TODO: Not sure if this is right…
        //      //  WhaleWatcher.Application.docker_client.close ();
        //      GLib.Process.exit (0);
        //  });

        this.delete_event.connect (before_destroy);

        show_app ();
    }

    public void show_app () {
        show_all ();
        show ();
        present ();
    }

    public bool before_destroy () {
        update_position_settings ();
        destroy ();
        return true;
    }

    private void update_position_settings () {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        WhaleWatcher.Application.settings.set_int ("pos-x", x);
        WhaleWatcher.Application.settings.set_int ("pos-y", y);
        WhaleWatcher.Application.settings.set_int ("window-width", width);
        WhaleWatcher.Application.settings.set_int ("window-height", height);
    }

}
