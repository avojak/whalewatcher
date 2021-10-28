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

public class WhaleWatcher.Views.ContainersView : Gtk.Paned {

    public const string TITLE = _("Containers");

    private Gtk.Stack stack;
    private WhaleWatcher.Widgets.ContainersSidebar sidebar;

    public ContainersView () {
        Object (
            position: 300
        );
    }

    construct {
        stack = new Gtk.Stack ();
        sidebar = new WhaleWatcher.Widgets.ContainersSidebar (stack);

        add (sidebar);
        add (stack);
    }

    public void set_containers (Gee.List<WhaleWatcher.Models.DockerContainer> containers) {
        foreach (var container in containers) {
            var name = container.names.get (0);
            var display_name = name.has_prefix ("/") ? name.substring (1) : name;
            var display_status = container.status;
            //  var display_image = container.image;
            var container_page = new WhaleWatcher.Views.ContainerPage (display_name, display_status, determine_status_type (container.state));
            container_page.set_container_details (container);
            stack.add_named (container_page, name);
        }
    }

    public void filter_containers (string filter_text) {
        sidebar.filter (filter_text);
    }

    private Granite.SettingsPage.StatusType determine_status_type (WhaleWatcher.Models.DockerContainer.State state) {
        switch (state) {
            case CREATED:
            case RESTARTING:
            case REMOVING:
            case PAUSED:
                return Granite.SettingsPage.StatusType.WARNING;
            case RUNNING:
                return Granite.SettingsPage.StatusType.SUCCESS;
            case EXITED:
                return Granite.SettingsPage.StatusType.OFFLINE;
            case DEAD:
                return Granite.SettingsPage.StatusType.ERROR;
            default:
                assert_not_reached ();
        }
    }

}