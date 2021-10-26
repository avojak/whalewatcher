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

public class WhaleWatcher.Widgets.ImageListCategory : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {

    public ImageListCategory (string name) {
        Object (
            name: name
        );
    }

    public new bool allow_dnd_sorting () {
        return false;
    }

    public new int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
        // Placeholders have empty name
        if (a.name == "" || b.name == "") {
            return 0;
        }
        // All other children are ImageListItems
        var item_a = a as WhaleWatcher.Widgets.ImageListItem;
        var item_b = b as WhaleWatcher.Widgets.ImageListItem;
        return item_a.name.ascii_casecmp (item_b.name);
    }

}