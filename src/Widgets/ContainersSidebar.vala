/*
 * Copyright 2017 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

/**
 * This is a modified version of Granite.SettingsSidebar to allow access to the listbox
 * for filtering.
 */
public class WhaleWatcher.Widgets.ContainersSidebar : Gtk.Grid {
    
    private Gtk.ListBox listbox;
    private Gtk.ActionBar action_bar;


    /**
     * The Gtk.Stack to control
     */
    public Gtk.Stack stack { get; construct; }

    /**
     * The name of the currently visible Granite.SettingsPage
     */
    public string? visible_child_name {
        get {
            var selected_row = listbox.get_selected_row ();

            if (selected_row == null) {
                return null;
            } else {
                return ((WhaleWatcher.Widgets.ContainersSidebarRow) selected_row).page.title;
            }
        }
        set {
            foreach (unowned Gtk.Widget listbox_child in listbox.get_children ()) {
                if (((WhaleWatcher.Widgets.ContainersSidebarRow) listbox_child).page.title == value) {
                    listbox.select_row ((Gtk.ListBoxRow) listbox_child);
                }
            }
        }
    }

    private string filter_text = "";

    /**
     * Create a new SettingsSidebar
     */
    public ContainersSidebar (Gtk.Stack stack) {
        Object (
            stack: stack,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            width_request = 200,
            hexpand = true,
            vexpand = true
        };
        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.set_filter_func ((row) => {
            if (filter_text == "") {
                return true;
            }
            return ((WhaleWatcher.Widgets.ContainersSidebarRow) row).title.contains (filter_text);
        });
        listbox.set_sort_func ((row1, row2) => {
            var title1 = ((WhaleWatcher.Widgets.ContainersSidebarRow) row1).title;
            var title2 = ((WhaleWatcher.Widgets.ContainersSidebarRow) row2).title;
            return title1.ascii_casecmp (title2);
        });

        scrolled_window.add (listbox);

        action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

        var start_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Start…"),
            sensitive = false
        };
        var stop_button = new Gtk.Button.from_icon_name ("media-playback-stop-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Stop…"),
            sensitive = false
        };

        action_bar.pack_start (start_button);
        action_bar.pack_start (stop_button);

        attach (scrolled_window, 0, 0);
        attach (action_bar, 0, 1);

        on_sidebar_changed ();
        stack.add.connect (on_sidebar_changed);
        stack.remove.connect (on_sidebar_changed);

        listbox.row_selected.connect ((row) => {
            stack.visible_child = ((WhaleWatcher.Widgets.ContainersSidebarRow) row).page;
        });

        listbox.set_header_func ((row, before) => {
            var header = ((WhaleWatcher.Widgets.ContainersSidebarRow) row).header;
            if (header != null) {
                row.set_header (new Granite.HeaderLabel (header));
            }
        });

        stack.notify["visible-child-name"].connect (() => {
            visible_child_name = stack.visible_child_name;
        });
    }

    public void filter (string filter_text) {
        this.filter_text = filter_text;
        listbox.invalidate_filter ();
    }

    private void on_sidebar_changed () {
        listbox.get_children ().foreach ((listbox_child) => {
            listbox_child.destroy ();
        });

        stack.get_children ().foreach ((child) => {
            if (child is Granite.SettingsPage) {
                var row = new WhaleWatcher.Widgets.ContainersSidebarRow ((Granite.SettingsPage) child);
                listbox.add (row);
            }
        });

        listbox.show_all ();
    }
}