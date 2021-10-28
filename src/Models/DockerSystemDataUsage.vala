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

public class WhaleWatcher.Models.DockerSystemDataUsage : GLib.Object {

    public uint64 layers_size { get; set; }
    public Gee.List<WhaleWatcher.Models.DockerImageSummary> images { get; set; }
    public Gee.List<WhaleWatcher.Models.DockerContainer> containers { get; set; }
    public Gee.List<WhaleWatcher.Models.DockerVolume> volumes { get; set; }

    public static WhaleWatcher.Models.DockerSystemDataUsage from_json (Json.Object json) {
        var obj = new WhaleWatcher.Models.DockerSystemDataUsage ();
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "LayersSize":
                    obj.layers_size = uint64.parse (json.get_double_member (name).to_string ());
                    break;
                case "Images":
                    obj.images = new Gee.ArrayList<WhaleWatcher.Models.DockerImageSummary> ();
                    var member = json.get_member (name);
                    if (member == null || member.is_null ()) {
                        break;
                    }
                    var array = member.get_array ();
                    if (array == null) {
                        break;
                    }
                    foreach (var element in array.get_elements ()) {
                        obj.images.add (WhaleWatcher.Models.DockerImageSummary.from_json (element.get_object ()));
                    }
                    break;
                case "Containers":
                    obj.containers = new Gee.ArrayList<WhaleWatcher.Models.DockerContainer> ();
                    var member = json.get_member (name);
                    if (member == null || member.is_null ()) {
                        break;
                    }
                    var array = member.get_array ();
                    if (array == null) {
                        break;
                    }
                    foreach (var element in array.get_elements ()) {
                        obj.containers.add (WhaleWatcher.Models.DockerContainer.from_json (element.get_object ()));
                    }
                    break;
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