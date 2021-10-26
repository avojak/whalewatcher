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

public class WhaleWatcher.Models.DockerContainer : GLib.Object {

    public string id { set; get; }
    public Gee.List<string> names { set; get; }
    public string image { set; get; }
    public string image_id { set; get; }
    public string command { set; get; }
    public int64 created { set; get; }
    public uint64 size_root_fs { set; get; }
    public string state { set; get; }
    public string status { set; get; }

    public static WhaleWatcher.Models.DockerContainer from_json (Json.Object json) {
        var obj = new WhaleWatcher.Models.DockerContainer ();
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Id":
                    obj.id = json.get_string_member (name);
                    break;
                case "Names":
                    var names = new Gee.ArrayList<string> ();
                    var member = json.get_member (name);
                    if (member == null || member.is_null ()) {
                        break;
                    }
                    var array = member.get_array ();
                    if (array == null) {
                        break;
                    }
                    foreach (var element in array.get_elements ()) {
                        names.add (element.get_string ());
                    }
                    obj.names = names;
                    break;
                case "Image":
                    obj.image = json.get_string_member (name);
                    break;
                case "ImageID":
                    obj.image_id = json.get_string_member (name);
                    break;
                case "Command":
                    obj.command = json.get_string_member (name);
                    break;
                case "Created":
                    obj.created = json.get_int_member (name);
                    break;
                case "SizeRootFs":
                    obj.size_root_fs = uint64.parse (json.get_double_member (name).to_string ());
                    break;
                case "State":
                    obj.state = json.get_string_member (name);
                    break;
                case "Status":
                    obj.status = json.get_string_member (name);
                    break;
                default:
                    warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj;
    }

}