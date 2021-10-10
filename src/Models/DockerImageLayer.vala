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

public class WhaleWatcher.Models.DockerImageLayer : GLib.Object {

    public string id { get; set; }
    public uint64 created { get; set; }
    public string created_by { get; set; }
    public Gee.List<string> tags { get; set; }
    public uint64 size { get; set; }
    public string comment { get; set; }

    public static WhaleWatcher.Models.DockerImageLayer from_json (Json.Object json) {
        var obj = new WhaleWatcher.Models.DockerImageLayer ();
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Id":
                    obj.id = json.get_string_member (name);
                    break;
                case "Created":
                    obj.created = uint64.parse (json.get_double_member (name).to_string ());
                    break;
                case "CreatedBy":
                    obj.created_by = json.get_string_member (name);
                    break;
                case "Tags":
                    var tags = new Gee.ArrayList<string> ();
                    var member = json.get_member (name);
                    if (member == null || member.is_null ()) {
                        break;
                    }
                    var array = member.get_array ();
                    if (array == null) {
                        break;
                    }
                    foreach (var element in array.get_elements ()) {
                        tags.add (element.get_string ());
                    }
                    obj.tags = tags;
                    break;
                case "Size":
                    obj.size = uint64.parse (json.get_double_member (name).to_string ());
                    break;
                case "Comment":
                    obj.comment = json.get_string_member (name);
                    break;
                default:
                    warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj;
    }

}