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

public class WhaleWatcher.Widgets.ImagesSourceList : Gtk.Grid {

    private Granite.Widgets.SourceList source_list;
    private Gtk.ActionBar action_bar;

    private Gtk.Button delete_button;
    private Gtk.Button run_button;
    private Gtk.Button export_button;
    private Gtk.Button pull_button;

    private WhaleWatcher.Widgets.ImageListCategory local_category;
    private WhaleWatcher.Widgets.ImageListCategory remote_category;
    private Granite.Widgets.SourceList.Item local_placeholder;
    private Granite.Widgets.SourceList.Item remote_placeholder;

    private Gee.Map<string, WhaleWatcher.Widgets.ImageListItem> image_items;
    private Gee.Map<string, Gee.List<WhaleWatcher.Widgets.ImageTagListItem>> image_tag_items;

    private string filter_text = "";

    public ImagesSourceList () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        source_list = new Granite.Widgets.SourceList ();
        source_list.set_filter_func ((item) => {
            // Always show categories
            if (item.parent == source_list.root) {
                return true;
            }
            // Show everything when there is no filter text
            if (filter_text == "") {
                return true;
            }
            // Show an item if it contains the filter text (duh)
            if (item.name.contains (filter_text)) {
                return true;
            }
            // Show tags for a parent when the parent matches the text (but not when the parent is a category)
            if (item.parent.name.contains (filter_text) && item.parent.parent != source_list.root) {
                return true;
            }
            // Make sure that the parent is visible (i.e. the image) when a tag matches the filter
            if (item is Granite.Widgets.SourceList.ExpandableItem) {
                var expand_item = item as Granite.Widgets.SourceList.ExpandableItem;
                foreach (var child in expand_item.children) {
                    if (child.name.contains (filter_text)) {
                        return true;
                    }
                }
            }
            return false;
            //  return item.name.contains (filter_text) || item.parent.name.contains (filter_text);
        }, false);

        local_category = new WhaleWatcher.Widgets.ImageListCategory (_("Local"));
        local_placeholder = new Granite.Widgets.SourceList.Item ("");
        local_placeholder.selectable = false;
        local_category.add (local_placeholder);
        local_category.child_added.connect (() => {
            local_category.expanded = true;
            local_placeholder.visible = false;
        });
        local_category.child_removed.connect (() => {
            if (local_category.n_children == 1) {
                local_category.expanded = false;
                local_placeholder.visible = true;
            }
        });

        remote_category = new WhaleWatcher.Widgets.ImageListCategory (_("Remote Repositories"));
        remote_placeholder = new Granite.Widgets.SourceList.Item ("");
        remote_placeholder.selectable = false;
        remote_category.add (remote_placeholder);
        remote_category.child_added.connect (() => {
            remote_category.expanded = true;
            remote_placeholder.visible = false;
        });
        remote_category.child_removed.connect (() => {
            if (remote_category.n_children == 1) {
                remote_category.expanded = false;
                remote_placeholder.visible = true;
            }
        });

        source_list.root.add (local_category);
        //  source_list.root.add (remote_category);

        source_list.item_selected.connect (on_item_selected);

        action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

        // Add sort options
        // Add ability to expand/collapse all

        delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Remove…"),
            sensitive = false
        };
        delete_button.clicked.connect (on_delete_button_clicked);

        run_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Run…"),
            sensitive = false
        };
        run_button.clicked.connect (on_run_button_clicked);

        export_button = new Gtk.Button.from_icon_name ("document-export-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Export…"),
            sensitive = false
        };
        export_button.clicked.connect (on_export_button_clicked);

        pull_button = new Gtk.Button.from_icon_name ("browser-download-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Pull"),
            sensitive = false
        };
        pull_button.clicked.connect (on_pull_button_clicked);

        action_bar.pack_start (run_button);
        action_bar.pack_start (export_button);
        action_bar.pack_start (pull_button);
        action_bar.pack_end (delete_button);

        attach (source_list, 0, 0);
        attach (action_bar, 0, 1);

        image_items = new Gee.HashMap<string, WhaleWatcher.Widgets.ImageListItem> ();
        image_tag_items = new Gee.HashMap<string, Gee.List<WhaleWatcher.Widgets.ImageTagListItem>> ();

        source_list.motion_notify_event.connect ((event_motion) => {
            debug ("Motion: x=%s, y=%s", event_motion.x.to_string (), event_motion.y.to_string ());
        });
        source_list.enter_notify_event.connect (() => {
            debug ("Enter");
        });
        source_list.leave_notify_event.connect (() => {
            debug ("Leave");
        });
        source_list.scroll_event.connect ((event_scroll) => {
            debug ("Scroll");
        });
    }

    public void set_images (Gee.List<WhaleWatcher.Models.DockerImageSummary> images) {
        foreach (var image in images) {
            if (!image_items.has_key (image.get_name ())) {
                var image_item = new WhaleWatcher.Widgets.ImageListItem (image.get_name ());
                local_category.add (image_item);
                image_items.set (image.get_name (), image_item);
                image_tag_items.set (image.get_name (), new Gee.ArrayList<WhaleWatcher.Widgets.ImageTagListItem> ());
            }
            foreach (var tag in image.repo_tags) {
                var tag_item = new WhaleWatcher.Widgets.ImageTagListItem (tag, tag.split (":")[1], image.containers > 0);
                image_items.get (image.get_name ()).add (tag_item);
                image_tag_items.get (image.get_name ()).add (tag_item);
            }
        }
    }

    public void filter (string filter_text) {
        this.filter_text = filter_text;
        source_list.refilter ();
    }

    private void on_item_selected (Granite.Widgets.SourceList source_list, Granite.Widgets.SourceList.Item? item) {
        delete_button.sensitive = item != null;
        run_button.sensitive = item != null;
        export_button.sensitive = item != null;
        pull_button.sensitive = item != null;

        if (item == null) {
            return;
        }

        var image_name = item.parent.name;
        var tag = item.name;

        image_selected (@"$image_name:$tag");
    }

    private string? get_selected_image () {
        Granite.Widgets.SourceList.Item? item = source_list.selected;
        if (item == null) {
            return null;
        }
        var tag_item = item as WhaleWatcher.Widgets.ImageTagListItem;
        return tag_item.image_name;
    }

    private void on_delete_button_clicked () {
        string? image_name = get_selected_image ();
        if (image_name != null) {
            delete_button_clicked (image_name);
        }
    }

    private void on_run_button_clicked () {
        string? image_name = get_selected_image ();
        if (image_name != null) {
            run_button_clicked (image_name);
        }
    }

    private void on_export_button_clicked () {
        string? image_name = get_selected_image ();
        if (image_name != null) {
            export_button_clicked (image_name);
        }
    }

    private void on_pull_button_clicked () {
        string? image_name = get_selected_image ();
        if (image_name != null) {
            pull_button_clicked (image_name);
        }
    }


    public signal void image_selected (string image_name);
    public signal void delete_button_clicked (string image_name);
    public signal void run_button_clicked (string image_name);
    public signal void export_button_clicked (string image_name);
    public signal void pull_button_clicked (string image_name);

}