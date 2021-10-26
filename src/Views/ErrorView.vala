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

public class WhaleWatcher.Views.ErrorView : Gtk.Grid {

    public const string TITLE = _("Error");

    private Granite.Widgets.AlertView error_view;

    construct {
        error_view = new Granite.Widgets.AlertView ("", "", "dialog-warning");
        error_view.show_action (_("Retry connection"));
        error_view.action_activated.connect (() => {
            retry_connection ();
        });
        add (error_view);
        show_all ();
    }

    public void set_content (string title, string description) {
        error_view.title = title;
        error_view.description = description;
        error_view.show_all ();
    }

    public signal void retry_connection ();

}