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

 public class WhaleWatcher.Views.WelcomeView : Granite.Widgets.Welcome {

    public unowned WhaleWatcher.MainWindow window { get; construct; }

    public WelcomeView (WhaleWatcher.MainWindow window) {
        Object (
            window: window,
            title: _("Welcome to WhaleWatcher!"),
            subtitle: _("Manage your Docker images, containers, and more")
        );
    }

    construct {
        valign = Gtk.Align.FILL;
        halign = Gtk.Align.FILL;
        vexpand = true;

        // TODO: Should there even be a welcome view? Instead just open whichever view was opened before? 
        //       Or maybe only show a view like this if Docker is not installed.
    }

}
