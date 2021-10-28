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

public class WhaleWatcher.Models.DockerVolumes : GLib.Object {

    public Gee.List<WhaleWatcher.Models.DockerVolume> volumes { set; get; }

    public static WhaleWatcher.Models.DockerVolumes from_json (Json.Object json) {
        var obj = new WhaleWatcher.Models.DockerVolumes ();
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Volumes":
                    obj.volumes = new Gee.ArrayList<WhaleWatcher.Models.DockerVolume> ();
                    var member = json.get_member (name);
                    if (member == null || member.is_null ()) {
                        break;
                    }
                    var array = member.get_array ();
                    if (array == null) {
                        break;
                    }
                    foreach (var element in array.get_elements ()) {
                        obj.volumes.add (WhaleWatcher.Models.DockerVolume.from_json (element.get_object ()));
                    }
                    break;
                default:
                    warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj;
    }

}