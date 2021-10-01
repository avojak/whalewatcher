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

public class WhaleWatcher.Models.DockerImage : GLib.Object {

    public string id { set; get; }
    public string parent_id { set; get; }
    public Gee.List<string> repo_tags { set; get; }
    public Gee.List<string> repo_digests { set; get; }
    public int64 created { set; get; }
    public uint64 size { set; get; }
    public double virtual_size { set; get; }
    public double shared_size { set; get; }
    public double containers { set; get; }

    public static WhaleWatcher.Models.DockerImage from_json (Json.Object json) {
        var obj = new WhaleWatcher.Models.DockerImage ();
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Id":
                    obj.id = json.get_string_member (name);
                    break;
                case "ParentId":
                    obj.parent_id = json.get_string_member (name);
                    break;
                case "RepoTags":
                    var repo_tags = new Gee.ArrayList<string> ();
                    foreach (var element in json.get_array_member (name).get_elements ()) {
                        repo_tags.add (element.get_string ());
                    }
                    obj.repo_tags = repo_tags;
                    break;
                case "RepoDigests":
                    var repo_digests = new Gee.ArrayList<string> ();
                    foreach (var element in json.get_array_member (name).get_elements ()) {
                        repo_digests.add (element.get_string ());
                    }
                    obj.repo_digests = repo_digests;
                    break;
                case "Created":
                    obj.created = json.get_int_member (name);
                    break;
                case "Size":
                    obj.size = uint64.parse (json.get_double_member (name).to_string ());
                    break;
                case "VirtualSize":
                    obj.virtual_size = json.get_double_member (name);
                    break;
                case "SharedSize":
                    obj.shared_size = json.get_double_member (name);
                    break;
                case "Containers":
                    obj.containers = json.get_double_member (name);
                    break;
                default:
                    warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj;
    }

    public string to_string () {
        StringBuilder sb = new StringBuilder ();
        sb.append_printf ("id = %s\n", id.to_string ());
        sb.append_printf ("parent_id = %s\n", parent_id.to_string ());
        sb.append_printf ("repo_tags = %s\n", repo_tags.get (0).to_string ());
        sb.append_printf ("repo_digests = %s\n", repo_digests.get (0).to_string ());
        sb.append_printf ("created = %s\n", created.to_string ());
        sb.append_printf ("size = %s\n", size.to_string ());
        sb.append_printf ("virtual_size = %s\n", virtual_size.to_string ());
        sb.append_printf ("shared_size = %s\n", shared_size.to_string ());
        sb.append_printf ("containers = %s\n", containers.to_string ());
        return (owned) sb.str;
    }

    public string get_name () {
        // Even when there's an image with no tags, it will have a RepoTags entry of "<none>:<none>"
        return repo_tags.get (0).split (":")[0];
    }

    public string get_short_id () {
        return id.split(":")[1].substring (0, 12);
    }

}