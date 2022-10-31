/*
 * Copyright (c) 2020 Andrew Vojak (https://avojak.com)
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

public class WhaleWatcher.Widgets.AuthDialog : Granite.Dialog {

    public unowned WhaleWatcher.MainWindow main_window { get; construct; }

    private Granite.ValidatedEntry username_entry;
    private Granite.ValidatedEntry email_entry;
    private Granite.ValidatedEntry password_entry;
    private Granite.ValidatedEntry server_entry;

    private Gtk.Entry entry;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    public AuthDialog (WhaleWatcher.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Log In"),
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            default_width: 450
        );
    }

    construct {
        var body = get_content_area ();

        // Create the header
        var header_grid = new Gtk.Grid ();
        header_grid.margin_start = 30;
        header_grid.margin_end = 30;
        header_grid.margin_bottom = 10;
        header_grid.column_spacing = 10;

        var header_image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label (_("Log In"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);

        body.add (header_grid);

        body.add (create_form ());

        spinner = new Gtk.Spinner ();
        body.add (spinner);

        status_label = new Gtk.Label ("");
        status_label.get_style_context ().add_class ("h4");
        status_label.halign = Gtk.Align.CENTER;
        status_label.valign = Gtk.Align.CENTER;
        status_label.justify = Gtk.Justification.CENTER;
        status_label.set_max_width_chars (50);
        status_label.set_line_wrap (true);
        status_label.margin_bottom = 10;
        body.add (status_label);

        // Add action buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            close ();
        });

        var submit_button = new Gtk.Button.with_label (_("Log In"));
        submit_button.get_style_context ().add_class ("suggested-action");
        submit_button.clicked.connect (() => {
            spinner.start ();
            status_label.label = "";
            submit_button_clicked (get_new_nickname ());
        });

        //  submit_button.sensitive = get_new_nickname () != current_nickname;
        //  entry.changed.connect (() => {
        //      var new_nickname = get_new_nickname ();
        //      submit_button.sensitive = (new_nickname != current_nickname) && new_nickname.length > 0;
        //  });

        add_action_widget (cancel_button, 0);
        add_action_widget (submit_button, 1);
    }

    private Gtk.Grid create_form () {
        GLib.Regex? email_regex = null;
        try {
            email_regex = new GLib.Regex ("""^[^\s]+@[^\s]+\.[^\s]+$""");
        } catch (Error e) {
            critical (e.message);
        }

        var grid = new Gtk.Grid ();
        grid.margin = 30;
        grid.row_spacing = 12;
        grid.column_spacing = 20;

        var username_label = new Gtk.Label (_("Username:"));
        username_label.halign = Gtk.Align.END;

        username_entry = new Granite.ValidatedEntry () {
            is_valid = true,
            text = Environment.get_user_name (),
            hexpand = true
        };

        var email_label = new Gtk.Label (_("Email Address:"));
        email_label.halign = Gtk.Align.END;

        email_entry = new Granite.ValidatedEntry.from_regex (email_regex) {
            hexpand = true
        };

        var password_label = new Gtk.Label (_("Password:"));
        password_label.halign = Gtk.Align.END;

        password_entry = new Granite.ValidatedEntry () {
            input_purpose = Gtk.InputPurpose.PASSWORD,
            visibility = false,
            hexpand = true
        };

        var server_label = new Gtk.Label (_("Server Address:"));
        server_label.halign = Gtk.Align.END;

        server_entry = new Granite.ValidatedEntry () {
            is_valid = true,
            text = "https://index.docker.io/v1/",
            hexpand = true,
            sensitive = false // TODO: Remove this when more than one server is supported
        };

        grid.attach (username_label, 0, 0, 1, 1);
        grid.attach (username_entry, 1, 0, 1, 1);
        grid.attach (email_label, 0, 1, 1, 1);
        grid.attach (email_entry, 1, 1, 1, 1);
        grid.attach (password_label, 0, 2, 1, 1);
        grid.attach (password_entry, 1, 2, 1, 1);
        grid.attach (server_label, 0, 3, 1, 1);
        grid.attach (server_entry, 1, 3, 1, 1);

        return grid;
    }

    private string get_new_nickname () {
        return entry.text.chomp ().chug ();
    }

    public void dismiss () {
        spinner.stop ();
        close ();
    }

    public void display_error (string message) {
        spinner.stop ();
        status_label.label = message;
    }

    public signal void submit_button_clicked (string new_nickname);

}