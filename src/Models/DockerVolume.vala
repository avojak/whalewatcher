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

public class WhaleWatcher.Models.DockerVolume : GLib.Object {

    public class UsageData {

        public int64 ref_count { set; get; }
        public uint64 size { set; get; }

        public static WhaleWatcher.Models.DockerVolume.UsageData from_json (Json.Object json) {
            var obj = new WhaleWatcher.Models.DockerVolume.UsageData ();
            foreach (unowned string name in json.get_members ()) {
                switch (name) {
                    case "RefCount":
                        obj.ref_count = json.get_int_member (name);
                        break;
                    case "Size":
                        obj.size = uint64.parse (json.get_double_member (name).to_string ());
                        break;
                    default:
                        warning ("Unsupported attribute: %s", name);
                        break;
                }
            }
            return obj;
        }

    }

    public string name { set; get; }
    public string created { set; get; }
    public string driver { set; get; }
    public string mountpoint { set; get; }
    public string scope { set; get; }
    public UsageData usage_data { set; get; }

    public static WhaleWatcher.Models.DockerVolume from_json (Json.Object json) {
        var obj = new WhaleWatcher.Models.DockerVolume ();
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Name":
                    obj.name = json.get_string_member (name);
                    break;
                case "CreatedAt":
                    obj.created = json.get_string_member (name);
                    break;
                case "Driver":
                    obj.driver = json.get_string_member (name);
                    break;
                case "Mountpoint":
                    obj.mountpoint = json.get_string_member (name);
                    break;
                case "Scope":
                    obj.scope = json.get_string_member (name);
                    break;
                case "UsageData":
                    obj.usage_data = UsageData.from_json (json.get_object_member (name));
                    break;
                default:
                    warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj;
    }

}