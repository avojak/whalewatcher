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

public class WhaleWatcher.Widgets.VolumesSourceList : Gtk.Grid {

    private Granite.Widgets.SourceList source_list;
    private Gtk.ActionBar action_bar;

    private Gtk.Button browse_button;
    private Gtk.Button delete_button;

    private string filter_text = "";

    public VolumesSourceList () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        source_list = new Granite.Widgets.SourceList ();
        source_list.set_filter_func ((item) => {
            // TODO
            return true;
        }, false);

        //  source_list.root.add (local_category);
        //  source_list.root.add (remote_category);

        source_list.item_selected.connect (on_item_selected);

        action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

        browse_button = new Gtk.Button.from_icon_name ("document-open-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Browse files…"),
            sensitive = false
        };
        browse_button.clicked.connect (on_browse_button_clicked);

        delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            tooltip_text = _("Remove…"),
            sensitive = false
        };
        delete_button.clicked.connect (on_delete_button_clicked);

        action_bar.pack_start (browse_button);
        action_bar.pack_end (delete_button);

        attach (source_list, 0, 0);
        attach (action_bar, 0, 1);
    }

    public void set_volumes (Gee.List<WhaleWatcher.Models.DockerVolume> volumes) {
        foreach (var volume in volumes) {
            var item = new WhaleWatcher.Widgets.VolumeListItem (volume.name);
            source_list.root.add (item);
            //  if (!image_items.has_key (image.get_name ())) {
            //      var image_item = new WhaleWatcher.Widgets.ImageListItem (image.get_name ());
            //      local_category.add (image_item);
            //      image_items.set (image.get_name (), image_item);
            //      image_tag_items.set (image.get_name (), new Gee.ArrayList<WhaleWatcher.Widgets.VolumeListItem> ());
            //  }
            //  foreach (var tag in image.repo_tags) {
            //      var tag_item = new WhaleWatcher.Widgets.VolumeListItem (tag, tag.split (":")[1], image.containers > 0);
            //      image_items.get (image.get_name ()).add (tag_item);
            //      image_tag_items.get (image.get_name ()).add (tag_item);
            //  }
        }
    }

    public void filter (string filter_text) {
        this.filter_text = filter_text;
        source_list.refilter ();
    }

    private void on_item_selected (Granite.Widgets.SourceList source_list, Granite.Widgets.SourceList.Item? item) {
        delete_button.sensitive = item != null;
        browse_button.sensitive = item != null;
        if (item == null) {
            return;
        }
        volume_selected (item.name);
    }

    private string? get_selected_volume () {
        Granite.Widgets.SourceList.Item? item = source_list.selected;
        if (item == null) {
            return null;
        }
        return item.name;
    }

    private void on_delete_button_clicked () {
        string? volume_name = get_selected_volume ();
        if (volume_name != null) {
            delete_button_clicked (volume_name);
        }
    }

    private void on_browse_button_clicked () {
        string? volume_name = get_selected_volume ();
        if (volume_name != null) {
            browse_button_clicked (volume_name);
        }
    }

    public signal void volume_selected (string volume_name);
    public signal void delete_button_clicked (string volume_name);
    public signal void browse_button_clicked (string volume_name);

}