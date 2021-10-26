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

public class WhaleWatcher.Widgets.ImageListItem : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {

    public string image_name { get; construct; }

    public ImageListItem (string image_name) {
        Object (
            name: image_name,
            selectable: false,
            expanded: true
        );
    }

    construct {
        child_added.connect (update_badge);
        child_removed.connect (update_badge);
    }

    public new bool allow_dnd_sorting () {
        return false;
    }

    public new int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
        var tag_a = a as WhaleWatcher.Widgets.ImageTagListItem;
        var tag_b = b as WhaleWatcher.Widgets.ImageTagListItem;
        return tag_a.name.ascii_casecmp (tag_b.name);
    }

    private void update_badge () {
        size_t num_in_use = 0;
        foreach (var child in children) {
            var tag_item = child as WhaleWatcher.Widgets.ImageTagListItem;
            if (tag_item.in_use) {
                num_in_use++;
            }
        }
        badge = _(@"$num_in_use in use / $n_children total");
    }

}